-- ============================================================================
-- PrezHome · Arreglo de renombrar hogar, fotos de recetas y plan semanal
-- ============================================================================
-- Esta migracion arregla de raiz tres bugs reportados:
--
--   1) Renombrar el hogar fallaba: public.homes tiene RLS activado pero solo
--      tenia politica de SELECT (homes_select). Al faltar una politica de
--      UPDATE, el UPDATE del cliente no afectaba a ninguna fila. Se anade
--      homes_update para que el usuario pueda renombrar su propio hogar.
--
--   2) Las fotos de recetas no se guardaban: se re-asegura el bucket publico
--      recipe-images y sus politicas de storage por si la migracion 0013 no
--      llego a aplicarse en la base de datos de la usuaria.
--
--   3) El plan semanal fallaba: la causa probable son migraciones sin aplicar.
--      Se re-aseguran de forma defensiva las columnas que anade 0019 sobre
--      meal_plan_entries. Al desplegar esta migracion, `supabase db push`
--      aplicara ademas TODAS las migraciones pendientes (0013-0020) en orden,
--      resolviendo de rebote los bugs 2 y 3.
--
-- Toda la migracion es idempotente (drop policy if exists + create,
-- add column if not exists, on conflict do nothing). No se modifica ninguna
-- migracion previa ni se borra nada: solo DROP POLICY IF EXISTS, nunca
-- DROP TABLE ni DROP COLUMN.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- BUG 1 · Politica UPDATE sobre public.homes (renombrar hogar)
-- ----------------------------------------------------------------------------
-- Permite que un miembro del hogar actualice su propio hogar (p. ej. cambiar
-- el nombre). Usa la misma funcion public.auth_home_id() que homes_select.
-- La creacion de hogares sigue yendo por la funcion create_home_and_join,
-- no por un INSERT directo.
drop policy if exists homes_update on public.homes;
create policy homes_update on public.homes
  for update to authenticated
  using (id = public.auth_home_id())
  with check (id = public.auth_home_id());

-- ----------------------------------------------------------------------------
-- BUG 2 · Bucket y politicas de imagenes de recetas
-- ----------------------------------------------------------------------------
-- Re-asegura el recurso de 0013_recipe_images.sql por si no se habia aplicado
-- en la base de datos de la usuaria. Replica la misma intencion de forma
-- idempotente: bucket publico recipe-images y escritura para autenticados.
insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;

drop policy if exists recipe_images_insert on storage.objects;
create policy recipe_images_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'recipe-images');

drop policy if exists recipe_images_update on storage.objects;
create policy recipe_images_update on storage.objects
  for update to authenticated
  using (bucket_id = 'recipe-images');

drop policy if exists recipe_images_delete on storage.objects;
create policy recipe_images_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'recipe-images');

-- ----------------------------------------------------------------------------
-- BUG 3 · Columnas del plan semanal en meal_plan_entries
-- ----------------------------------------------------------------------------
-- La causa probable del fallo al regenerar el plan es que faltan migraciones
-- por aplicar. Al desplegar via `supabase db push` se aplicaran todas las
-- pendientes en orden. Aqui, de forma defensiva e idempotente, se re-aseguran
-- solo las dos columnas que anade 0019; NO se recrea la tabla ni sus politicas
-- (ya existen en 0016).
alter table public.meal_plan_entries
  add column if not exists from_freezer boolean not null default false;

alter table public.meal_plan_entries
  add column if not exists inventory_item_id uuid
    references public.inventory_items (id) on delete set null;
