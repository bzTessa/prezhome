-- Bandeja de apuntes: lo que la persona apunta rápido desde el "+" sin decidir
-- todavía qué es ("llamar al fontanero", "mirar ofertas de aceite"). Luego lo
-- pasa a la compra, a tareas o pide un aviso (remind_at). Cada apunte es de
-- quien lo escribe: no lo ve el resto del hogar. Idempotente.
create table if not exists public.inbox_notes (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  text       text not null check (char_length(text) between 1 and 500),
  remind_at  timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists inbox_notes_user_idx
  on public.inbox_notes (user_id, created_at desc);

alter table public.inbox_notes enable row level security;

drop policy if exists inbox_select on public.inbox_notes;
create policy inbox_select on public.inbox_notes
  for select using (user_id = (select auth.uid()));
drop policy if exists inbox_insert on public.inbox_notes;
create policy inbox_insert on public.inbox_notes
  for insert with check (
    user_id = (select auth.uid()) and home_id = public.auth_home_id()
  );
drop policy if exists inbox_update on public.inbox_notes;
create policy inbox_update on public.inbox_notes
  for update using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
drop policy if exists inbox_delete on public.inbox_notes;
create policy inbox_delete on public.inbox_notes
  for delete using (user_id = (select auth.uid()));

grant select, insert, update, delete on public.inbox_notes to authenticated;
