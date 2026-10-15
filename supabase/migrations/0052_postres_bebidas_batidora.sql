-- Recetas: permitir Postre y Bebida como tipo de comida y la Batidora como aparato.
-- El check antiguo de meal_type no incluía 'dessert', así que guardar un postre fallaba.
alter table public.recipes drop constraint if exists recipes_meal_type_check;
alter table public.recipes add constraint recipes_meal_type_check
  check (meal_type = any (array['breakfast','lunch','dinner','snack','dessert','drink']));

alter table public.recipes drop constraint if exists recipes_appliance_check;
alter table public.recipes add constraint recipes_appliance_check
  check (appliance = any (array['none','oven','stovetop','pot','airfryer','microwave','blender']));
