-- ============================================================================
-- PrezHome · Recetas que no hace falta cocinar
-- ============================================================================
-- "No hace falta cocinar" marcado a mano en una receta (café, yogur, fruta…).
-- null = lo decide la app por el nombre, el tipo y el tiempo. Lo que no se
-- cocina no sale en el modo cocina ni en la cocina en lote. Idempotente.
-- ============================================================================

alter table public.recipes
  add column if not exists no_cook boolean;
