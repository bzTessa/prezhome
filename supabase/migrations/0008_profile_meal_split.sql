-- ============================================================================
-- PrezHome · Reparto de calorías por comida en el perfil
-- ============================================================================
-- Guarda qué porcentaje de las calorías diarias corresponde a cada comida
-- (breakfast/lunch/dinner/snack/dessert). Con esto la app calcula, para una
-- receta de un tipo dado, cuántas kcal te tocan y cuántos gramos poner.
-- Se guarda como JSON: { "breakfast": 20, "lunch": 40, "dinner": 40, "snack": 0 }
-- Idempotente.
-- ============================================================================

alter table public.profiles
  add column if not exists meal_split jsonb not null
  default '{"breakfast": 20, "lunch": 40, "dinner": 40, "snack": 0, "dessert": 0}'::jsonb;
