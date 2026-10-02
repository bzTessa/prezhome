-- ============================================================================
-- PrezHome · Diario de consumo personal (contador de calorías v1)
-- ============================================================================
-- Cada fila es algo que una PERSONA se ha comido un día concreto. A diferencia
-- del resto de la app (que es por hogar), el diario es PERSONAL: lo que come
-- cada usuario. Por eso el aislamiento es por user_id = auth.uid(), igual que
-- la tabla profiles de 0001, y NO por hogar (nada de auth_home_id()).
--
-- Las columnas source (con el valor 'foto' reservado) y recipe_id son ganchos
-- para piezas futuras (registro por foto con IA y onboarding); aquí solo se usan
-- 'manual' y 'receta'. RLS por usuario. Idempotente.
-- ============================================================================

create table if not exists public.food_log_entries (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  log_date   date not null,
  -- Tipo de comida opcional: sirve para agrupar en la UI, puede ser null.
  meal_type  text
               check (meal_type in ('breakfast','lunch','dinner','snack','dessert')),
  name       text not null,
  calories   numeric,
  protein    numeric,
  carbs      numeric,
  fat        numeric,
  -- 'manual' (a mano), 'receta' (desde una receta propia). 'foto' queda
  -- reservado para la pieza 2 (registro por foto), aún no usado en la UI.
  source     text not null default 'manual'
               check (source in ('manual','receta','foto')),
  recipe_id  uuid references public.recipes (id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists food_log_user_date_idx
  on public.food_log_entries (user_id, log_date);

-- ----------------------------------------------------------------------------
-- RLS por usuario (como profiles): cada quien ve y gestiona solo lo suyo.
-- ----------------------------------------------------------------------------
alter table public.food_log_entries enable row level security;

drop policy if exists food_log_select on public.food_log_entries;
create policy food_log_select on public.food_log_entries
  for select using (user_id = auth.uid());
drop policy if exists food_log_insert on public.food_log_entries;
create policy food_log_insert on public.food_log_entries
  for insert with check (user_id = auth.uid());
drop policy if exists food_log_update on public.food_log_entries;
create policy food_log_update on public.food_log_entries
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());
drop policy if exists food_log_delete on public.food_log_entries;
create policy food_log_delete on public.food_log_entries
  for delete using (user_id = auth.uid());

grant select, insert, update, delete on public.food_log_entries to authenticated;
