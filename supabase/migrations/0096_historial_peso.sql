-- Historial de peso: cada persona apunta su peso cuando quiere y ve cómo
-- cambia. Es privado: no lo ve el resto del hogar. Un apunte por día (si se
-- apunta otra vez el mismo día, se corrige). Idempotente.
create table if not exists public.weight_entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  measured_on date not null default current_date,
  weight_kg   numeric(5, 1) not null check (weight_kg between 20 and 400),
  created_at  timestamptz not null default now(),
  unique (user_id, measured_on)
);

create index if not exists weight_entries_user_idx
  on public.weight_entries (user_id, measured_on desc);

alter table public.weight_entries enable row level security;

drop policy if exists weight_select on public.weight_entries;
create policy weight_select on public.weight_entries
  for select using (user_id = (select auth.uid()));
drop policy if exists weight_insert on public.weight_entries;
create policy weight_insert on public.weight_entries
  for insert with check (user_id = (select auth.uid()));
drop policy if exists weight_update on public.weight_entries;
create policy weight_update on public.weight_entries
  for update using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
drop policy if exists weight_delete on public.weight_entries;
create policy weight_delete on public.weight_entries
  for delete using (user_id = (select auth.uid()));

grant select, insert, update, delete on public.weight_entries to authenticated;
