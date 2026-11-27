"""Importa el catálogo online de Consum o BM Supermercados a Supabase.

Igual que mercadona_sync.py: nombre con formato, marca, precio, precio por
kg/l/ud y la URL de la foto oficial en public.supermarket_products. Lo lanza
cada semana .github/workflows/open-prices.yml. Uso local sin escribir:
  python scripts/consum_sync.py --dry-run
  python scripts/consum_sync.py bm --dry-run
"""

import json
import sys
import time
import urllib.request
from datetime import datetime, timezone

from mercadona_sync import save
from open_prices_sync import normalize

STORES = {
    "consum": "https://tienda.consum.es/api/rest/V1.0/catalog/product?limit=100&offset=",
    "bm": "https://www.online.bmsupermercados.es/api/rest/V1.0/catalog/product?limit=100&offset=",
}
UNITS = {
    "kilo": "kg",
    "kg": "kg",
    "gr": "g",
    "g": "g",
    "litro": "l",
    "l": "l",
    "ml": "ml",
    "unidad": "ud",
    "ud": "ud",
    "u.": "ud",
    "u": "ud",
}
HEADERS = {"User-Agent": "PrezHome/1.0 (prezhomeapp@gmail.com)"}
STORE = "consum"
MIN_PRODUCTS = 1000


def _get(api_base: str, offset: int) -> dict:
    req = urllib.request.Request(f"{api_base}{offset}", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def to_row(product: dict, now: str, store: str = STORE) -> dict | None:
    """Fila de supermarket_products para un producto de la API, o None."""
    data = product.get("productData") or {}
    # La descripción lleva el formato ("Leche Semidesnatada Brik 1 L").
    name = (data.get("description") or data.get("name") or "").strip()
    pid = str(product.get("code") or product.get("id") or "").strip()
    if not name or not pid:
        return None
    price_data = product.get("priceData") or {}
    value = ((price_data.get("prices") or [{}])[0]).get("value") or {}
    unit_parts = (price_data.get("unitPriceUnitType") or "").strip().lower().split()
    unit_raw = unit_parts[-1] if unit_parts else ""
    cats = product.get("categories") or [{}]
    return {
        "store": store,
        "product_id": pid,
        "name": name,
        "name_normalized": normalize(name),
        "brand": ((data.get("brand") or {}).get("name") or "").strip() or None,
        "size": None,
        "ean": (product.get("ean") or "").strip() or None,
        # centAmount viene ya en euros, pese al nombre.
        "price": value.get("centAmount") or None,
        "unit_price": value.get("centUnitAmount") or None,
        "unit": UNITS.get(unit_raw, unit_raw or None),
        "image_url": data.get("imageURL"),
        "category": cats[0].get("name"),
        "updated_at": now,
    }


def collect(now: str, store: str = STORE) -> list[dict]:
    api_base = STORES[store]
    rows: dict[str, dict] = {}
    offset, more = 0, True
    while more:
        data = _get(api_base, offset)
        for p in data.get("products", []):
            row = to_row(p, now, store=store)
            if row:
                rows[row["product_id"]] = row
        more = bool(data.get("hasMore")) and bool(data.get("products"))
        offset += 100
        time.sleep(0.5)  # sin prisa: una petición cada medio segundo
    return list(rows.values())


def _self_check() -> None:
    row = to_row({
        "code": "7080604",
        "ean": "8410000000001",
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
    assert row["ean"] == "8410000000001"
    bm_row = to_row({
        "code": "1330",
        "ean": "8410830001016",
        "productData": {"description": "Arroz redondo 1 kg", "brand": {"name": "BM"}},
        "priceData": {"prices": [{"value": {"centAmount": 1.88, "centUnitAmount": 1.88}}],
                      "unitPriceUnitType": "KILO"},
    }, "t", store="bm")
    assert bm_row["store"] == "bm" and bm_row["unit"] == "kg"
    assert to_row({"code": "1"}, "t") is None


def main() -> None:
    _self_check()
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    store = args[0] if args and args[0] in STORES else STORE
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now, store=store)
    print(f"{store}: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la API ha cambiado, no se toca la tabla.")
    if "--dry-run" not in sys.argv:
        save(rows, now, store)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
