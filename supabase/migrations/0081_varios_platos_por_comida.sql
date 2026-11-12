-- ============================================================================
-- PrezHome · Varios platos por comida (primero, segundo, postre...)
-- ============================================================================
-- Antes cada comida del plan tenía una sola receta (UNIQUE hogar/día/comida).
-- Ahora "position" ordena los platos de una misma comida: 0 es el principal y
-- 1, 2... los que se añaden con "Añadir otro plato". Lo existente queda en 0.
-- Idempotente.
-- ============================================================================

alter table public.meal_plan_entries
  add column if not exists position smallint not null default 0;

alter table public.meal_plan_entries
  drop constraint if exists meal_plan_entries_home_id_plan_date_meal_type_key;

create unique index if not exists meal_plan_entries_meal_position_key
  on public.meal_plan_entries (home_id, plan_date, meal_type, position);
