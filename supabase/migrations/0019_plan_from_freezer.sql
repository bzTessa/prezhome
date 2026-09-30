-- ============================================================================
-- PrezHome · Marcar comidas del plan que salen del congelador
-- ============================================================================
-- Permite que el planificador priorice los platos ya congelados: una entrada
-- del plan puede indicar que se consume del congelador (from_freezer) y de qué
-- item del inventario procede (inventory_item_id), para descontarlo al comerlo.
-- Idempotente.
-- ============================================================================

alter table public.meal_plan_entries
  add column if not exists from_freezer boolean not null default false;

alter table public.meal_plan_entries
  add column if not exists inventory_item_id uuid
    references public.inventory_items (id) on delete set null;
