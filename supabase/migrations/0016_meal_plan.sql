-- ============================================================================
-- PrezHome · Plan semanal de comidas (planificador v1)
-- ============================================================================
-- Cada fila es una comida planificada: un día, un tipo de comida y la receta
-- asignada. Es del HOGAR (compartido). "skipped" marca que ese día no se hace
-- en casa (ej. se come fuera), para el reajuste dinámico.
--
-- Además, meal_plan_feedback guarda las decisiones del usuario (aceptar/rechazar
-- una receta en el plan) para que el planificador APRENDA con el tiempo.
-- RLS por hogar. Idempotente.
-- ============================================================================

create table if not exists public.meal_plan_entries (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  plan_date  date not null,
  meal_type  text not null
               check (meal_type in ('breakfast','lunch','dinner','snack','dessert')),
  recipe_id  uuid references public.recipes (id) on delete set null,
  skipped    boolean not null default false, -- true = ese día se come fuera
  created_at timestamptz not null default now(),
  unique (home_id, plan_date, meal_type)
);
create index if not exists meal_plan_home_date_idx
  on public.meal_plan_entries (home_id, plan_date);

-- Historial de decisiones para el aprendizaje (peso de cada receta).
create table if not exists public.meal_plan_feedback (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  recipe_id  uuid not null references public.recipes (id) on delete cascade,
  -- 'accepted' (se dejó en el plan / se cocinó), 'rejected' (se quitó/cambió)
  action     text not null check (action in ('accepted','rejected')),
  created_at timestamptz not null default now()
);
create index if not exists meal_plan_feedback_home_idx
  on public.meal_plan_feedback (home_id, recipe_id);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.meal_plan_entries enable row level security;
alter table public.meal_plan_feedback enable row level security;

drop policy if exists mpe_select on public.meal_plan_entries;
create policy mpe_select on public.meal_plan_entries
  for select using (home_id = public.auth_home_id());
drop policy if exists mpe_insert on public.meal_plan_entries;
create policy mpe_insert on public.meal_plan_entries
  for insert with check (home_id = public.auth_home_id());
drop policy if exists mpe_update on public.meal_plan_entries;
create policy mpe_update on public.meal_plan_entries
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists mpe_delete on public.meal_plan_entries;
create policy mpe_delete on public.meal_plan_entries
  for delete using (home_id = public.auth_home_id());

drop policy if exists mpf_select on public.meal_plan_feedback;
create policy mpf_select on public.meal_plan_feedback
  for select using (home_id = public.auth_home_id());
drop policy if exists mpf_insert on public.meal_plan_feedback;
create policy mpf_insert on public.meal_plan_feedback
  for insert with check (home_id = public.auth_home_id());

grant select, insert, update, delete on public.meal_plan_entries to authenticated;
grant select, insert, update, delete on public.meal_plan_feedback to authenticated;
