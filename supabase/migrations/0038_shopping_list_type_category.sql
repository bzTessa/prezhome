-- ============================================================================
-- PrezHome · Tipo y categoría en la lista de la compra
-- ============================================================================
-- Permite añadir a la lista de la compra cosas que NO son comida (hogar/
-- limpieza) y elegir su categoría/ubicación, para que al marcarlas como
-- compradas vayan al SITIO CORRECTO del inventario (comida -> su ubicación;
-- hogar -> Hogar/Limpieza).
--   item_type: 'comida' (por defecto) | 'hogar'
--   category : ubicación/sección sugerida (Nevera/Congelador/Despensa/
--              Especias/Limpieza/Hogar) o null para que el sistema la deduzca.
--
-- Dato operativo del hogar; NO toca RLS (shopping_list_items ya tiene sus
-- políticas por hogar desde 0026). Idempotente. Las filas existentes quedan
-- item_type='comida' y category null (comportamiento previo).
-- ============================================================================

alter table public.shopping_list_items
  add column if not exists item_type text not null default 'comida';

alter table public.shopping_list_items
  add column if not exists category text;
