-- ============================================================================
-- PrezHome · Peso por ración (gramos) en recetas
-- ============================================================================
-- Guarda cuántos gramos pesa UNA ración del plato ya preparado. Con esto y las
-- calorías por ración, la app calcula la densidad calórica (kcal/100 g) y, dado
-- un objetivo de calorías, cuántos gramos poner en el taper.
-- Idempotente.
-- ============================================================================

alter table public.recipes
  add column if not exists grams_per_serving numeric;
