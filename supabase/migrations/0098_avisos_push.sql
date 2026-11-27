-- Avisos push entre la gente de casa (Firebase Cloud Messaging).
-- Cada móvil guarda aquí su token al entrar; la función notify-home los lee
-- con la service role para avisar a los demás del hogar. Cada persona solo
-- ve y toca sus propios tokens. Idempotente.
create table if not exists public.push_tokens (
  token      text primary key check (char_length(token) between 10 and 4096),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  platform   text not null default 'android' check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);

create index if not exists push_tokens_user_idx on public.push_tokens (user_id);

alter table public.push_tokens enable row level security;

drop policy if exists push_tokens_select on public.push_tokens;
create policy push_tokens_select on public.push_tokens
  for select using (user_id = (select auth.uid()));
drop policy if exists push_tokens_insert on public.push_tokens;
create policy push_tokens_insert on public.push_tokens
  for insert with check (user_id = (select auth.uid()));
drop policy if exists push_tokens_update on public.push_tokens;
create policy push_tokens_update on public.push_tokens
  for update using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
drop policy if exists push_tokens_delete on public.push_tokens;
create policy push_tokens_delete on public.push_tokens
  for delete using (user_id = (select auth.uid()));

grant select, insert, update, delete on public.push_tokens to authenticated;
