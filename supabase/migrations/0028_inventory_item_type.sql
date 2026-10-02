-- ============================================================================
-- PrezHome · Tipo de item en el inventario (comida vs hogar/limpieza)
-- ============================================================================
-- Permite distinguir en el inventario los productos de COMIDA de los de
-- HOGAR/LIMPIEZA (ej. detergente, lejía, papel). Esto es la base para que la
-- UI muestre y filtre ambos tipos y para que el alta desde tickets clasifique
-- los productos.
--   item_type:
--     'comida' -> alimentos (por defecto, conserva el comportamiento actual)
--     'hogar'  -> productos de hogar/limpieza
--
-- Además se RELAJA el CHECK de category. En 0001 inventory_items.category se
-- definió con un CHECK inline: check (category in ('Despensa','Nevera','Congelador')).
-- Al ser inline sin nombre, Postgres lo nombra por defecto
-- 'inventory_items_category_check'. Ese CHECK impide insertar items de hogar
-- con categorías no-comida (ej. 'Limpieza','Hogar'), por eso se elimina y se
-- recrea admitiendo también esas categorías.
--
-- Idempotente. Los items existentes conservan su category
-- ('Despensa'|'Nevera'|'Congelador') y quedan item_type='comida' por el default,
-- sin romper datos. No toca RLS ni grants (ya existen desde 0001 y item_type no
-- afecta a la seguridad por hogar).
-- ============================================================================

-- 1. Columna item_type con default 'comida' (los datos existentes quedan comida).
alter table public.inventory_items
  add column if not exists item_type text not null default 'comida';

-- CHECK de item_type, creado de forma idempotente (guardado por existencia).
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'inventory_items_item_type_check'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_item_type_check
      check (item_type in ('comida', 'hogar'));
  end if;
end $$;

-- 2. Relajar el CHECK de category para admitir categorías de hogar/limpieza.
--    El CHECK original (de 0001) solo admitía ubicaciones de comida; los items
--    de hogar usan categorías no-comida ('Limpieza','Hogar'), que de otro modo
--    violarían el constraint al insertar.
--
--    En vez de asumir el nombre por defecto del CHECK inline de 0001
--    ('inventory_items_category_check'), eliminamos dinámicamente CUALQUIER
--    constraint CHECK de la tabla cuya definición mencione 'category'. Así es
--    robusto aunque el constraint llegara con otro nombre en algún entorno,
--    sin tocar 0001-0027.
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
      check (category in ('Despensa', 'Nevera', 'Congelador', 'Limpieza', 'Hogar'));
  end if;
end $$;
