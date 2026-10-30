"""Importa el catálogo de la tienda online de Consum a Supabase.

Igual que mercadona_sync.py: nombre con formato, marca, precio, precio por
kg/l/ud y la URL de la foto oficial en public.supermarket_products. Lo lanza
cada semana .github/workflows/open-prices.yml. Uso local sin escribir:
  python scripts/consum_sync.py --dry-run
"""

import json
import sys
import time
import urllib.request
from datetime import datetime, timezone

from mercadona_sync import save
from open_prices_sync import normalize

API = "https://tienda.consum.es/api/rest/V1.0/catalog/product?limit=100&offset="
HEADERS = {"User-Agent": "PrezHome/1.0 (prezhomeapp@gmail.com)"}
STORE = "consum"
MIN_PRODUCTS = 1000


def _get(offset: int) -> dict:
    req = urllib.request.Request(f"{API}{offset}", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def to_row(product: dict, now: str) -> dict | None:
    """Fila de supermarket_products para un producto de la API, o None."""
    data = product.get("productData") or {}
    # La descripción lleva el formato ("Leche Semidesnatada Brik 1 L").
    name = (data.get("description") or data.get("name") or "").strip()
    pid = str(product.get("code") or product.get("id") or "").strip()
    if not name or not pid:
        return None
    price_data = product.get("priceData") or {}
    value = ((price_data.get("prices") or [{}])[0]).get("value") or {}
    unit = (price_data.get("unitPriceUnitType") or "").split()
    cats = product.get("categories") or [{}]
    return {
        "store": STORE,
        "product_id": pid,
        "name": name,
        "name_normalized": normalize(name),
        "brand": ((data.get("brand") or {}).get("name") or "").strip() or None,
        "size": None,
        # centAmount viene ya en euros, pese al nombre.
        "price": value.get("centAmount") or None,
        "unit_price": value.get("centUnitAmount") or None,
        "unit": unit[-1].lower() if unit else None,
        "image_url": data.get("imageURL"),
        "category": cats[0].get("name"),
        "updated_at": now,
    }


def collect(now: str) -> list[dict]:
    rows: dict[str, dict] = {}
    offset, more = 0, True
    while more:
        data = _get(offset)
        for p in data.get("products", []):
            row = to_row(p, now)
            if row:
                rows[row["product_id"]] = row
        more = bool(data.get("hasMore")) and bool(data.get("products"))
        offset += 100
        time.sleep(0.5)  # sin prisa: una petición cada medio segundo
    return list(rows.values())


def _self_check() -> None:
    row = to_row({
        "code": "7080604",
        "productData": {"name": "Leche Semidesnatada Brik",
                        "description": "Leche Semidesnatada Brik 1 L",
                        "brand": {"name": "CONSUM"},
                        "imageURL": "https://cdn-consum.aktiosdigitalservices.com/x.jpg"},
        "priceData": {"prices": [{"value": {"centAmount": 0.83,
                                            "centUnitAmount": 0.83}}],
                      "unitPriceUnitType": "1 L"},
        "categories": [{"name": "Leche"}],
    }, "t")
    assert row["name"] == "Leche Semidesnatada Brik 1 L" and row["unit"] == "l"
    assert row["price"] == 0.83 and row["brand"] == "CONSUM"
    assert to_row({"code": "1"}, "t") is None


def main() -> None:
    _self_check()
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now)
    print(f"Consum: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la API ha cambiado, no se toca la tabla.")
    if "--dry-run" not in sys.argv:
        save(rows, now, STORE)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
