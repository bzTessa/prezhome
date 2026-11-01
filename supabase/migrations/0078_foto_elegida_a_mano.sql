-- La foto que la persona elige a mano para un producto se queda para siempre
-- en su hogar (compra y despensa): la búsqueda automática no la cambia.
alter table public.food_photo_cache
  add column if not exists manual boolean not null default false;

-- Búsqueda por trozos del nombre (ilike '%leche%') rápida aunque el catálogo
-- crezca con más países.
create extension if not exists pg_trgm with schema extensions;
create index if not exists supermarket_products_name_trgm
  on public.supermarket_products
  using gin (name_normalized extensions.gin_trgm_ops);
