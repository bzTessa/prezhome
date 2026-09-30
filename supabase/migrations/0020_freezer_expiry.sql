-- ============================================================================
-- PrezHome · Caducidad / consumo preferente de congelados
-- ============================================================================
-- - recipes.freezer_days: días recomendados de congelación para esa receta
--   (lo estima la IA según el tipo de plato: un pescado dura menos que un guiso).
-- - inventory_items.best_before: fecha límite de consumo preferente del item.
--   Se calcula al congelar (frozen_on + freezer_days) pero es editable.
-- El planificador usará best_before para priorizar lo que caduca antes (FIFO).
-- Idempotente.
-- ============================================================================

alter table public.recipes
  add column if not exists freezer_days integer;

alter table public.inventory_items
  add column if not exists best_before date;
