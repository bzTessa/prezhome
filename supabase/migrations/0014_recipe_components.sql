-- ============================================================================
-- PrezHome · Componentes del plato (para desglosar gramos en el taper)
-- ============================================================================
-- Para platos combinados (ej. "Pollo al roquefort con arroz"), guarda las
-- partes del plato YA COCINADO con su proporción, para poder decir cuántos
-- gramos de cada parte poner. Se guarda como JSON en la propia receta:
--   [ { "name": "Pollo al roquefort", "proportion": 55 },
--     { "name": "Arroz blanco", "proportion": 45 } ]
-- Las proporciones son % del peso total del plato. Idempotente.
-- ============================================================================

alter table public.recipes
  add column if not exists components jsonb;
