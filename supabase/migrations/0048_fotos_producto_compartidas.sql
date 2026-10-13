-- ============================================================================
-- PrezHome · Fotos de producto compartidas entre hogares
-- ============================================================================
-- Idempotente. food_photo_cache es por hogar, así que cada casa buscaba en
-- Open Food Facts (límite ~10 búsquedas/minuto) los mismos productos. Esta
-- tabla guarda, por nombre normalizado, la foto de OFF que ya encontró
-- cualquier hogar, y la lista de la compra la reutiliza sin buscar.
--
-- Solo admite URLs de imágenes de Open Food Facts: las fotos que una persona
-- sube de su galería se quedan en la caché de su hogar y nunca se comparten.
-- Se puede leer e insertar, no modificar ni borrar (el primero que la
-- encuentra fija la foto; nadie puede cambiar la de otros).
--
-- NOTA DE CI: crea RLS y grants, así que el check de revisión manual fallará a
-- propósito hasta que se apruebe.
-- ============================================================================

create table if not exists public.product_photo_shared (
  name_normalized text primary key
    check (char_length(name_normalized) between 1 and 120),
  url             text not null
    check (url ~ '^https://images\.openfoodfacts\.(org|net)/'),
  created_at      timestamptz not null default now()
);

alter table public.product_photo_shared enable row level security;

drop policy if exists pps_select on public.product_photo_shared;
create policy pps_select on public.product_photo_shared
  for select to authenticated using (true);
drop policy if exists pps_insert on public.product_photo_shared;
create policy pps_insert on public.product_photo_shared
  for insert to authenticated with check (true);

grant select, insert on public.product_photo_shared to authenticated;
