-- ============================================================================
-- PrezHome · Arreglo del 403 al subir fotos de recetas (RLS de Storage)
-- ============================================================================
-- Al subir una foto de receta, Supabase Storage devolvia:
--     new row violates row-level security policy (statusCode 403, Unauthorized)
-- Es decir, la politica RLS de INSERT sobre storage.objects para el bucket
-- publico recipe-images no permitia la subida.
--
-- Causa: las politicas de recipe-images (definidas en 0013 y re-aseguradas en
-- 0021) llevaban la clausula `to authenticated`. En cambio el bucket tickets,
-- que SI funciona (ver 0002_storage_tickets_ocr.sql), define sus politicas sin
-- esa clausula, usando el rol por defecto. La diferencia del `to authenticated`
-- es lo que provocaba el 403.
--
-- Arreglo: redefinir (drop + create) las tres politicas de recipe-images
-- QUITANDO `to authenticated`, replicando el estilo del bucket tickets. Las
-- fotos de recetas van en un bucket publico y no son datos sensibles, asi que
-- basta con comprobar el bucket_id, igual que antes, pero sin `to authenticated`.
-- Se conservan los MISMOS nombres de politica (recipe_images_insert/update/
-- delete) y la misma condicion sobre bucket_id.
--
-- La migracion es idempotente (drop policy if exists + create). No se modifica
-- ninguna migracion previa (0001-0021 son inmutables) ni se borra nada mas que
-- las propias politicas que se vuelven a crear.
-- ============================================================================

-- INSERT: cualquier usuario puede subir imagenes de recetas al bucket publico.
-- Sin `to authenticated`, igual que tickets_insert, que funciona.
drop policy if exists recipe_images_insert on storage.objects;
create policy recipe_images_insert on storage.objects
  for insert with check (bucket_id = 'recipe-images');

-- UPDATE: gestion de imagenes de recetas en el bucket publico, sin `to authenticated`.
drop policy if exists recipe_images_update on storage.objects;
create policy recipe_images_update on storage.objects
  for update using (bucket_id = 'recipe-images');

-- DELETE: borrado de imagenes de recetas en el bucket publico, sin `to authenticated`.
drop policy if exists recipe_images_delete on storage.objects;
create policy recipe_images_delete on storage.objects
  for delete using (bucket_id = 'recipe-images');
