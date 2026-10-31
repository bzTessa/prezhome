"""Importa a Supabase las fichas públicas de producto de un súper con web.

Muchas tiendas online publican en su sitemap todas sus fichas de producto y
cada ficha lleva un bloque JSON-LD de schema.org (nombre, marca, precio,
foto). Este script lee las fichas del súper indicado (ver STORES) con pocas
peticiones a la vez y guarda lo mismo que mercadona_sync.py en
public.supermarket_products. Solo fichas que el robots.txt permite. Lo lanza
cada semana .github/workflows/open-prices.yml. Uso local sin escribir:
  python scripts/jsonld_sync.py ahorramas --dry-run
"""

import gzip
import html
import json
import re
import sys
import urllib.request
import urllib.robotparser
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from urllib.parse import urljoin

from mercadona_sync import save
from open_prices_sync import normalize

HEADERS = {"User-Agent": "Mozilla/5.0 (PrezHome; prezhomeapp@gmail.com)"}
WORKERS = 4
MIN_PRODUCTS = 500

# súper -> (índice de sitemaps, regex de fichas a leer). Solo los sitemaps de
# producto ("-product") y, si la URL lo dice, solo secciones de súper.
STORES = {
    "ahorramas": (
        "https://www.ahorramas.com/sitemap_index.xml",
        r"^https://www\.ahorramas\.com/.+-\d+\.html$",
    ),
    "pingodoce": (
        "https://www.pingodoce.pt/home/sitemap_index.xml",
        r"/home/produtos/(?!higiene|livraria|casa-e|animais|promocoes)[^/]+/",
    ),
    "auchan": (
        "https://www.auchan.pt/sitemap_index.xml",
        r"/pt/(alimentacao|bebidas-e-garrafeira|produtos-frescos|"
        r"limpeza-e-cuidados-do-lar|biologicos-e-alternativas)/",
    ),
}


def _get(url: str) -> str:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = resp.read()
    if body[:2] == b"\x1f\x8b":
        body = gzip.decompress(body)
    return body.decode("utf-8", "replace")


def _locs(xml: str) -> list[str]:
    return [html.unescape(u) for u in re.findall(r"<loc>\s*([^<\s]+)\s*</loc>", xml)]


def product_urls(index: str, pattern: str) -> list[str]:
    host = re.match(r"https://[^/]+", index).group(0)
    robots = urllib.robotparser.RobotFileParser(f"{host}/robots.txt")
    robots.read()
    urls = [
        u
        for sitemap in _locs(_get(index))
        if "-product" in sitemap
        for u in _locs(_get(sitemap))
        if re.search(pattern, u)
    ]
    return [u for u in dict.fromkeys(urls) if robots.can_fetch(HEADERS["User-Agent"], u)]


def product_ld(page: str) -> dict | None:
    """El bloque JSON-LD de tipo Product de una ficha, o None."""
    for block in re.findall(
        r"<script[^>]*application/ld\+json[^>]*>(.*?)</script>", page, re.S
    ):
        try:
            data = json.loads(block.strip())
        except ValueError:
            continue
        items = data if isinstance(data, list) else data.get("@graph", [data])
        for item in items:
            if isinstance(item, dict) and "Product" in str(item.get("@type")):
                return item
    return None


def to_row(store: str, url: str, page: str, now: str) -> dict | None:
    """Fila de supermarket_products para una ficha de producto, o None."""
    p = product_ld(page)
    name = html.unescape(str((p or {}).get("name") or "")).strip()
    if not name:
        return None
    brand = p.get("brand")
    brand = (brand.get("name") if isinstance(brand, dict) else brand) or None
    offers = p.get("offers")
    offer = (offers[0] if isinstance(offers, list) and offers else offers) or {}
    try:
        price = float(offer.get("price") or offer.get("lowPrice"))
    except (TypeError, ValueError, AttributeError):
        price = None
    image = p.get("image")
    image = image[0] if isinstance(image, list) and image else image
    if isinstance(image, dict):
        image = image.get("url")
    pid = str(p.get("sku") or p.get("productID") or url.rstrip("/").rsplit("/", 1)[-1])
    return {
        "store": store,
        "product_id": pid,
        "name": name,
        "name_normalized": normalize(name),
        "brand": html.unescape(str(brand)).strip() if brand else None,
        "size": None,
        "price": price,
        "unit_price": None,
        "unit": None,
        "image_url": urljoin(url, image) if isinstance(image, str) and image else None,
        "category": p.get("category") if isinstance(p.get("category"), str) else None,
        "updated_at": now,
    }


def _row_or_none(store: str, url: str, now: str) -> dict | None:
    try:
        return to_row(store, url, _get(url), now)
    except Exception:  # una ficha caída no tumba el catálogo
        return None


def collect(store: str, now: str) -> list[dict]:
    urls = product_urls(*STORES[store])
    with ThreadPoolExecutor(WORKERS) as pool:
        rows = pool.map(lambda u: _row_or_none(store, u, now), urls)
    return list({r["product_id"]: r for r in rows if r}.values())


def _self_check() -> None:
    page = (
        '<script type="application/ld+json">{"@context":"https://schema.org",'
        '"@type":"Product","sku":"52360","name":"Pimentón picante 75g",'
        '"brand":{"@type":"Brand","name":"Vega Cáceres"},'
        '"image":["/on/a.jpg"],'
        '"offers":{"@type":"Offer","price":"2.35"}}</script>'
    )
    row = to_row("ahorramas", "https://www.ahorramas.com/x-52360.html", page, "t")
    assert row["product_id"] == "52360" and row["price"] == 2.35
    assert row["brand"] == "Vega Cáceres" and row["image_url"] == "https://www.ahorramas.com/on/a.jpg"
    graph = '<script type="application/ld+json">{"@graph":[{"@type":"WebPage"},' \
        '{"@type":"Product","name":"Leite","offers":[{"price":0.9}]}]}</script>'
    assert to_row("auchan", "https://x/1.html", graph, "t")["price"] == 0.9
    assert to_row("auchan", "https://x/1.html", "<html></html>", "t") is None


def main() -> None:
    _self_check()
    store = sys.argv[1]
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(store, now)
    print(f"{store}: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la web ha cambiado, no se toca la tabla.")
    if "--dry-run" in sys.argv:
        print(rows[:3])
    else:
        save(rows, now, store)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
