-- Caducidades que el hogar corrige a mano, en días de vida por producto y
-- zona ("Nata para cocinar" en Despensa: 150). La app las propone la próxima
-- vez antes que su tabla. La clave es el nombre normalizado en el cliente
-- (ShelfLife.normalizedName). Idempotente.
create table if not exists public.product_shelf_life (
  home_id         uuid not null references public.homes (id) on delete cascade,
  name_normalized text not null,
  zone            text not null,
  days            integer not null check (days between 1 and 3650),
  updated_at      timestamptz not null default now(),
  primary key (home_id, name_normalized, zone)
);

alter table public.product_shelf_life enable row level security;

drop policy if exists psl_select on public.product_shelf_life;
create policy psl_select on public.product_shelf_life
  for select using (home_id = public.auth_home_id());
drop policy if exists psl_insert on public.product_shelf_life;
create policy psl_insert on public.product_shelf_life
  for insert with check (home_id = public.auth_home_id());
drop policy if exists psl_update on public.product_shelf_life;
create policy psl_update on public.product_shelf_life
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists psl_delete on public.product_shelf_life;
create policy psl_delete on public.product_shelf_life
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.product_shelf_life to authenticated;
