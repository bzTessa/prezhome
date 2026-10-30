"""Importa el catálogo de la tienda online de Mercadona a Supabase.

Para cada producto guarda nombre, formato, precio, precio por kg/l/ud y la URL
de su foto oficial (no la imagen) en public.supermarket_products. Los productos
que ya no aparecen se borran. Lo lanza cada semana
.github/workflows/open-prices.yml. Sin dependencias externas. Uso local sin
escribir nada:
  python scripts/mercadona_sync.py --dry-run

Los textos vienen de un tercero: solo se guardan como datos, nunca se
interpretan como instrucciones.
"""

import json
import os
import sys
import time
import urllib.request
from datetime import datetime, timezone

from open_prices_sync import normalize

API = "https://tienda.mercadona.es/api"
HEADERS = {"User-Agent": "PrezHome/1.0 (prezhomeapp@gmail.com)"}
STORE = "mercadona"
# Si sale muchísimo menos, la API ha cambiado: mejor no tocar la tabla.
MIN_PRODUCTS = 1000


def _get(path: str) -> dict:
    req = urllib.request.Request(f"{API}/{path}?lang=es", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def _num(value) -> float | None:
    try:
        n = float(str(value).strip())
    except (TypeError, ValueError):
        return None
    return n if n > 0 else None


def to_row(product: dict, category: str, now: str) -> dict | None:
    """Fila de supermarket_products para un producto de la API, o None."""
    name = (product.get("display_name") or "").strip()
    pid = str(product.get("id") or "").strip()
    if not name or not pid or not product.get("published", True):
        return None
    pi = product.get("price_instructions") or {}
    size_n, fmt = _num(pi.get("unit_size")), pi.get("size_format")
    return {
        "store": STORE,
        "product_id": pid,
        "name": name,
        "name_normalized": normalize(name),
        "size": f"{size_n:g} {fmt}" if size_n and fmt else None,
        "price": _num(pi.get("unit_price")),
        "unit_price": _num(pi.get("reference_price") or pi.get("bulk_price")),
        "unit": (pi.get("reference_format") or "").lower() or None,
        "image_url": product.get("thumbnail"),
        "category": category,
        "updated_at": now,
    }


def collect(now: str) -> list[dict]:
    rows: dict[str, dict] = {}
    for top in _get("categories/").get("results", []):
        for sub in top.get("categories", []):
            detail = _get(f"categories/{sub['id']}/")
            for group in detail.get("categories", []):
                for p in group.get("products", []):
                    row = to_row(p, sub.get("name") or "", now)
                    if row:
                        rows[row["product_id"]] = row
            time.sleep(0.5)  # sin prisa: una petición cada medio segundo
    return list(rows.values())


def _rest(method: str, path: str, body: list | None = None) -> None:
    url = os.environ["SUPABASE_URL"].rstrip("/")
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    req = urllib.request.Request(
        f"{url}/rest/v1/{path}",
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )
    with urllib.request.urlopen(req, timeout=120):
        pass


def save(rows: list[dict], now: str) -> None:
    for i in range(0, len(rows), 500):
        _rest("POST", "supermarket_products?on_conflict=store,product_id",
              rows[i:i + 500])
    # Lo que no se ha visto en esta pasada ya no está a la venta.
    stamp = now.replace("+", "%2B")
    _rest("DELETE", f"supermarket_products?store=eq.{STORE}&updated_at=lt.{stamp}")


def _self_check() -> None:
    row = to_row({
        "id": "4241", "display_name": "Aceite de oliva 0,4º Hacendado",
        "published": True,
        "thumbnail": "https://prod-mercadona.imgix.net/images/x.jpg",
        "price_instructions": {"unit_size": 5.0, "size_format": "l",
                               "unit_price": "16.75", "bulk_price": "3.35",
                               "reference_price": "3.350",
                               "reference_format": "L"},
    }, "Aceite de oliva", "t")
    assert row["size"] == "5 l" and row["price"] == 16.75
    assert row["unit_price"] == 3.35 and row["unit"] == "l"
    assert row["name_normalized"].startswith("aceite de oliva")
    assert to_row({"id": "1", "display_name": " "}, "", "t") is None


def main() -> None:
    _self_check()
    now = datetime.now(timezone.utc).isoformat()
    rows = collect(now)
    print(f"Mercadona: {len(rows)} productos")
    if len(rows) < MIN_PRODUCTS:
        sys.exit("Muy pocos productos: la API ha cambiado, no se toca la tabla.")
    if "--dry-run" not in sys.argv:
        save(rows, now)
        print("Catálogo guardado.")


if __name__ == "__main__":
    main()
