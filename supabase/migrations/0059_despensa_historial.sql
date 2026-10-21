-- Despensa al día.
--
-- (a) pantry_log: lo que sale de la despensa y qué día (consumido a mano o
--     gastado al cocinar una receta del plan). Solo lo ve y edita el hogar.
-- (b) meal_plan_entries.pantry_used_at: cuándo se descontaron de la despensa
--     los ingredientes de esa comida. Se reclama con un update condicional,
--     así dos móviles del mismo hogar no lo descuentan dos veces.

-- (a) ------------------------------------------------------------------------
create table if not exists public.pantry_log (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  name       text not null check (char_length(btrim(name)) between 1 and 200),
  quantity   numeric,
  unit       text,
  reason     text not null default 'consumido'
             check (reason in ('consumido', 'receta')),
  recipe_id  uuid references public.recipes (id) on delete set null,
  used_on    date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists pantry_log_home_used_idx
  on public.pantry_log (home_id, used_on desc);

alter table public.pantry_log enable row level security;

drop policy if exists pantry_log_select on public.pantry_log;
create policy pantry_log_select on public.pantry_log
  for select using (home_id = public.auth_home_id());

drop policy if exists pantry_log_insert on public.pantry_log;
create policy pantry_log_insert on public.pantry_log
  for insert with check (home_id = public.auth_home_id());

drop policy if exists pantry_log_delete on public.pantry_log;
create policy pantry_log_delete on public.pantry_log
  for delete using (home_id = public.auth_home_id());

grant select, insert, delete on public.pantry_log to authenticated;

-- (b) ------------------------------------------------------------------------
alter table public.meal_plan_entries
  add column if not exists pantry_used_at timestamptz;

-- Lo de días anteriores ya no se descuenta: la despensa se llevaba a mano.
update public.meal_plan_entries
   set pantry_used_at = now()
 where pantry_used_at is null
   and plan_date < current_date;
