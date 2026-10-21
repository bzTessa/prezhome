-- Rendimiento (avisos del linter de Supabase).
--
-- 1) Índices en claves foráneas que la app usa en joins/filtros o que se
--    revisan al borrar la fila padre (receta, lista, tarea...).
-- 2) RLS: `(select auth.uid())` se evalúa una vez por consulta en lugar de
--    una vez por fila. Mismo significado, solo cambia el coste.

create index if not exists profiles_home_id_idx on public.profiles (home_id);
create index if not exists home_members_user_id_idx on public.home_members (user_id);
create index if not exists shopping_list_items_list_id_idx on public.shopping_list_items (list_id);
create index if not exists shopping_list_items_category_id_idx on public.shopping_list_items (category_id);
create index if not exists meal_plan_entries_recipe_id_idx on public.meal_plan_entries (recipe_id);
create index if not exists meal_plan_entries_inventory_item_id_idx on public.meal_plan_entries (inventory_item_id);
create index if not exists meal_plan_feedback_recipe_id_idx on public.meal_plan_feedback (recipe_id);
create index if not exists food_log_entries_recipe_id_idx on public.food_log_entries (recipe_id);
create index if not exists inventory_items_recipe_id_idx on public.inventory_items (recipe_id);
create index if not exists pantry_log_recipe_id_idx on public.pantry_log (recipe_id);
create index if not exists task_points_task_id_idx on public.task_points (task_id);

alter policy profiles_select on public.profiles
  using ((id = (select auth.uid()))
    or ((home_id is not null) and (home_id = auth_home_id()) and (is_public = true)));
alter policy profiles_update on public.profiles
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

alter policy food_log_select on public.food_log_entries
  using (user_id = (select auth.uid()));
alter policy food_log_insert on public.food_log_entries
  with check (user_id = (select auth.uid()));
alter policy food_log_update on public.food_log_entries
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
alter policy food_log_delete on public.food_log_entries
  using (user_id = (select auth.uid()));

alter policy task_points_insert on public.task_points
  with check ((home_id = auth_home_id()) and (user_id = (select auth.uid())));
alter policy reward_redemptions_insert on public.reward_redemptions
  with check ((home_id = auth_home_id()) and (redeemed_by = (select auth.uid())));
