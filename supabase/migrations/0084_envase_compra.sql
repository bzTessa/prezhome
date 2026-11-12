-- Tamaño del envase del súper de cada línea de la compra, en la misma unidad
-- que la línea (200 para una nata de 200 ml). Con él la cantidad se cuenta en
-- envases ("2 × 200 ml"). Null = no se sabe o va suelto. Idempotente.
alter table public.shopping_list_items
  add column if not exists pack_size numeric;

alter table public.shopping_list_items
  drop constraint if exists shopping_list_items_pack_size_check;
alter table public.shopping_list_items
  add constraint shopping_list_items_pack_size_check
    check (pack_size is null or pack_size > 0);
