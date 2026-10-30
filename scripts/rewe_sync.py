"""Importa el catálogo de la tienda online de REWE (Alemania) a Supabase.

Igual que mercadona_sync.py, pero REWE no da precios sin elegir tienda, así
que solo se guardan nombre, marca, categoría y la URL de la foto oficial. Lo
lanza cada semana .github/workflows/open-prices.yml. Uso local sin escribir:
  python scripts/rewe_sync.py --dry-run
"""

import json
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

from mercadona_sync import save
from open_prices_sync import normalize

API = "https://shop.rewe.de/api/products"
HEADERS = {"User-Agent": "Mozilla/5.0 (PrezHome; prezhomeapp@gmail.com)"}
STORE = "rewe"
# Categorías de la tienda (sin las temáticas, que repiten productos).
CATEGORIES = [
    "obst-gemuese", "fleisch-wurst-fisch", "kaese-eier-molkerei",
    "tiefkuehlkost", "backwaren-cerealien-aufstriche", "kochen-backen",
    "oele-sossen-gewuerze", "fertiggerichte-konserven", "suesses-salziges",
    "kaffee-tee-kakao", "getraenke-genussmittel", "drogerie-gesundheit",
    "baby-kind", "kueche-haushalt",
]
MIN_PRODUCTS = 5000


def _get(params: dict) -> dict:
    url = f"{API}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def to_row(product: dict, now: str) -> dict | None:
    """Fila de supermarket_products para un producto de la API, o None."""
    name = (product.get("productName") or "").strip()
    pid = str(product.get("id") or "").strip()
    if not name or not pid:
        return None
    images = (product.get("media") or {}).get("images") or []
    image = images[0]["_links"]["self"]["href"] if images else None
    path = (product.get("_embedded") or {}).get("categoryPath") or ""
    brand = ((product.get("brand") or {}).get("name") or "").strip()
    return {
        "store": STORE,
        "product_id": pid,
        "name": name,
        "name_normalized": normalize(name),
        "brand": brand or None,
        "size": None,
        "price": None,
        "unit_price": None,
        "unit": None,
        "image_url": image,
        "category": path.split("/")[0] or None,
        "updated_at": now,
    }


def collect(now: str) -> list[dict]:
    rows: dict[str, dict] = {}
    for slug in CATEGORIES:
        page, pages = 1, 1
        # shortcut: la API corta en 10.000 productos por consulta (solo afecta
        # a bebidas); si faltaran, recorrer sus subcategorías.
        while page <= pages:
            data = _get({"categorySlug": slug, "objectsPerPage": 250,
                         "page": page})
            pages = data.get("pagination", {}).get("totalPages", 1)
            for p in (data.get("_embedded") or {}).get("products", []):
                row = to_row(p, now)
                if row:
                    rows[row["product_id"]] = row
            page += 1
            time.sleep(0.5)  # sin prisa: una petición cada medio segundo
    return list(rows.values())


def _self_check() -> None:
    row = to_row({
        "id": "7043234", "productName": "REWE Bio Zwiebeln 500g",
        "brand": {"name": "REWE Bio"},
        "media": {"images": [{"_links": {"self": {
            "href": "https://img.rewe-static.de/7043234/x.png"}}}]},
        "_embedded": {"categoryPath": "Obst & Gemüse/Frisches Gemüse/"},
    }, "t")
    assert row["brand"] == "REWE Bio" and row["category"] == "Obst & Gemüse"
    assert row["image_url"].endswith("x.png") and row["price"] is None
    assert to_row({"id": "1"}, "t") is None


def main() -> None:
    _self_check()
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now)
    print(f"REWE: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la API ha cambiado, no se toca la tabla.")
    if "--dry-run" not in sys.argv:
        save(rows, now, STORE)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
