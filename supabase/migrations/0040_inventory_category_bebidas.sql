-- ============================================================================
-- PrezHome · Nueva ubicación de inventario: "Bebidas"
-- ============================================================================
-- Añade "Bebidas" como ubicación válida de los productos de COMIDA del
-- inventario (agua, refrescos, zumos, leche, vino, cerveza...), para tenerlas
-- en su propia sección en la despensa.
--
-- Mismo patrón robusto e idempotente de 0028/0035: eliminamos cualquier CHECK
-- cuya definición mencione 'category' y lo recreamos con la lista ampliada.
-- No toca RLS, grants ni datos existentes.
-- ============================================================================

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

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'inventory_items_category_check'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_category_check
      check (category in ('Despensa', 'Nevera', 'Congelador', 'Especias', 'Bebidas', 'Limpieza', 'Hogar'));
  end if;
end $$;
