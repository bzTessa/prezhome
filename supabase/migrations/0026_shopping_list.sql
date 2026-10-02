-- ============================================================================
-- PrezHome · Lista de la compra del hogar
-- ============================================================================
-- Cada fila es un articulo de la lista de la compra. Es del HOGAR (compartido),
-- de modo que cualquier miembro ve y edita la misma lista. "checked" marca que
-- el articulo ya se ha comprado. "source" indica si se anadio a mano ('manual')
-- o lo genero el planificador a partir del plan semanal de comidas ('auto').
-- RLS por hogar. Idempotente.
-- ============================================================================

create table if not exists public.shopping_list_items (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  name       text not null,
  quantity   numeric,
  unit       text,
  checked    boolean not null default false,
  source     text not null default 'manual'
               check (source in ('manual','auto')),
  created_at timestamptz not null default now()
);
create index if not exists shopping_list_home_idx
  on public.shopping_list_items (home_id, checked);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.shopping_list_items enable row level security;

drop policy if exists sli_select on public.shopping_list_items;
create policy sli_select on public.shopping_list_items
  for select using (home_id = public.auth_home_id());
drop policy if exists sli_insert on public.shopping_list_items;
create policy sli_insert on public.shopping_list_items
  for insert with check (home_id = public.auth_home_id());
drop policy if exists sli_update on public.shopping_list_items;
create policy sli_update on public.shopping_list_items
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());
drop policy if exists sli_delete on public.shopping_list_items;
create policy sli_delete on public.shopping_list_items
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.shopping_list_items to authenticated;
