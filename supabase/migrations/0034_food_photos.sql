-- ============================================================================
-- PrezHome · Fotos reales de alimentos (despensa y lista de la compra)
-- ============================================================================
-- Hace la despensa (inventario) y la lista de la compra mucho mas visuales:
-- cada alimento puede mostrar una FOTO REAL buscada por su nombre (Unsplash via
-- la edge function recipe-photo, reutilizada) y, cuando no hay foto o no hay
-- clave de Unsplash, cae a una ilustracion cozy por categoria en la UI.
--
-- Esta migracion aporta la CAPA DE DATOS:
--   1. Columna image_url (text) en public.inventory_items: URL http(s) COMPLETA
--      de la foto del alimento. NULL = sin foto (la UI muestra la ilustracion
--      cozy). Es un dato OPERATIVO, no de control de acceso: NO toca RLS de esa
--      tabla, que ya existe desde 0001.
--   2. Columna image_url (text) en public.shopping_list_items: idem para la
--      lista de la compra. Tampoco toca su RLS (ya existe desde 0026).
--   3. Tabla public.food_photo_cache: cache COMPARTIDA POR HOGAR de la foto
--      resuelta para un nombre normalizado. Evita re-buscar en Unsplash el
--      mismo alimento (la cuota demo de Unsplash es ~50 busquedas/hora). Si una
--      fila tiene url NULL es que ya se busco y no habia foto (o no hay clave):
--      se respeta y no se re-busca. Como es una tabla NUEVA, SI declara su RLS
--      por hogar (home_id = public.auth_home_id()) y sus grants, copiando el
--      patron exacto de 0026_shopping_list.sql.
--
-- Idempotente: add column if not exists / create table if not exists / drop
-- policy if exists antes de create policy. Las filas existentes quedan con
-- image_url NULL, sin romper datos. Sigue el estilo de 0032 (comentarios en
-- espanol, guardas idempotentes).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Foto del alimento en el inventario (despensa/nevera/congelador).
-- ----------------------------------------------------------------------------
alter table public.inventory_items
  add column if not exists image_url text;

-- ----------------------------------------------------------------------------
-- 2. Foto del articulo en la lista de la compra.
-- ----------------------------------------------------------------------------
alter table public.shopping_list_items
  add column if not exists image_url text;

-- ----------------------------------------------------------------------------
-- 3. Cache de fotos por hogar y nombre normalizado.
-- ----------------------------------------------------------------------------
-- La clave es (home_id, name_normalized): el nombre normalizado lo calcula el
-- cliente con CategoryIcons.normalize (minusculas, sin acentos) para agrupar
-- "Platano"/"platano". url puede ser NULL (ya buscado, sin foto). fetched_at
-- marca cuando se resolvio por ultima vez.
create table if not exists public.food_photo_cache (
  home_id         uuid not null references public.homes (id) on delete cascade,
  name_normalized text not null,
  url             text,
  fetched_at      timestamptz not null default now(),
  primary key (home_id, name_normalized)
);

-- ----------------------------------------------------------------------------
-- RLS por hogar (patron de 0026_shopping_list.sql).
-- ----------------------------------------------------------------------------
alter table public.food_photo_cache enable row level security;

drop policy if exists fpc_select on public.food_photo_cache;
create policy fpc_select on public.food_photo_cache
  for select using (home_id = public.auth_home_id());
drop policy if exists fpc_insert on public.food_photo_cache;
create policy fpc_insert on public.food_photo_cache
  for insert with check (home_id = public.auth_home_id());
drop policy if exists fpc_update on public.food_photo_cache;
create policy fpc_update on public.food_photo_cache
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists fpc_delete on public.food_photo_cache;
create policy fpc_delete on public.food_photo_cache
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.food_photo_cache to authenticated;
