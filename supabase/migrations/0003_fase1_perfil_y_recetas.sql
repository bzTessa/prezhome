-- ============================================================================
-- PrezHome · FASE 1 — Perfil nutricional + campos de recetas + ingredientes
-- ============================================================================
-- Idempotente: usa "if not exists" / "add column if not exists" para poder
-- re-ejecutarse sin romper. RLS y GRANTs incluidos.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Ampliar profiles con datos del perfil nutricional (DATOS PERSONALES)
-- ----------------------------------------------------------------------------
-- Por defecto el perfil físico es PRIVADO (is_public = false). La pareja solo
-- podrá verlo si el dueño lo marca como público.
alter table public.profiles add column if not exists sex text
  check (sex in ('male', 'female'));
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists height_cm numeric;
alter table public.profiles add column if not exists weight_kg numeric;
alter table public.profiles add column if not exists activity_level text
  default 'moderate'
  check (activity_level in ('sedentary','light','moderate','active','very_active'));
alter table public.profiles add column if not exists goal text
  default 'maintain'
  check (goal in ('maintain','lose','gain'));
alter table public.profiles add column if not exists meals_per_day integer default 4;
alter table public.profiles add column if not exists is_public boolean not null default false;

-- ----------------------------------------------------------------------------
-- 2. Ampliar recipes con tiempos, aparato de cocina, tipo de comida, favorita
-- ----------------------------------------------------------------------------
alter table public.recipes add column if not exists prep_minutes integer;
alter table public.recipes add column if not exists cook_minutes integer;
alter table public.recipes add column if not exists appliance text
  default 'none'
  check (appliance in ('none','oven','stovetop','pot','airfryer','microwave'));
alter table public.recipes add column if not exists meal_type text
  default 'lunch'
  check (meal_type in ('breakfast','lunch','dinner','snack'));
alter table public.recipes add column if not exists is_favorite boolean not null default false;
alter table public.recipes add column if not exists freezable boolean not null default false;

-- ----------------------------------------------------------------------------
-- 3. Tabla de ingredientes de receta (con cantidades, para lista de compra)
-- ----------------------------------------------------------------------------
create table if not exists public.recipe_ingredients (
  id        uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  home_id   uuid not null references public.homes (id) on delete cascade,
  name      text not null,
  quantity  numeric,
  unit      text,
  position  integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists recipe_ingredients_recipe_id_idx
  on public.recipe_ingredients (recipe_id);
create index if not exists recipe_ingredients_home_id_idx
  on public.recipe_ingredients (home_id);

-- ----------------------------------------------------------------------------
-- 4. RLS de recipe_ingredients (por hogar, como el resto)
-- ----------------------------------------------------------------------------
alter table public.recipe_ingredients enable row level security;

drop policy if exists recipe_ingredients_select on public.recipe_ingredients;
create policy recipe_ingredients_select on public.recipe_ingredients
  for select using (home_id = public.auth_home_id());

drop policy if exists recipe_ingredients_insert on public.recipe_ingredients;
create policy recipe_ingredients_insert on public.recipe_ingredients
  for insert with check (home_id = public.auth_home_id());

drop policy if exists recipe_ingredients_update on public.recipe_ingredients;
create policy recipe_ingredients_update on public.recipe_ingredients
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists recipe_ingredients_delete on public.recipe_ingredients;
create policy recipe_ingredients_delete on public.recipe_ingredients
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.recipe_ingredients to authenticated;

-- ----------------------------------------------------------------------------
-- 5. Política de profiles: ver también el perfil de la pareja SI es público
-- ----------------------------------------------------------------------------
-- Reemplaza profiles_select para permitir ver perfiles del mismo hogar cuando
-- is_public = true (además del propio, siempre visible).
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (
    id = auth.uid()
    or (
      home_id is not null
      and home_id = public.auth_home_id()
      and is_public = true
    )
  );

-- Nota: profiles_update ya existe (solo el propio usuario edita su perfil).
-- ============================================================================
-- FIN Fase 1
-- ============================================================================
