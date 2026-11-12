-- ============================================================================
-- PrezHome · Preparados del súper ("Comprado hecho")
-- ============================================================================
-- Platos o postres que el hogar compra ya hechos (natillas, tortilla...).
-- Se eligen del catálogo del súper y quedan como "preparados de confianza"
-- para reutilizarlos; con "Cocinar poco" el plan tira de ellos. Una comida
-- del plan puede ser una receta (recipe_id) o un preparado (ready_meal_id).
-- "trusted = false" lo quita de la lista sin borrar lo ya planificado.
-- RLS por hogar. Idempotente.
-- ============================================================================

create table if not exists public.ready_meals (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  name       text not null,
  image_url  text,
  calories   numeric, -- kcal por ración, si se saben
  kind       text not null default 'main' check (kind in ('main','dessert')),
  trusted    boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists ready_meals_home_idx on public.ready_meals (home_id);

alter table public.meal_plan_entries
  add column if not exists ready_meal_id uuid
    references public.ready_meals (id) on delete set null;
create index if not exists meal_plan_entries_ready_meal_id_idx
  on public.meal_plan_entries (ready_meal_id);

alter table public.ready_meals enable row level security;

drop policy if exists rm_select on public.ready_meals;
create policy rm_select on public.ready_meals
  for select using (home_id = (select public.auth_home_id()));
drop policy if exists rm_insert on public.ready_meals;
create policy rm_insert on public.ready_meals
  for insert with check (home_id = (select public.auth_home_id()));
drop policy if exists rm_update on public.ready_meals;
create policy rm_update on public.ready_meals
  for update using (home_id = (select public.auth_home_id()))
  with check (home_id = (select public.auth_home_id()));
drop policy if exists rm_delete on public.ready_meals;
create policy rm_delete on public.ready_meals
  for delete using (home_id = (select public.auth_home_id()));

-- Sin GRANT el RLS ni se evalúa (ver 0076).
grant select, insert, update, delete on public.ready_meals to authenticated;
