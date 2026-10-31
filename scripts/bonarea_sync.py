"""Importa la sección de alimentación de bonÀrea online a Supabase.

bonÀrea no tiene API pública y su buscador pide antes una zona de reparto,
pero cada ficha de producto es pública. Se leen las del sitemap con código
13_ (alimentación) y 99_ (congelados): nombre, formato, precio, precio por
kg/l y la foto oficial (images.bonarea.com/<código>_1.png). Igual que
mercadona_sync.py, lo lanza cada semana .github/workflows/open-prices.yml.
Uso local sin escribir:
  python scripts/bonarea_sync.py --dry-run
"""

import html
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

from mercadona_sync import save
from open_prices_sync import normalize

SITEMAP = "https://www.bonarea-online.com/sitemap.xml"
HEADERS = {"User-Agent": "Mozilla/5.0 (PrezHome; prezhomeapp@gmail.com)"}
STORE = "bonarea"
MIN_PRODUCTS = 1000
# Pocas a la vez para no cargar su web: unas 3.600 fichas en ~20 min.
WORKERS = 4


def _get(url: str) -> str:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read().decode("utf-8", "replace")


def product_urls(sitemap: str) -> list[str]:
    """Fichas en castellano de alimentación y congelados, sin repetir."""
    urls = re.findall(
        r"<loc>(https://www\.bonarea-online\.com/online/producto/[^<]+/(?:13|99)_[^<]+)</loc>",
        sitemap,
    )
    return list(dict.fromkeys(urls))


def _euros(s: str | None) -> float | None:
    if not s:
        return None
    try:
        return float(s.replace(".", "").replace(",", "."))
    except ValueError:
        return None


def to_row(url: str, page: str, now: str) -> dict | None:
    """Fila de supermarket_products para una ficha de producto, o None."""
    pid = url.rsplit("/", 1)[-1]
    title = re.search(r"<h1 class=title>([^<]+)</h1>", page)
    if not title:
        return None
    name = html.unescape(title.group(1)).strip()
    size = re.search(r"<div class=subtitle>([^<]+)</div>", page)
    size = html.unescape(size.group(1)).strip() if size else None
    price = re.search(r'class="h2 bold">([\d.,]+)\s*€', page)
    unit = re.search(r"class=price-kl>\(([\d.,]+)\s*€/(\w+)\)", page)
    # Miga de pan: Alimentación > Quesos > ...; la sección es el 2.º nivel.
    cat = re.search(r"section-special-level[^>]*>([^<]+)</a>", page)
    full = f"{name} {size}" if size and size not in name else name
    return {
        "store": STORE,
        "product_id": pid,
        "name": full,
        "name_normalized": normalize(full),
        "brand": None,
        "size": size,
        "price": _euros(price.group(1)) if price else None,
        "unit_price": _euros(unit.group(1)) if unit else None,
        "unit": unit.group(2).lower() if unit else None,
        "image_url": f"https://images.bonarea.com/{pid}_1.png",
        "category": html.unescape(cat.group(1)).strip() if cat else None,
        "updated_at": now,
    }


def _row_or_none(url: str, now: str) -> dict | None:
    try:
        return to_row(url, _get(url), now)
    except Exception:  # una ficha caída no tumba el catálogo
        return None


def collect(now: str) -> list[dict]:
    urls = product_urls(_get(SITEMAP))
    with ThreadPoolExecutor(WORKERS) as pool:
        rows = pool.map(lambda u: _row_or_none(u, now), urls)
    return list({r["product_id"]: r for r in rows if r}.values())


def _self_check() -> None:
    page = (
        "<h1 class=title>Queso azul</h1><div class=subtitle>100 g</div>"
        '<span class="h2 bold">1,3 €/u</span> '
        "<span class=price-kl>(13,00 €/kg)</span>"
        '<a class="modal-breadcrumb section-special-level" '
        "data-ref=13*300*050>Quesos</a>"
    )
    url = "https://www.bonarea-online.com/online/producto/queso-azul/13_1627"
    row = to_row(url, page, "t")
    assert row["product_id"] == "13_1627" and row["name"] == "Queso azul 100 g"
    assert row["price"] == 1.3 and row["unit_price"] == 13.0
    assert row["unit"] == "kg" and row["category"] == "Quesos"
    assert row["image_url"] == "https://images.bonarea.com/13_1627_1.png"
    assert to_row(url, "<html></html>", "t") is None
    assert product_urls(
        f"<loc>{url}</loc><loc>{url}</loc>"
        "<loc>https://www.bonarea-online.com/online/producto/x/05_1</loc>"
    ) == [url]


def main() -> None:
    _self_check()
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now)
    print(f"bonÀrea: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la web ha cambiado, no se toca la tabla.")
    if "--dry-run" in sys.argv:
        print(rows[:3])
    else:
        save(rows, now, STORE)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
