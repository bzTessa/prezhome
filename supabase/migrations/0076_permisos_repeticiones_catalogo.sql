-- ============================================================================
-- PrezHome · Permisos que faltaban en 0072 y 0074
-- ============================================================================
-- Este proyecto no da permisos por defecto a las tablas nuevas: sin GRANT, el
-- RLS ni se llega a evaluar y la app recibe "permission denied" (42501).
-- Repetir una comida del plan fallaba por eso. Las políticas ya existen.
-- ============================================================================

grant select, insert, update, delete on public.meal_plan_repeats to authenticated;
-- Mismo fallo en el catálogo de súpers (0074): la app lo lee al buscar.
grant select on public.supermarket_products to authenticated;
