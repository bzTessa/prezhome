-- ============================================================================
-- PrezHome · Precios de mercado por país (Open Prices)
-- ============================================================================
-- Medianas de precio por alimento y país que importa cada semana
-- scripts/open_prices_sync.py desde Open Prices (Open Food Facts, ODbL).
-- La app las usa como precio aproximado antes de la tabla fija de
-- ApproxPrice, y siempre por detrás de los tickets reales.
--
-- Datos públicos y comunes a todos: cualquier usuario autenticado puede
-- leerlos; solo el importador (service_role, que salta RLS) escribe.
-- ============================================================================

create table if not exists public.market_prices (
  country_code  text not null,             -- ISO 3166-1 alfa-2, p. ej. 'ES'
  keyword       text not null,             -- clave de alimento ('tomate')
  unit          text not null check (unit in ('kg', 'l', 'ud')),
  currency      text not null,             -- ISO 4217, p. ej. 'EUR'
  median_price  numeric not null check (median_price > 0),
  samples       integer not null,
  updated_at    date not null default current_date,
  primary key (country_code, keyword, unit)
);

alter table public.market_prices enable row level security;

drop policy if exists market_prices_select on public.market_prices;
create policy market_prices_select on public.market_prices
  for select to authenticated using (true);

grant select on public.market_prices to authenticated;
