-- ============================================================================
-- PrezHome · Nueva ubicación de inventario: "Especias"
-- ============================================================================
-- Añade "Especias" como ubicación válida de los productos de COMIDA del
-- inventario. Las especias y condimentos (sal, pimienta, aceite, vinagre...)
-- son básicos que no suelen gastarse rápido ni interesa que acaben en la lista
-- de la compra, por eso tienen su propia sección en la despensa y se marcan
-- como "siempre en casa" (is_staple) por defecto desde la UI.
--
-- El CHECK de inventory_items.category venía de 0001 (relajado en 0028 para
-- admitir 'Limpieza'/'Hogar'). Aquí lo volvemos a relajar para admitir también
-- 'Especias', con el MISMO patrón robusto e idempotente de 0028: eliminamos
-- cualquier CHECK cuya definición mencione 'category' y lo recreamos con la
-- lista ampliada. No toca RLS, grants ni datos existentes.
-- ============================================================================

-- 1. Eliminar dinámicamente cualquier CHECK sobre 'category' (robusto ante
--    nombres distintos entre entornos), igual que hace 0028.
do $$
declare
  r record;
begin
  for r in
    select conname
    from pg_constraint
    where conrelid = 'public.inventory_items'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%category%'
  loop
    execute format(
      'alter table public.inventory_items drop constraint %I',
      r.conname
    );
  end loop;
end $$;

-- 2. Recrear el CHECK admitiendo también 'Especias'.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'inventory_items_category_check'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_category_check
      check (category in ('Despensa', 'Nevera', 'Congelador', 'Especias', 'Limpieza', 'Hogar'));
  end if;
end $$;
