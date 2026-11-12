-- Cómo cuenta cada hogar un producto en la compra: 'pack' (envases del súper),
-- 'piece' (piezas sueltas) o 'weight' (g / kg, ml / L). Se guarda cuando la
-- persona lo elige en una fila y la app lo respeta desde entonces (lista del
-- plan, envases del catálogo). La clave es el nombre normalizado en el cliente
-- (CategoryIcons.normalize). Idempotente.
create table if not exists public.product_count_prefs (
  home_id         uuid not null references public.homes (id) on delete cascade,
  name_normalized text not null,
  mode            text not null check (mode in ('pack', 'piece', 'weight')),
  updated_at      timestamptz not null default now(),
  primary key (home_id, name_normalized)
);

alter table public.product_count_prefs enable row level security;

drop policy if exists pcp_select on public.product_count_prefs;
create policy pcp_select on public.product_count_prefs
  for select using (home_id = public.auth_home_id());
drop policy if exists pcp_insert on public.product_count_prefs;
create policy pcp_insert on public.product_count_prefs
  for insert with check (home_id = public.auth_home_id());
drop policy if exists pcp_update on public.product_count_prefs;
create policy pcp_update on public.product_count_prefs
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists pcp_delete on public.product_count_prefs;
create policy pcp_delete on public.product_count_prefs
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.product_count_prefs to authenticated;
