"""Importa precios de referencia de Open Prices (Open Food Facts) a Supabase.

Open Prices es una base de datos ABIERTA (licencia ODbL) de precios que sube la
comunidad a partir de tickets y etiquetas de supermercado. Este script:
  1. descarga los precios de los países de COUNTRIES (últimos 2 años),
  2. los convierte a precio por kg, l o ud y los agrupa por alimento (mismas
     claves que ApproxPrice en la app: 'tomate', 'leche'...),
  3. guarda la MEDIANA de cada alimento en public.market_prices.

Lo lanza cada semana .github/workflows/open-prices.yml. Sin dependencias
externas (solo biblioteca estándar). Uso local sin escribir nada:
  python scripts/open_prices_sync.py --dry-run

Los nombres de producto vienen de terceros: solo se usan para buscar palabras
clave conocidas, nunca se guardan ni se interpretan como instrucciones.
"""

import json
import os
import statistics
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from datetime import date, timedelta

API = "https://prices.openfoodfacts.org/api/v1"
HEADERS = {"User-Agent": "PrezHome/1.0 (prezhomeapp@gmail.com)"}

# País -> (fragmento del nombre del país en OSM para filtrar tiendas, moneda).
# Para abrir otro país basta con añadir su línea.
COUNTRIES = {"ES": ("Espa", "EUR")}

# Primera palabra del nombre del producto -> clave de alimento de la app.
# Incluye catalán porque muchos tickets de España vienen en catalán.
NAME_KEYWORDS = {
    "leche": "leche", "llet": "leche",
    "arroz": "arroz", "arros": "arroz",
    "queso": "queso", "formatge": "queso",
    "pasta": "pasta", "espaguetis": "pasta", "macarrones": "pasta",
    "harina": "harina", "farina": "harina",
    "lentejas": "lenteja", "llenties": "lenteja",
    "garbanzos": "garbanzo", "cigrons": "garbanzo",
    "avena": "avena", "civada": "avena",
    "azucar": "azucar", "sucre": "azucar",
    "mantequilla": "mantequilla", "mantega": "mantequilla",
    "yogur": "yogur", "iogurt": "yogur",
    "aceite": "aceite", "oli": "aceite",
    "nata": "nata",
    "pollo": "pollo", "pollastre": "pollo",
    "pechuga": "pechuga",
    "pavo": "pavo",
    "ternera": "ternera", "vedella": "ternera",
    "cerdo": "cerdo", "porc": "cerdo",
    "jamon": "jamon", "pernil": "jamon",
    "bacon": "bacon",
    "salmon": "salmon", "salmo": "salmon",
    "merluza": "merluza", "lluc": "merluza",
    "atun": "atun", "tonyina": "atun",
    "gambas": "gambas",
    "tomate": "tomate", "tomaquet": "tomate",
    "cebolla": "cebolla", "ceba": "cebolla",
    "patata": "patata", "patatas": "patata",
    "zanahoria": "zanahoria", "pastanaga": "zanahoria",
}

# Palabras que indican un producto ELABORADO: "Tomate frito" no es tomate.
PROCESSED = {
    "frito", "salsa", "crema", "zumo", "suc", "batido", "cocida", "cocido",
    "untable", "ratllat", "rallado", "chocolate", "xocolata", "galletas",
    "galetes", "tortilla", "tortilles", "pizza", "caldo", "brou", "claras",
    "polvo", "sabor", "bebida", "beguda", "fritas", "frites", "chips",
}

# Categoría de Open Prices (fruta/verdura a granel) -> clave de la app.
CATEGORY_KEYWORDS = {
    "en:tomatoes": "tomate", "en:onions": "cebolla", "en:garlic": "ajo",
    "en:potatoes": "patata", "en:carrots": "zanahoria",
    "en:peppers": "pimiento", "en:zucchini": "calabacin",
    "en:courgettes": "calabacin", "en:broccoli": "brocoli",
    "en:spinachs": "espinaca", "en:lettuces": "lechuga",
    "en:mushrooms": "champinon", "en:apples": "manzana",
    "en:bananas": "platano", "en:oranges": "naranja",
    "en:strawberries": "fresa", "en:avocados": "aguacate",
    "en:lemons": "limon",
}

# Límites de cordura por kg/l/ud (descarta errores de escaneo).
MIN_PRICE, MAX_PRICE = 0.05, 200.0
MIN_SAMPLES = 3


def normalize(text: str) -> str:
    """Igual que CategoryIcons.normalize: minúsculas y sin acentos."""
    text = unicodedata.normalize("NFKD", text.lower().strip())
    return "".join(c for c in text if not unicodedata.combining(c))


def _get(path: str, params: dict) -> dict:
    url = f"{API}/{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def _paged(path: str, params: dict):
    page = 1
    while True:
        data = _get(path, {**params, "size": 100, "page": page})
        yield from data.get("items", [])
        if page >= data.get("pages", 1):
            return
        page += 1
        time.sleep(0.3)  # educados con la API comunitaria


def keyword_for_name(name: str) -> str | None:
    """Clave de alimento si la PRIMERA palabra es un alimento conocido y el
    nombre no es de un producto elaborado."""
    tokens = "".join(c if c.isalnum() else " " for c in normalize(name)).split()
    if not tokens or any(t in PROCESSED for t in tokens):
        return None
    return NAME_KEYWORDS.get(tokens[0])


def unit_price(row: dict) -> tuple[str, str, float] | None:
    """(clave, unidad 'kg'|'l'|'ud', precio por unidad) de una fila, o None."""
    price = row.get("price_without_discount") or row.get("price")
    if not price or price <= 0:
        return None
    if row.get("type") == "CATEGORY":
        key = CATEGORY_KEYWORDS.get(row.get("category_tag") or "")
        per = {"KILOGRAM": "kg", "UNIT": "ud"}.get(row.get("price_per") or "")
        return (key, per, float(price)) if key and per else None
    product = row.get("product") or {}
    key = keyword_for_name(product.get("product_name") or "")
    qty = product.get("product_quantity")
    unit = product.get("product_quantity_unit")
    if not key or not qty or qty <= 0:
        return None
    if unit == "g":
        return key, "kg", float(price) / (qty / 1000)
    if unit == "ml":
        return key, "l", float(price) / (qty / 1000)
    return None


def aggregate(rows: list[dict], currency: str, since: str) -> dict:
    """{(clave, unidad): [precios]} con las filas válidas del país."""
    groups: dict[tuple[str, str], list[float]] = {}
    for row in rows:
        if row.get("currency") != currency or (row.get("date") or "") < since:
            continue
        hit = unit_price(row)
        if hit and MIN_PRICE <= hit[2] <= MAX_PRICE:
            groups.setdefault(hit[:2], []).append(hit[2])
    return groups


def collect(country: str) -> list[dict]:
    name_like, currency = COUNTRIES[country]
    since = (date.today() - timedelta(days=730)).isoformat()
    rows = []
    for loc in _paged("locations", {"osm_address_country__like": name_like}):
        if loc.get("osm_address_country_code") != country:
            continue
        if not loc.get("price_count"):
            continue
        rows.extend(_paged("prices", {"location_id": loc["id"]}))
    out = []
    for (key, unit), prices in aggregate(rows, currency, since).items():
        if len(prices) < MIN_SAMPLES:
            continue
        out.append({
            "country_code": country,
            "keyword": key,
            "unit": unit,
            "currency": currency,
            "median_price": round(statistics.median(prices), 2),
            "samples": len(prices),
            "updated_at": date.today().isoformat(),
        })
    return out


def upsert(rows: list[dict]) -> None:
    url = os.environ["SUPABASE_URL"].rstrip("/")
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    req = urllib.request.Request(
        f"{url}/rest/v1/market_prices?on_conflict=country_code,keyword,unit",
        data=json.dumps(rows).encode(),
        method="POST",
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )
    with urllib.request.urlopen(req, timeout=60):
        pass


def _self_check() -> None:
    assert keyword_for_name("Llet desnatada UHT") == "leche"
    assert keyword_for_name("Tomate frito") is None
    assert keyword_for_name("Coca-Cola Zero") is None
    assert keyword_for_name("Patatas fritas lisas") is None
    assert unit_price({"type": "PRODUCT", "price": 1.5, "product": {
        "product_name": "Arròs llarg", "product_quantity": 500,
        "product_quantity_unit": "g"}}) == ("arroz", "kg", 3.0)
    assert unit_price({"type": "CATEGORY", "price": 2.0,
                       "category_tag": "en:tomatoes",
                       "price_per": "KILOGRAM"}) == ("tomate", "kg", 2.0)
    groups = aggregate([
        {"type": "CATEGORY", "price": p, "category_tag": "en:onions",
         "price_per": "KILOGRAM", "currency": "EUR", "date": "2026-01-01"}
        for p in (1.0, 2.0, 3.0, 999.0)
    ], "EUR", "2025-01-01")
    assert groups == {("cebolla", "kg"): [1.0, 2.0, 3.0]}


def main() -> None:
    _self_check()
    dry = "--dry-run" in sys.argv
    rows = [r for c in COUNTRIES for r in collect(c)]
    for r in sorted(rows, key=lambda r: (r["country_code"], r["keyword"])):
        print(f"{r['country_code']} {r['keyword']:<12} {r['median_price']:>6} "
              f"{r['currency']}/{r['unit']}  ({r['samples']} precios)")
    if not rows:
        sys.exit("Open Prices no devolvió precios válidos: no se toca la tabla.")
    if not dry:
        upsert(rows)
        print(f"Guardados {len(rows)} precios de referencia.")


if __name__ == "__main__":
    main()
