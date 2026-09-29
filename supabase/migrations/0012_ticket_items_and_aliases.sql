-- ============================================================================
-- PrezHome · Desglose de tickets (productos) + memoria de correcciones
-- ============================================================================
-- Reutiliza la tabla public.tickets (0002). Añade:
--   - ticket_items: cada producto de un ticket (nombre, precio, cantidad, categoría)
--   - product_aliases: memoria de correcciones (texto del ticket -> nombre correcto)
--     para que la IA no repita errores de abreviaturas en el mismo hogar.
-- RLS por hogar. Idempotente.
-- ============================================================================

-- Productos de cada ticket
create table if not exists public.ticket_items (
  id          uuid primary key default gen_random_uuid(),
  ticket_id   uuid not null references public.tickets (id) on delete cascade,
  home_id     uuid not null references public.homes (id) on delete cascade,
  raw_name    text,                 -- lo que ponía el ticket (ej. "LCH DESNAT")
  name        text not null,        -- nombre corregido/legible
  category    text,                 -- lácteos, verdura, carne, limpieza...
  quantity    numeric default 1,
  unit_price  numeric,              -- precio por unidad
  total_price numeric,              -- precio total de la línea
  position    integer not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists ticket_items_ticket_id_idx
  on public.ticket_items (ticket_id);
create index if not exists ticket_items_home_id_idx
  on public.ticket_items (home_id);
create index if not exists ticket_items_name_idx on public.ticket_items (name);

-- Memoria de correcciones de nombres (abreviatura del ticket -> nombre real)
create table if not exists public.product_aliases (
  id           uuid primary key default gen_random_uuid(),
  home_id      uuid not null references public.homes (id) on delete cascade,
  raw_name     text not null,       -- "LCH DESNAT"
  correct_name text not null,       -- "Leche desnatada"
  category     text,
  updated_at   timestamptz not null default now(),
  unique (home_id, raw_name)
);
create index if not exists product_aliases_home_id_idx
  on public.product_aliases (home_id);

-- Añadir categoría de tienda a tickets (opcional, útil para stats)
alter table public.tickets
  add column if not exists store_category text;

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.ticket_items enable row level security;
alter table public.product_aliases enable row level security;

drop policy if exists ticket_items_select on public.ticket_items;
create policy ticket_items_select on public.ticket_items
  for select using (home_id = public.auth_home_id());

drop policy if exists ticket_items_insert on public.ticket_items;
create policy ticket_items_insert on public.ticket_items
  for insert with check (home_id = public.auth_home_id());

drop policy if exists ticket_items_update on public.ticket_items;
create policy ticket_items_update on public.ticket_items
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists ticket_items_delete on public.ticket_items;
create policy ticket_items_delete on public.ticket_items
  for delete using (home_id = public.auth_home_id());

drop policy if exists product_aliases_select on public.product_aliases;
create policy product_aliases_select on public.product_aliases
  for select using (home_id = public.auth_home_id());

drop policy if exists product_aliases_insert on public.product_aliases;
create policy product_aliases_insert on public.product_aliases
  for insert with check (home_id = public.auth_home_id());

drop policy if exists product_aliases_update on public.product_aliases;
create policy product_aliases_update on public.product_aliases
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

-- ----------------------------------------------------------------------------
-- GRANTs
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on public.ticket_items to authenticated;
grant select, insert, update, delete on public.product_aliases to authenticated;
