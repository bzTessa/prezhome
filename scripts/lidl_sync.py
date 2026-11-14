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
(80) y las tarjetas regalo (30). Casi la mitad de las fichas salen sin precio
las semanas en que no están a la venta: entonces se conserva el último precio
conocido en vez de borrarlo. Igual que
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

from mercadona_sync import _rest
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


def page_data(page: str) -> dict:
    """Ficha completa que la web lleva dentro (__NUXT_DATA__, formato devalue:
    una lista plana donde cada objeto apunta a sus valores por índice)."""
    m = re.search(r'<script[^>]*id="__NUXT_DATA__"[^>]*>(.*?)</script>', page, re.S)
    if not m:
        return {}
    try:
        flat = json.loads(m.group(1))
    except ValueError:
        return {}

    def resolve(i: int, depth: int = 0):
        v = flat[i]
        if depth > 12:
            return None
        if isinstance(v, dict):
            return {k: resolve(j, depth + 1) if isinstance(j, int) else j for k, j in v.items()}
        if isinstance(v, list):
            if v and v[0] in ("Reactive", "ShallowReactive", "Ref", "ShallowRef"):
                return resolve(v[1], depth)
            return [resolve(j, depth + 1) if isinstance(j, int) else j for j in v]
        return v

    for i, v in enumerate(flat):
        if isinstance(v, dict) and "regionsPrices" in v and "productId" in v:
            data = resolve(i)
            return data if isinstance(data, dict) else {}
    return {}


def _amount(price: dict | None) -> float | None:
    value = (price or {}).get("price")
    return value if isinstance(value, (int, float)) and value > 0 else None


def _offer(regular: dict | None, member: dict | None) -> dict | None:
    """Precio normal y con Lidl Plus de un mismo momento. Si solo hay precio
    Lidl Plus, el normal es el tachado."""
    regular = regular or {}
    member = ((member or {}).get("price")) or {}
    price = _amount(regular)
    member_price = _amount(member)
    if price is None and member_price is not None:
        deleted = (member.get("discount") or {}).get("deletedPrice")
        price = deleted if isinstance(deleted, (int, float)) and deleted > 0 else None
    if price is None and member_price is None:
        return None
    return {
        "price": price,
        "member_price": member_price if member_price and (price is None or member_price < price) else None,
        "starts_at": regular.get("startDate") or member.get("startDate"),
        "size": ((regular.get("packaging") or member.get("packaging") or {}).get("text") or "").strip() or None,
    }


def store_price(data: dict) -> dict | None:
    """Precio de tienda de la zona por defecto: el de esta semana o, si el
    producto aún no está a la venta, el próximo con su fecha de inicio
    (starts_at; None si ya está a la venta)."""
    regions = data.get("regionsPrices") or {}
    if not isinstance(regions, dict) or not regions:
        return None
    default = next((r.get("regionPriceId") for r in (data.get("regionsV2") or {}).values()
                    if isinstance(r, dict) and r.get("isDefault")), None)
    ordered = [regions[default]] if default in regions else []
    ordered += [r for k, r in sorted(regions.items()) if k != default]
    ordered = [r for r in ordered if isinstance(r, dict)]
    for r in ordered:
        now = _offer(r.get("currentPrice"), r.get("currentLidlPlusPrice"))
        if now:
            return dict(now, starts_at=None)
    upcoming = []
    for r in ordered:
        member = {((f.get("price") or {}).get("startDate")): f
                  for f in (r.get("futureLidlPlusPrices") or []) if isinstance(f, dict)}
        for f in r.get("futurePrices") or []:
            if isinstance(f, dict):
                start = (f.get("price") or {}).get("startDate")
                upcoming.append(_offer(f.get("price"), member.pop(start, None)))
        upcoming += [_offer(None, f) for f in member.values()]
    upcoming = [u for u in upcoming if u and u["starts_at"]]
    return min(upcoming, key=lambda u: u["starts_at"]) if upcoming else None


def light_image(data: dict, image: str | None) -> str | None:
    """La misma foto en el tamaño "small" (380 px, ~55 KB): la del JSON-LD es
    la "medium" (~200-500 KB), demasiado para una lista en el móvil."""
    images = [i for i in ((data.get("media") or {}).get("imageMap") or {}).values()
              if isinstance(i, dict)]
    same = next((i for i in images if image and image in (
        i.get("mediumUrl"), i.get("largeUrl"), i.get("smallUrl"))), None)
    return (same or {}).get("smallUrl") or image


def shelf_ean(eans) -> str | None:
    """Código de barras del envase. Los de 13 cifras que empiezan por 2 son de
    peso variable (cambian con cada pieza): no sirven para escanear."""
    for ean in eans or []:
        ean = str(ean).strip()
        if ean.isdigit() and not (len(ean) == 13 and ean.startswith("2")):
            return ean
    return None


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
    data = page_data(page)
    price = store_price(data)
    if not size and price:
        size = price["size"]
    category = ((data.get("keyfacts") or {}).get("wonCategoryPrimary") or "").split("/")[-1]
    full = " ".join(p for p in (name.strip(" -"), brand, size) if p)
    return {
        "store": store,
        "product_id": str(product.get("sku") or url.rsplit("/p", 1)[-1]),
        "name": full,
        "name_normalized": normalize(full),
        "brand": brand,
        "size": size,
        "price": price["price"] if price else offers[0].get("price"),
        "member_price": price["member_price"] if price else None,
        "price_starts_at": price["starts_at"] if price else None,
        "ean": shelf_ean(data.get("eans")),
        "unit_price": None,
        "unit": None,
        "image_url": light_image(data, images[0] if isinstance(images, list) else images),
        "category": category.strip() or None,
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


def upsert_batches(rows: list[dict]) -> list[list[dict]]:
    """Lotes para guardar: las filas sin precio van sin la columna price,
    así el upsert deja el último precio conocido."""
    priced = [r for r in rows if r["price"] is not None]
    unpriced = [{k: v for k, v in r.items() if k != "price"}
                for r in rows if r["price"] is None]
    return [g[i:i + 500] for g in (priced, unpriced) for i in range(0, len(g), 500)]


def save(rows: list[dict], now: str, store: str) -> None:
    for batch in upsert_batches(rows):
        _rest("POST", "supermarket_products?on_conflict=store,product_id", batch)
    # Lo que ya no tiene ficha no se vende.
    stamp = now.replace("+", "%2B")
    _rest("DELETE", f"supermarket_products?store=eq.{store}&updated_at=lt.{stamp}")


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
    assert row["category"] is None  # sin __NUXT_DATA__ sigue valiendo el JSON-LD
    def nuxt(obj: dict) -> str:
        flat: list = [None]
        def put(v) -> int:
            if isinstance(v, dict):
                i = len(flat); flat.append(None)
                flat[i] = {k: put(x) for k, x in v.items()}
                return i
            if isinstance(v, list):
                i = len(flat); flat.append(None)
                flat[i] = [put(x) for x in v]
                return i
            flat.append(v)
            return len(flat) - 1
        flat[0] = ["Reactive", put(obj)]
        return f'<script type="application/json" id="__NUXT_DATA__">{json.dumps(flat)}</script>'
    soon = {"price": 6.99, "startDate": "2026-11-19T23:00Z", "packaging": {"text": "500 g"}}
    later = {"price": 7.49, "startDate": "2026-12-01T23:00Z"}
    product = {
        "productId": 1,
        "keyfacts": {"wonCategoryPrimary": "Mundos/Comida/Café, té y cacao"},
        "regionsV2": {"1": {"regionPriceId": "2", "isDefault": False},
                      "9": {"regionPriceId": "1", "isDefault": True}},
        "regionsPrices": {"2": {"currentPrice": {"price": 3.39}},
                          "1": {"currentPrice": {"price": 2.99}}},
    }
    row = to_row(url, page + nuxt(product), "t")
    assert row["price"] == 2.99 and row["category"] == "Café, té y cacao"
    assert row["image_url"] == "https://www.lidl.es/assets/a.png"  # sin media, la de siempre
    product["media"] = {"imageMap": {"7": {
        "mediumUrl": "https://www.lidl.es/assets/a.png",
        "smallUrl": "https://www.lidl.es/assets/a-small.png"}}}
    assert to_row(url, page + nuxt(product), "t")["image_url"].endswith("a-small.png")
    product["regionsPrices"] = {"1": {"futurePrices": [{"price": later}, {"price": soon}]}}
    row = to_row(url, page.replace("Aprox.220 g", "") + nuxt(product), "t")
    assert row["price"] == 6.99 and row["size"] == "500 g"
    assert row["price_starts_at"] == "2026-11-19T23:00Z" and row["member_price"] is None
    product["eans"] = ["4335619482951"]
    product["regionsPrices"] = {"1": {"currentLidlPlusPrice": {"price": {
        "price": 1.19, "discount": {"deletedPrice": 1.49}}}}}
    row = to_row(url, page + nuxt(product), "t")
    assert (row["price"], row["member_price"]) == (1.49, 1.19)
    assert row["ean"] == "4335619482951" and row["price_starts_at"] is None
    assert shelf_ean(["2269780000000", "20099763"]) == "20099763"
    assert shelf_ean(["2269780000000"]) is None
    assert to_row(url, page.replace("REALVALLE", "-"), "t", "lidl_fr")["brand"] is None
    assert store_key("fr") == "lidl_fr" and store_key("es") == "lidl"
    batches = upsert_batches([row, dict(row, price=None, product_id="2")])
    assert batches[0] == [row] and "price" not in batches[1][0]
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
