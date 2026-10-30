-- ============================================================================
-- PrezHome · Comidas que se repiten en el plan
-- ============================================================================
-- Una regla dice "esta receta, en esta comida, cada N días desde tal fecha"
-- (hasta una fecha o para siempre). La app la convierte en comidas del plan
-- hacia delante; filled_until recuerda hasta dónde, para que una comida que
-- se quita a mano no vuelva a aparecer. RLS por hogar. Idempotente.
-- ============================================================================

create table if not exists public.meal_plan_repeats (
  id           uuid primary key default gen_random_uuid(),
  home_id      uuid not null references public.homes (id) on delete cascade,
  recipe_id    uuid not null references public.recipes (id) on delete cascade,
  meal_type    text not null
                 check (meal_type in ('breakfast','lunch','dinner','snack','dessert')),
  start_date   date not null,
  every_days   int not null check (every_days between 1 and 60),
  end_date     date,
  filled_until date not null,
  created_at   timestamptz not null default now()
);
create index if not exists meal_plan_repeats_home_idx
  on public.meal_plan_repeats (home_id);
create index if not exists meal_plan_repeats_recipe_id_idx
  on public.meal_plan_repeats (recipe_id);

alter table public.meal_plan_entries
  add column if not exists repeat_id uuid
    references public.meal_plan_repeats (id) on delete set null;
create index if not exists meal_plan_entries_repeat_id_idx
  on public.meal_plan_entries (repeat_id);

alter table public.meal_plan_repeats enable row level security;

drop policy if exists mpr_select on public.meal_plan_repeats;
create policy mpr_select on public.meal_plan_repeats
  for select using (home_id = (select public.auth_home_id()));
drop policy if exists mpr_insert on public.meal_plan_repeats;
create policy mpr_insert on public.meal_plan_repeats
  for insert with check (home_id = (select public.auth_home_id()));
drop policy if exists mpr_update on public.meal_plan_repeats;
create policy mpr_update on public.meal_plan_repeats
  for update using (home_id = (select public.auth_home_id()))
  with check (home_id = (select public.auth_home_id()));
drop policy if exists mpr_delete on public.meal_plan_repeats;
create policy mpr_delete on public.meal_plan_repeats
  for delete using (home_id = (select public.auth_home_id()));
