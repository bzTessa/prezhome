-- ============================================================================
-- PrezHome · Varias listas de la compra y categorías personalizadas
-- ============================================================================
-- Hasta ahora había UNA sola lista de la compra por hogar (shopping_list_items
-- desde 0026). Esta migración permite:
--   1. VARIAS listas por hogar (p. ej. una por súper): tabla shopping_lists.
--   2. CATEGORÍAS personalizadas por hogar (secciones de la lista), con orden,
--      color e icono: tabla shopping_categories.
--   3. Enlazar cada artículo de la compra a una lista y a una categoría
--      concretas mediante columnas NULLABLE en shopping_list_items (list_id,
--      category_id). Se mantienen NULLABLE a propósito para COMPATIBILIDAD:
--      los artículos existentes (y los que no se asignen) se tratan como de la
--      "Lista principal" (list_id NULL) y "Sin categorizar" (category_id NULL),
--      conservando además la columna de texto libre `category` de 0038.
--
-- Ambas tablas son NUEVAS, así que SÍ declaran su RLS por hogar
-- (home_id = public.auth_home_id()) con el bloque de 4 políticas + grants,
-- copiando el patrón EXACTO de 0026_shopping_list.sql.
--
-- SEED de categorías por defecto y "Lista principal": se DELEGA EN LA APP, no
-- en un trigger. Motivo: el seed necesita el home_id del hogar y se hace de
-- forma idempotente al abrir la pantalla de la compra (ver
-- lib/utils/shopping_categories.dart + lib/shopping_list_screen.dart). Además,
-- list_id NULL se trata siempre como "Lista principal" y category_id NULL como
-- "Sin categorizar", de modo que la app funciona aunque el seed todavía no se
-- haya ejecutado. Las categorías por defecto (en español) son: Frutas y
-- Verduras, Carnes y Pescados, Lácteos, Panadería, Congelados, Conservas,
-- Pastas y Cereales, Bebidas, Limpieza y Hogar, Condimentos y Sin categorizar.
--
-- Idempotente: create table if not exists / add column if not exists /
-- drop policy if exists antes de create policy. Las filas existentes de
-- shopping_list_items quedan con list_id/category_id NULL, sin romper datos.
--
-- NOTA DE CI: esta migración CREA políticas RLS, así que los checks
-- 'Validación de cambios IA'/'Revisión manual requerida' fallarán A PROPÓSITO
-- (NO bloqueante; el PR sigue siendo mergeable), igual que 0026/0034.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Listas de la compra del hogar (varias; p. ej. una por súper).
-- ----------------------------------------------------------------------------
create table if not exists public.shopping_lists (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  name       text not null,
  color      text,
  icon       text,
  created_at timestamptz not null default now()
);
create index if not exists shopping_lists_home_idx
  on public.shopping_lists (home_id);

-- ----------------------------------------------------------------------------
-- 2. Categorías/secciones personalizadas del hogar (con orden).
-- ----------------------------------------------------------------------------
create table if not exists public.shopping_categories (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  name       text not null,
  position   int,
  color      text,
  icon       text,
  created_at timestamptz not null default now()
);
create index if not exists shopping_categories_home_idx
  on public.shopping_categories (home_id, position);

-- ----------------------------------------------------------------------------
-- 3. Enlaces NULLABLE en los artículos de la compra (compatibilidad).
--    list_id NULL   = "Lista principal" (la app lo trata así).
--    category_id NULL = "Sin categorizar" (se mantiene además `category` texto).
--    on delete set null: borrar una lista/categoría NO borra sus artículos;
--    quedan en la principal / sin categorizar.
-- ----------------------------------------------------------------------------
alter table public.shopping_list_items
  add column if not exists list_id uuid
    references public.shopping_lists (id) on delete set null;

alter table public.shopping_list_items
  add column if not exists category_id uuid
    references public.shopping_categories (id) on delete set null;

create index if not exists shopping_list_items_list_idx
  on public.shopping_list_items (home_id, list_id);

-- ----------------------------------------------------------------------------
-- RLS por hogar de shopping_lists (patrón de 0026_shopping_list.sql).
-- ----------------------------------------------------------------------------
alter table public.shopping_lists enable row level security;

drop policy if exists shl_select on public.shopping_lists;
create policy shl_select on public.shopping_lists
  for select using (home_id = public.auth_home_id());
drop policy if exists shl_insert on public.shopping_lists;
create policy shl_insert on public.shopping_lists
  for insert with check (home_id = public.auth_home_id());
drop policy if exists shl_update on public.shopping_lists;
create policy shl_update on public.shopping_lists
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists shl_delete on public.shopping_lists;
create policy shl_delete on public.shopping_lists
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.shopping_lists to authenticated;

-- ----------------------------------------------------------------------------
-- RLS por hogar de shopping_categories (mismo patrón).
-- ----------------------------------------------------------------------------
alter table public.shopping_categories enable row level security;

drop policy if exists shc_select on public.shopping_categories;
create policy shc_select on public.shopping_categories
  for select using (home_id = public.auth_home_id());
drop policy if exists shc_insert on public.shopping_categories;
create policy shc_insert on public.shopping_categories
  for insert with check (home_id = public.auth_home_id());
drop policy if exists shc_update on public.shopping_categories;
create policy shc_update on public.shopping_categories
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists shc_delete on public.shopping_categories;
create policy shc_delete on public.shopping_categories
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.shopping_categories to authenticated;
