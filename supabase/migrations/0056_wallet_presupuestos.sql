-- ============================================================================
-- PrezWallet · Presupuestos mensuales (PrezWallet/docs/PREZWALLET.md §3.1, §5)
-- ============================================================================
-- Idempotente. Un importe al mes, el mismo todos los meses: category_id nulo
-- es el presupuesto total; con categoría, el de esa categoría. Como el resto
-- de wallet_*, es del usuario y, si lleva home_id, lo ve también su hogar.
-- ============================================================================

create table if not exists public.wallet_budgets (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  home_id     uuid references public.homes (id) on delete cascade,
  category_id uuid references public.wallet_categories (id) on delete cascade,
  amount      numeric not null check (amount > 0),
  created_at  timestamptz not null default now(),
  -- Un solo presupuesto total y uno por categoría para cada usuario.
  unique nulls not distinct (owner_id, category_id)
);
create index if not exists wallet_budgets_home_idx on public.wallet_budgets (home_id);
create index if not exists wallet_budgets_category_idx on public.wallet_budgets (category_id);

alter table public.wallet_budgets enable row level security;

drop policy if exists wallet_budgets_select on public.wallet_budgets;
create policy wallet_budgets_select on public.wallet_budgets
  for select using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

-- La categoría, si la hay, tiene que ser una que el usuario pueda ver.
drop policy if exists wallet_budgets_insert on public.wallet_budgets;
create policy wallet_budgets_insert on public.wallet_budgets
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
    and (category_id is null or exists (
      select 1 from public.wallet_categories c
      where c.id = category_id
        and (c.owner_id is null
             or c.owner_id = auth.uid()
             or (c.home_id is not null and c.home_id = public.auth_home_id()))
    ))
  );

drop policy if exists wallet_budgets_update on public.wallet_budgets;
create policy wallet_budgets_update on public.wallet_budgets
  for update using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
    and (category_id is null or exists (
      select 1 from public.wallet_categories c
      where c.id = category_id
        and (c.owner_id is null
             or c.owner_id = auth.uid()
             or (c.home_id is not null and c.home_id = public.auth_home_id()))
    ))
  );

drop policy if exists wallet_budgets_delete on public.wallet_budgets;
create policy wallet_budgets_delete on public.wallet_budgets
  for delete using (owner_id = auth.uid());

grant select, insert, update, delete on public.wallet_budgets to authenticated;
