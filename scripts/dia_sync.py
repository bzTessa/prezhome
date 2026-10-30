"""Importa el catálogo de la tienda online de Dia a Supabase.

Igual que mercadona_sync.py: nombre, marca, precio, precio por kg/l/ud y la
URL de la foto oficial en public.supermarket_products. Lo lanza cada semana
.github/workflows/open-prices.yml. Uso local sin escribir:
  python scripts/dia_sync.py --dry-run
"""

import json
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

from mercadona_sync import save
from open_prices_sync import normalize

# Con un código de sección que no existe (L101), Dia responde 404 pero con el
# surtido entero, 20 productos por página. Si un día lo cambia, MIN_PRODUCTS
# evita borrar el catálogo.
API = "https://www.dia.es/api/v1/plp-back/reduced?navigation=L101&page="
HEADERS = {"User-Agent": "Mozilla/5.0 (PrezHome; prezhomeapp@gmail.com)"}
STORE = "dia"
UNITS = {"KILO": "kg", "LITRO": "l", "UNIDAD": "ud"}
MIN_PRODUCTS = 1000


def _get(page: int) -> dict:
    req = urllib.request.Request(f"{API}{page}", headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise
        return json.load(e)


def to_row(item: dict, now: str) -> dict | None:
    """Fila de supermarket_products para un producto de la API, o None."""
    name = (item.get("display_name") or "").strip()
    pid = str(item.get("object_id") or "").strip()
    if not name or not pid:
        return None
    prices = item.get("prices") or {}
    image = item.get("image")
    return {
        "store": STORE,
        "product_id": pid,
        "name": name,
        "name_normalized": normalize(name),
        "brand": (item.get("brand") or "").strip() or None,
        "size": None,
        "price": prices.get("price") or None,
        "unit_price": prices.get("price_per_unit") or None,
        "unit": UNITS.get(prices.get("measure_unit") or ""),
        "image_url": f"https://www.dia.es{image}" if image else None,
        # "/frutas/platanos-y-bananas/p/42070" -> "frutas"
        "category": (item.get("url") or "/").split("/")[1] or None,
        "updated_at": now,
    }


def collect(now: str) -> list[dict]:
    rows: dict[str, dict] = {}
    page, pages = 1, 1
    while page <= pages:
        data = _get(page)
        pages = data.get("pagination", {}).get("total_pages", 1)
        for item in data.get("plp_items", []):
            row = to_row(item, now)
            if row:
                rows[row["product_id"]] = row
        page += 1
        time.sleep(0.5)  # sin prisa: una petición cada medio segundo
    return list(rows.values())


def _self_check() -> None:
    row = to_row({
        "object_id": "42070", "display_name": "Banana granel 900 g aprox.",
        "brand": "", "image": "/product_images/42070/42070_ISO_0_ES.jpg",
        "url": "/frutas/platanos-y-bananas/p/42070",
        "prices": {"price": 1.4, "price_per_unit": 1.55,
                   "measure_unit": "KILO"},
    }, "t")
    assert row["category"] == "frutas" and row["unit"] == "kg"
    assert row["price"] == 1.4 and row["brand"] is None
    assert row["image_url"].startswith("https://www.dia.es/product_images/")
    assert to_row({"object_id": "1"}, "t") is None


def main() -> None:
    _self_check()
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now)
    print(f"Dia: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la API ha cambiado, no se toca la tabla.")
    if "--dry-run" in sys.argv:
        from collections import Counter
        print(Counter(r["category"] for r in rows).most_common())
    else:
        save(rows, now, STORE)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
