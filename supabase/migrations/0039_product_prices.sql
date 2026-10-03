-- ============================================================================
-- PrezHome · Memoria de precios por producto (aprende de los tickets)
-- ============================================================================
-- Cada vez que se escanea/guarda un ticket, la app actualiza aquí el precio
-- conocido de cada producto (por nombre normalizado y hogar). Sirve para:
--   - estimar el COSTE de la lista de la compra y de cada comida,
--   - presupuestos y costes más exactos con el tiempo,
--   - estadísticas de productos y precios.
--
-- Guardamos el ÚLTIMO precio unitario visto + una media acumulada y el nº de
-- muestras, para poder mostrar evolución y precios típicos. Un producto se
-- identifica por name_normalized (misma normalización que CategoryIcons:
-- minúsculas, sin acentos) para agrupar "Leche"/"leche".
--
-- RLS por hogar (patrón de 0026/0034). Idempotente. NUEVA tabla, por eso sí
-- declara sus políticas.
-- ============================================================================

create table if not exists public.product_prices (
  home_id          uuid not null references public.homes (id) on delete cascade,
  name_normalized  text not null,
  display_name     text,            -- último nombre legible visto
  last_unit_price  numeric,         -- último precio por unidad conocido
  avg_unit_price   numeric,         -- media acumulada del precio por unidad
  samples          integer not null default 0,  -- nº de veces visto con precio
  last_seen        timestamptz not null default now(),
  primary key (home_id, name_normalized)
);

create index if not exists product_prices_home_idx
  on public.product_prices (home_id);

-- ----------------------------------------------------------------------------
-- RLS por hogar
-- ----------------------------------------------------------------------------
alter table public.product_prices enable row level security;

drop policy if exists product_prices_select on public.product_prices;
create policy product_prices_select on public.product_prices
  for select using (home_id = public.auth_home_id());

drop policy if exists product_prices_insert on public.product_prices;
create policy product_prices_insert on public.product_prices
  for insert with check (home_id = public.auth_home_id());

drop policy if exists product_prices_update on public.product_prices;
create policy product_prices_update on public.product_prices
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists product_prices_delete on public.product_prices;
create policy product_prices_delete on public.product_prices
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.product_prices to authenticated;
