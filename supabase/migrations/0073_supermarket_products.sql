-- ============================================================================
-- PrezHome · Catálogo de productos de supermercado (foto oficial y precio)
-- ============================================================================
-- Productos tal cual los publica la tienda online de cada cadena (de momento
-- Mercadona): nombre, formato, precio, precio por kg/l/ud y la URL de la foto
-- oficial (no se copia la imagen). Lo rellena cada semana
-- scripts/mercadona_sync.py con la service role; las apps solo leen.
-- Los precios son orientativos: la app lo indica.
-- ============================================================================

create table if not exists public.supermarket_products (
  store text not null,
  product_id text not null,
  name text not null,
  -- minúsculas y sin acentos, para buscar con ilike
  name_normalized text not null,
  size text,
  price numeric,
  unit_price numeric,
  unit text,
  image_url text,
  category text,
  updated_at timestamptz not null default now(),
  primary key (store, product_id)
);

alter table public.supermarket_products enable row level security;

drop policy if exists "Catálogo visible para usuarios" on public.supermarket_products;
create policy "Catálogo visible para usuarios"
  on public.supermarket_products for select
  to authenticated
  using (true);
