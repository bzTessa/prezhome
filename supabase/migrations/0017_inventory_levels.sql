-- ============================================================================
-- PrezHome · Inventario con niveles (cimiento del congelador inteligente)
-- ============================================================================
-- Amplía inventory_items para distinguir QUÉ tipo de cosa es cada item, lo cual
-- es la base para el meal prep y el planificador que usa el congelador:
--   kind:
--     'ingredient'  -> ingrediente crudo (ej. pollo troceado, cebolla picada)
--     'prep'        -> preparado intermedio (ej. sofrito, sopa en daditos)
--     'dish'        -> plato terminado listo para comer (ej. lentejas)
-- - recipe_id: si el item procede de una receta (para platos/preparados).
-- - servings: nº de raciones que representa (para platos/preparados congelados).
-- - frozen_on: fecha de congelación (para saber antigüedad).
-- Idempotente. Mantiene los campos existentes (name, category, quantity, unit...).
-- ============================================================================

alter table public.inventory_items
  add column if not exists kind text not null default 'ingredient'
    check (kind in ('ingredient', 'prep', 'dish'));

alter table public.inventory_items
  add column if not exists recipe_id uuid references public.recipes (id) on delete set null;

alter table public.inventory_items
  add column if not exists servings numeric;

alter table public.inventory_items
  add column if not exists frozen_on date;
