-- ============================================================================
-- PrezHome · Recetas: tipos de comida múltiples + pasos de preparación
-- ============================================================================
-- - meal_types: una receta puede valer para varias comidas (comida Y cena...).
--   Mantenemos meal_type (singular) por compatibilidad, pero la app usará el array.
-- - instructions: pasos de preparación (texto), para poder verlos en el detalle.
-- Idempotente.
-- ============================================================================

-- Array de tipos de comida (breakfast/lunch/dinner/snack)
alter table public.recipes
  add column if not exists meal_types text[] not null default '{}';

-- Pasos / instrucciones de preparación
alter table public.recipes
  add column if not exists instructions text;

-- Rellenar meal_types a partir del meal_type existente (solo si está vacío)
update public.recipes
set meal_types = array[meal_type]
where (meal_types is null or array_length(meal_types, 1) is null)
  and meal_type is not null;
