-- ============================================================================
-- PrezHome · Raciones por comida en el plan (plan del hogar)
-- ============================================================================
-- Guarda cuántas RACIONES cocinar en cada entrada del plan según cuántos
-- miembros del hogar comen en casa ese día/comida. Es orientativo y flexible:
-- si la columna viene nula se usa el fallback de la receta. No altera RLS ni
-- policies (hereda las de meal_plan_entries). Idempotente.
-- ============================================================================

alter table public.meal_plan_entries
  add column if not exists servings integer;
