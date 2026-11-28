-- Ficha de la casa: lo que toda la gente de casa necesita a mano. Wifi,
-- contactos (casero, fontanero, seguro, comunidad), electrodomésticos con su
-- garantía y notas sueltas. Lo ve y lo toca todo el hogar. Idempotente.
create table if not exists public.home_info (
  id          uuid primary key default gen_random_uuid(),
  home_id     uuid not null references public.homes (id) on delete cascade,
  kind        text not null check (kind in ('wifi', 'contact', 'appliance', 'note')),
  title       text not null check (char_length(title) between 1 and 120),
  detail      text check (detail is null or char_length(detail) <= 500),
  phone       text check (phone is null or char_length(phone) <= 40),
  valid_until date,
  created_by  uuid default auth.uid() references auth.users (id) on delete set null,
  created_at  timestamptz not null default now()
);

create index if not exists home_info_home_idx
  on public.home_info (home_id, kind, created_at);

alter table public.home_info enable row level security;

drop policy if exists home_info_select on public.home_info;
create policy home_info_select on public.home_info
  for select using (home_id = public.auth_home_id());
drop policy if exists home_info_insert on public.home_info;
create policy home_info_insert on public.home_info
  for insert with check (home_id = public.auth_home_id());
drop policy if exists home_info_update on public.home_info;
create policy home_info_update on public.home_info
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists home_info_delete on public.home_info;
create policy home_info_delete on public.home_info
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.home_info to authenticated;
