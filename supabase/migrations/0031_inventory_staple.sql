-- ============================================================================
-- PrezHome · Basicos "siempre en casa" (staple) en el inventario
-- ============================================================================
-- Permite marcar un item del inventario como BASICO/"siempre en casa" (staple).
-- Pensado sobre todo para especias y basicos (sal, pimienta, aceite, azucar...)
-- que la usuaria da por supuestos y no quiere que acaben en la lista de la
-- compra cuando una receta los pide en pequenas cantidades.
--   is_staple:
--     false -> comportamiento normal (por defecto, no cambia los datos actuales)
--     true  -> "siempre en casa": _generarDesdePlan lo trata como disponible y
--              NO lo anade a la lista de la compra, por poca cantidad que pida
--              la receta.
--
-- is_staple es un campo OPERATIVO del hogar (una preferencia de gestion), NO de
-- control de acceso: NO toca RLS, policies ni grants, que ya existen desde 0001
-- (y 0028 para item_type). La seguridad por hogar sigue siendo
-- 'home_id = public.auth_home_id()', sin cambios.
--
-- Idempotente (add column if not exists). Los items existentes quedan
-- is_staple=false por el default, sin romper datos. Sigue el estilo de 0028
-- (comentarios en espanol, guardas idempotentes).
-- ============================================================================

-- Columna is_staple con default false (los datos existentes quedan en false).
alter table public.inventory_items
  add column if not exists is_staple boolean not null default false;
