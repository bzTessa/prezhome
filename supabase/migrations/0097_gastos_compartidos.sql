-- Gastos compartidos del hogar (compañeros de piso, pareja...): quién pagó
-- qué. La app reparte a partes iguales entre las personas de casa, dice quién
-- debe a quién y "Saldar cuentas" marca lo pendiente como saldado.
-- paid_by es el id de un perfil o de una persona sin cuenta (home_people).
-- Lo ve y lo toca todo el hogar. Idempotente.
create table if not exists public.home_expenses (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  paid_by    uuid not null,
  amount     numeric(10, 2) not null check (amount > 0 and amount < 100000),
  concept    text not null check (char_length(concept) between 1 and 120),
  spent_on   date not null default current_date,
  settled    boolean not null default false,
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists home_expenses_home_idx
  on public.home_expenses (home_id, settled, spent_on desc);

alter table public.home_expenses enable row level security;

drop policy if exists home_expenses_select on public.home_expenses;
create policy home_expenses_select on public.home_expenses
  for select using (home_id = public.auth_home_id());
drop policy if exists home_expenses_insert on public.home_expenses;
create policy home_expenses_insert on public.home_expenses
  for insert with check (home_id = public.auth_home_id());
drop policy if exists home_expenses_update on public.home_expenses;
create policy home_expenses_update on public.home_expenses
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists home_expenses_delete on public.home_expenses;
create policy home_expenses_delete on public.home_expenses
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.home_expenses to authenticated;
