-- ============================================================================
-- PrezWallet · Recibos (PrezWallet/docs/PREZWALLET.md §3.7)
-- ============================================================================
-- Idempotente. Facturas que se repiten (luz, alquiler, suscripciones): importe,
-- cada cuántos meses y la próxima fecha de cargo. Al marcar uno como pagado, la
-- app crea el movimiento y avanza next_date. Como el resto de wallet_*, es del
-- usuario y, con home_id, lo ve y lo gestiona también su hogar.
-- ============================================================================

create table if not exists public.wallet_bills (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  home_id      uuid references public.homes (id) on delete cascade,
  name         text not null check (length(trim(name)) > 0),
  amount       numeric not null check (amount > 0),
  category_id  uuid references public.wallet_categories (id) on delete set null,
  account_id   uuid references public.wallet_accounts (id) on delete set null,
  every_months int not null default 1 check (every_months between 1 and 12),
  next_date    date not null,
  created_at   timestamptz not null default now()
);
create index if not exists wallet_bills_owner_date_idx
  on public.wallet_bills (owner_id, next_date);
create index if not exists wallet_bills_home_idx on public.wallet_bills (home_id);

alter table public.wallet_bills enable row level security;

drop policy if exists wallet_bills_select on public.wallet_bills;
create policy wallet_bills_select on public.wallet_bills
  for select using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

-- Cuenta y categoría, si las hay, tienen que ser visibles para el usuario.
drop policy if exists wallet_bills_insert on public.wallet_bills;
create policy wallet_bills_insert on public.wallet_bills
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
    and (account_id is null or exists (
      select 1 from public.wallet_accounts a
      where a.id = account_id
        and (a.owner_id = auth.uid()
             or (a.home_id is not null and a.home_id = public.auth_home_id()))
    ))
    and (category_id is null or exists (
      select 1 from public.wallet_categories c
      where c.id = category_id
        and (c.owner_id is null
             or c.owner_id = auth.uid()
             or (c.home_id is not null and c.home_id = public.auth_home_id()))
    ))
  );

drop policy if exists wallet_bills_update on public.wallet_bills;
create policy wallet_bills_update on public.wallet_bills
  for update using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  )
  with check (
    ((home_id is null and owner_id = auth.uid())
     or (home_id is not null and home_id = public.auth_home_id()))
    and (account_id is null or exists (
      select 1 from public.wallet_accounts a
      where a.id = account_id
        and (a.owner_id = auth.uid()
             or (a.home_id is not null and a.home_id = public.auth_home_id()))
    ))
    and (category_id is null or exists (
      select 1 from public.wallet_categories c
      where c.id = category_id
        and (c.owner_id is null
             or c.owner_id = auth.uid()
             or (c.home_id is not null and c.home_id = public.auth_home_id()))
    ))
  );

drop policy if exists wallet_bills_delete on public.wallet_bills;
create policy wallet_bills_delete on public.wallet_bills
  for delete using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

grant select, insert, update, delete on public.wallet_bills to authenticated;
