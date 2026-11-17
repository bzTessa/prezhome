-- Lo que trae cada envase de un producto según el hogar ("Garbanzos: 570 g").
-- Manda sobre el catálogo del súper: la compra cuenta envases enteros y la
-- despensa resta solo lo que gasta cada receta. Idempotente.
alter table public.product_count_prefs
  add column if not exists pack_size numeric,
  add column if not exists pack_unit text;

alter table public.product_count_prefs
  drop constraint if exists product_count_prefs_pack_check;
alter table public.product_count_prefs
  add constraint product_count_prefs_pack_check check (
    (pack_size is null and pack_unit is null)
    or (pack_size > 0 and pack_unit in ('g', 'ml'))
  );
