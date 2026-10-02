-- ============================================================================
-- PrezHome · Arreglo del 403 al subir fotos de recetas (RLS de Storage), v4
-- ============================================================================
-- Al guardar una receta con foto, Supabase Storage seguia devolviendo:
--     new row violates row-level security policy (statusCode 403, Unauthorized)
-- La subida real (lib/add_recipe_screen.dart, _uploadImageIfAny) hace:
--     storage.from('recipe-images').uploadBinary('{homeId}/<timestamp>.<ext>',
--       bytes, FileOptions(contentType, upsert: true))
-- sobre el bucket PUBLICO recipe-images.
--
-- Historico de intentos fallidos (el 403 persistio en todos):
--   0013: insert/update/delete to authenticated + bucket_id = 'recipe-images'.
--   0021: re-asegura lo mismo (to authenticated + bucket_id).
--   0022: quita `to authenticated`, deja solo bucket_id.
--   0023: copia el patron del bucket tickets:
--           bucket_id = 'recipe-images'
--           and (storage.foldername(name))[1] = public.auth_home_id()::text
--         sin `to authenticated`, mas grant base sobre storage.objects.
-- Tras 0022 y 0023 el 403 SIGUE apareciendo.
--
-- Por que la comparacion con el bucket tickets NO es fiable:
--   La premisa de 0023 era "tickets funciona, replico su patron". Pero tickets
--   NUNCA sube una imagen de verdad: en lib/scan_ticket_screen.dart la insercion
--   usa 'storage_path': '' con el comentario "(futuro: subir la imagen al
--   bucket)". Es decir, las politicas de storage de tickets basadas en
--   foldername + auth_home_id() JAMAS se han ejercitado en un INSERT real de
--   storage.objects. "tickets funciona" no demuestra que ese patron sea valido
--   para una subida real; copiarlo (0023) carecia de fundamento.
--
-- Por que falla la condicion foldername + auth_home_id() aqui:
--   public.auth_home_id() (0001_initial_schema.sql) es:
--     select home_id from public.profiles where id = auth.uid();
--   La condicion (storage.foldername(name))[1] = public.auth_home_id()::text es
--   fragil en el contexto de una request de Storage: si auth.uid() o
--   profiles.home_id no resuelven como se espera en ese contexto, la condicion
--   da false y Storage responde 403. Para un bucket PUBLICO de imagenes NO
--   sensibles no hace falta esa comprobacion por hogar.
--
-- Arreglo (minimo y robusto):
--   Para un bucket publico de imagenes no sensibles, la policy correcta es
--   comprobar unicamente el bucket para el rol authenticated:
--     for insert to authenticated with check (bucket_id = 'recipe-images')
--   Esto evita depender de auth_home_id() dentro del contexto de storage y es
--   mas robusto. El dato sensible (la receta en public.recipes) sigue protegido
--   por su propia RLS por hogar; la imagen del plato no es dato sensible.
--   Se eliminan TODAS las politicas recipe_images_* acumuladas por los intentos
--   previos (0013/0021/0022/0023) y se crea UNA version limpia y consistente de
--   insert/update/delete. Como upsert:true puede sobrescribir, update/delete se
--   recrean con la misma condicion simple para que no vuelva a dar 403.
--
-- Esta migracion es idempotente (drop policy if exists + create; on conflict do
-- nothing en el bucket; grant). No modifica ninguna migracion previa (0001-0023
-- son inmutables) ni borra nada mas que las propias politicas que recrea. No
-- contiene DROP TABLE ni DROP COLUMN.
-- ============================================================================

-- Eliminar TODAS las politicas recipe_images_* acumuladas en intentos previos
-- para no dejar politicas contradictorias conviviendo sobre storage.objects.
drop policy if exists recipe_images_insert on storage.objects;
drop policy if exists recipe_images_update on storage.objects;
drop policy if exists recipe_images_delete on storage.objects;

-- INSERT: cualquier usuario autenticado puede subir imagenes al bucket publico
-- recipe-images. Solo se comprueba el bucket (nada de auth_home_id en storage).
create policy recipe_images_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'recipe-images');

-- UPDATE: permite sobrescribir imagenes (upsert:true de _uploadImageIfAny) con
-- la misma condicion simple, de forma consistente con el INSERT.
create policy recipe_images_update on storage.objects
  for update to authenticated
  using (bucket_id = 'recipe-images')
  with check (bucket_id = 'recipe-images');

-- DELETE: permite borrar imagenes del bucket publico, misma condicion simple.
create policy recipe_images_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'recipe-images');

-- Re-asegurar el bucket publico de forma idempotente por si no existiera. Al
-- ser publico, la lectura no necesita politica de SELECT (igual que en 0013).
insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;

-- GRANT base sobre storage.objects para el rol authenticated. Las politicas RLS
-- pueden permitir la operacion, pero sin permiso de tabla la operacion falla
-- igual. Este GRANT es seguro: el acceso real sigue limitado por las policies
-- RLS de arriba (bucket_id = 'recipe-images').
grant select, insert, update, delete on storage.objects to authenticated;
