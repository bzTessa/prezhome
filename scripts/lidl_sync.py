"""Importa los productos de alimentación de la web de Lidl a Supabase.

Por defecto Lidl España (tienda "lidl"); con un país (fr, it, de, pt) lee
la web de Lidl de ese país y guarda la tienda "lidl_<país>".

Lidl no vende comida online, pero su web tiene ficha pública (con precio de
tienda) de buena parte de lo que hay en tienda. robots.txt prohíbe su
buscador, no las fichas: se leen las del sitemap de productos de
supermercado y de cada una el JSON-LD (nombre, marca, precio, foto) y el
formato ("Aprox.220 g"). El código dice qué es: 11 alimentación, 12
temporada (Deluxe, Navidad), 60 y 66 básicos de Italia y Portugal (pasta,
huevos, detergente). Se dejan fuera el bazar (10, 85), los packs solo online
(80) y las tarjetas regalo (30). Igual que
mercadona_sync.py, lo lanza cada semana .github/workflows/open-prices.yml.
Uso local sin escribir:
  python scripts/lidl_sync.py --dry-run
  python scripts/lidl_sync.py fr --dry-run
"""

import gzip
import html
import json
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

from mercadona_sync import save
from open_prices_sync import normalize

# país -> idioma de su web
COUNTRIES = {"es": "es", "fr": "fr", "it": "it", "de": "de", "pt": "pt"}
HEADERS = {"User-Agent": "Mozilla/5.0 (PrezHome; prezhomeapp@gmail.com)"}
MIN_PRODUCTS = 100
WORKERS = 4
# Prefijos de código de producto que se venden en el súper (ver arriba).
SUPERMARKET_CODES = "11|12|60|66"


def _get(url: str) -> bytes:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def sitemap_url(country: str) -> str:
    return (
        f"https://www.lidl.{country}/p/export/"
        f"{country.upper()}/{COUNTRIES[country]}/product_sitemap.xml.gz"
    )


def store_key(country: str) -> str:
    return "lidl" if country == "es" else f"lidl_{country}"


def product_urls(sitemap: str) -> list[str]:
    """Fichas de supermercado (ver SUPERMARKET_CODES), sin repetir."""
    urls = re.findall(
        rf"<loc>(https://www\.lidl\.[a-z]+/p/[^<]+/p(?:{SUPERMARKET_CODES})\d+)</loc>",
        sitemap,
    )
    return list(dict.fromkeys(urls))


def to_row(url: str, page: str, now: str, store: str = "lidl") -> dict | None:
    """Fila de supermarket_products para una ficha de producto, o None."""
    product = None
    for block in re.findall(
        r'<script type="application/ld\+json"[^>]*>(.*?)</script>', page, re.S
    ):
        try:
            data = json.loads(block)
        except ValueError:
            continue
        if isinstance(data, dict) and data.get("@type") == "Product":
            product = data
            break
    if not product or not (product.get("name") or "").strip():
        return None
    name = html.unescape(product["name"]).strip()
    brand = ((product.get("brand") or {}).get("name") or "").strip(" -").title() or None
    offers = product.get("offers") or [{}]
    images = product.get("image") or [None]
    size = re.search(r'ods-price__footer.*?class="block-text"[^>]*>([^<]+)</span>', page, re.S)
    size = html.unescape(size.group(1)).replace("Aprox.", "").strip(" -") or None if size else None
    full = " ".join(p for p in (name.strip(" -"), brand, size) if p)
    return {
        "store": store,
        "product_id": str(product.get("sku") or url.rsplit("/p", 1)[-1]),
        "name": full,
        "name_normalized": normalize(full),
        "brand": brand,
        "size": size,
        "price": offers[0].get("price"),
        "unit_price": None,
        "unit": None,
        "image_url": images[0] if isinstance(images, list) else images,
        "category": None,
        "updated_at": now,
    }


def _row_or_none(url: str, now: str, store: str) -> dict | None:
    try:
        return to_row(url, _get(url).decode("utf-8", "replace"), now, store)
    except Exception:  # una ficha caída no tumba el catálogo
        return None


def collect(now: str, country: str) -> list[dict]:
    store = store_key(country)
    urls = product_urls(gzip.decompress(_get(sitemap_url(country))).decode("utf-8"))
    with ThreadPoolExecutor(WORKERS) as pool:
        rows = pool.map(lambda u: _row_or_none(u, now, store), urls)
    return list({r["product_id"]: r for r in rows if r}.values())


def _self_check() -> None:
    page = (
        '<script type="application/ld+json">{"@type":"Product","sku":"11000881",'
        '"name":"Jamón cocido ahumado","image":["https://www.lidl.es/assets/a.png"],'
        '"brand":{"name":"REALVALLE"},"offers":[{"price":3.65}]}</script>'
        '<div class="ods-price__footer" data-v-1><span class="block-text" '
        'data-v-2>Aprox.220 g</span>'
    )
    url = "https://www.lidl.es/p/realvalle-jamon-cocido-ahumado/p11000881"
    row = to_row(url, page, "t")
    assert row["product_id"] == "11000881" and row["price"] == 3.65
    assert row["name"] == "Jamón cocido ahumado Realvalle 220 g"
    assert row["brand"] == "Realvalle" and row["size"] == "220 g"
    assert row["image_url"] == "https://www.lidl.es/assets/a.png"
    assert to_row(url, "<html></html>", "t") is None
    assert to_row(url, page.replace("REALVALLE", "-"), "t", "lidl_fr")["brand"] is None
    assert store_key("fr") == "lidl_fr" and store_key("es") == "lidl"
    assert sitemap_url("it").endswith("lidl.it/p/export/IT/it/product_sitemap.xml.gz")
    assert product_urls(
        f"<loc>{url}</loc><loc>{url}</loc>"
        "<loc>https://www.lidl.es/p/silvercrest-espumador/p100401586</loc>"
        "<loc>https://www.lidl.es/p/deluxe-picana-de-pato/p12178745</loc>"
        "<loc>https://www.lidl.it/p/detersivo-lavatrice/p66000161</loc>"
        "<loc>https://www.lidl.it/p/spaghetti/p6006216</loc>"
        "<loc>https://www.lidl.de/p/lidl-geschenkkarte/p300000712</loc>"
        "<loc>https://www.lidl.fr/p/livarno-ensemble-de-jardin/p800012224</loc>"
    ) == [
        url,
        "https://www.lidl.es/p/deluxe-picana-de-pato/p12178745",
        "https://www.lidl.it/p/detersivo-lavatrice/p66000161",
        "https://www.lidl.it/p/spaghetti/p6006216",
    ]


def main() -> None:
    _self_check()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    country = args[0] if args else "es"
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now, country)
    print(f"Lidl {country}: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la web ha cambiado, no se toca la tabla.")
    if "--dry-run" in sys.argv:
        print(rows[:3])
    else:
        save(rows, now, store_key(country))
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
