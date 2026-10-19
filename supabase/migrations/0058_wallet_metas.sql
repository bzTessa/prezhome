-- ============================================================================
-- PrezWallet · Metas de ahorro (PrezWallet/docs/PREZWALLET.md §3.9)
-- ============================================================================
-- Idempotente. Una meta es un objetivo (piso, coche, colchón) con lo ya
-- apartado, el ahorro al mes, la rentabilidad esperada y, si se quiere, una
-- fecha. La app calcula cuándo se llega o cuánto falta al mes. Como el resto
-- de wallet_*, es del usuario y, con home_id, la ve y edita también su hogar.
-- ============================================================================

create table if not exists public.wallet_goals (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  home_id         uuid references public.homes (id) on delete cascade,
  name            text not null check (length(trim(name)) > 0),
  target_amount   numeric not null check (target_amount > 0),
  saved_amount    numeric not null default 0 check (saved_amount >= 0),
  monthly_saving  numeric not null default 0 check (monthly_saving >= 0),
  expected_return numeric not null default 0
                    check (expected_return between -50 and 50),
  target_date     date,
  created_at      timestamptz not null default now()
);
create index if not exists wallet_goals_owner_idx on public.wallet_goals (owner_id);
create index if not exists wallet_goals_home_idx on public.wallet_goals (home_id);

alter table public.wallet_goals enable row level security;

drop policy if exists wallet_goals_select on public.wallet_goals;
create policy wallet_goals_select on public.wallet_goals
  for select using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_goals_insert on public.wallet_goals;
create policy wallet_goals_insert on public.wallet_goals
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
  );

drop policy if exists wallet_goals_update on public.wallet_goals;
create policy wallet_goals_update on public.wallet_goals
  for update using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  )
  with check (
    (home_id is null and owner_id = auth.uid())
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_goals_delete on public.wallet_goals;
create policy wallet_goals_delete on public.wallet_goals
  for delete using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

grant select, insert, update, delete on public.wallet_goals to authenticated;
