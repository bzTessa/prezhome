-- ============================================================================
-- PrezHome · Catálogo de súper: código de barras, precio con tarjeta y fecha
-- ============================================================================
-- Lidl publica en cada ficha el código de barras (EAN), el precio para
-- clientes Lidl Plus y, si el producto aún no está a la venta, desde cuándo
-- vale su precio. Lo rellena scripts/lidl_sync.py; los demás súpers lo dejan
-- vacío. Solo columnas nuevas: la lectura sigue con la misma RLS.
-- ============================================================================

alter table public.supermarket_products
  add column if not exists ean text,
  -- precio con la tarjeta del súper (Lidl Plus), si es distinto
  add column if not exists member_price numeric,
  -- desde cuándo vale price, si aún no ha empezado
  add column if not exists price_starts_at timestamptz;

-- Escanear un código de barras busca el producto en los catálogos.
create index if not exists supermarket_products_ean_idx
  on public.supermarket_products (ean)
  where ean is not null;
