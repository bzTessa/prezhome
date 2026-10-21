-- ============================================================================
-- PrezWallet · Rentabilidad histórica de la cartera
-- ============================================================================
-- Idempotente.
-- wallet_trades: compras y ventas con fecha de cada posición; con ellas se sabe
--   cuántas participaciones había cada día y cuánto dinero entró o salió.
-- wallet_prices: cierre diario en euros de cada valor (dato de mercado, igual
--   para todos). Lo escribe solo la función wallet-prices con la clave de
--   servicio; la app solo lo lee.
-- ============================================================================

create table if not exists public.wallet_trades (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  home_id     uuid references public.homes (id) on delete cascade,
  holding_id  uuid not null references public.wallet_holdings (id) on delete cascade,
  side        text not null default 'buy' check (side in ('buy', 'sell')),
  quantity    numeric not null check (quantity > 0),
  price       numeric not null check (price >= 0),
  traded_on   date not null default current_date,
  created_at  timestamptz not null default now()
);
create index if not exists wallet_trades_owner_idx on public.wallet_trades (owner_id);
create index if not exists wallet_trades_home_idx on public.wallet_trades (home_id);
create index if not exists wallet_trades_holding_idx on public.wallet_trades (holding_id);

alter table public.wallet_trades enable row level security;

drop policy if exists wallet_trades_select on public.wallet_trades;
create policy wallet_trades_select on public.wallet_trades
  for select using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_trades_insert on public.wallet_trades;
create policy wallet_trades_insert on public.wallet_trades
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
  );

drop policy if exists wallet_trades_update on public.wallet_trades;
create policy wallet_trades_update on public.wallet_trades
  for update using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  )
  with check (
    (home_id is null and owner_id = auth.uid())
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_trades_delete on public.wallet_trades;
create policy wallet_trades_delete on public.wallet_trades
  for delete using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

grant select, insert, update, delete on public.wallet_trades to authenticated;

create table if not exists public.wallet_prices (
  symbol     text not null,
  day        date not null,
  close_eur  numeric not null check (close_eur >= 0),
  primary key (symbol, day)
);

alter table public.wallet_prices enable row level security;

drop policy if exists wallet_prices_select on public.wallet_prices;
create policy wallet_prices_select on public.wallet_prices
  for select to authenticated using (true);

grant select on public.wallet_prices to authenticated;
