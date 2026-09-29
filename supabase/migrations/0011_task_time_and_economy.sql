-- ============================================================================
-- PrezHome · Hora en tareas + Economía (Capa 1: gastos y presupuesto)
-- ============================================================================
-- Idempotente. RLS por hogar en las tablas de economía.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Hora concreta opcional en las tareas (además de la fecha)
-- ----------------------------------------------------------------------------
alter table public.tasks
  add column if not exists due_time time;

-- ============================================================================
-- 2. ECONOMÍA
-- ============================================================================

-- Presupuesto mensual del hogar (una fila por hogar)
create table if not exists public.budgets (
  home_id        uuid primary key references public.homes (id) on delete cascade,
  monthly_amount numeric not null default 0,
  updated_at     timestamptz not null default now()
);

-- Gastos del hogar
create table if not exists public.expenses (
  id           uuid primary key default gen_random_uuid(),
  home_id      uuid not null references public.homes (id) on delete cascade,
  amount       numeric not null,
  category     text not null default 'Supermercado'
                 check (category in ('Supermercado', 'Hogar', 'Ocio', 'Otros')),
  store        text,
  note         text,
  spent_on     date not null default (now()::date),
  ticket_path  text,   -- ruta en el bucket de tickets si vino de un escaneo
  created_by   uuid references auth.users (id) on delete set null,
  created_at   timestamptz not null default now()
);
create index if not exists expenses_home_id_idx on public.expenses (home_id);
create index if not exists expenses_spent_on_idx on public.expenses (spent_on);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.budgets enable row level security;
alter table public.expenses enable row level security;

drop policy if exists budgets_select on public.budgets;
create policy budgets_select on public.budgets
  for select using (home_id = public.auth_home_id());

drop policy if exists budgets_upsert on public.budgets;
create policy budgets_upsert on public.budgets
  for insert with check (home_id = public.auth_home_id());

drop policy if exists budgets_update on public.budgets;
create policy budgets_update on public.budgets
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists expenses_select on public.expenses;
create policy expenses_select on public.expenses
  for select using (home_id = public.auth_home_id());

drop policy if exists expenses_insert on public.expenses;
create policy expenses_insert on public.expenses
  for insert with check (home_id = public.auth_home_id());

drop policy if exists expenses_update on public.expenses;
create policy expenses_update on public.expenses
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists expenses_delete on public.expenses;
create policy expenses_delete on public.expenses
  for delete using (home_id = public.auth_home_id());

-- ----------------------------------------------------------------------------
-- GRANTs
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on public.budgets to authenticated;
grant select, insert, update, delete on public.expenses to authenticated;
