-- ============================================================================
-- PrezHome · Arreglo definitivo del 403 al subir fotos de recetas (RLS Storage)
-- ============================================================================
-- Al subir una foto de receta, Supabase Storage seguia devolviendo:
--     new row violates row-level security policy (statusCode 403, Unauthorized)
-- es decir, la politica RLS de INSERT sobre storage.objects para el bucket
-- publico recipe-images no permitia la subida.
--
-- Causa raiz (comparando los dos buckets):
--   El bucket PRIVADO tickets (ver 0002_storage_tickets_ocr.sql) SI funciona en
--   produccion. Sus politicas sobre storage.objects usan la condicion probada
--     bucket_id = 'tickets'
--     and (storage.foldername(name))[1] = public.auth_home_id()::text
--   y NO llevan la clausula `to authenticated`.
--
--   El bucket PUBLICO recipe-images se definio en 0013 (con `to authenticated`),
--   se re-aseguro en 0021 (con `to authenticated`) y en 0022 se quito
--   `to authenticated` dejando solo `bucket_id = 'recipe-images'`. Pese a aplicar
--   0022, el 403 PERSISTE: comprobar unicamente bucket_id no reproduce el patron
--   que la usuaria ya tiene funcionando.
--
--   La subida real (lib/add_recipe_screen.dart, _uploadImageIfAny) usa la ruta
--   '{homeId}/<timestamp>.<ext>', por lo que la primera carpeta de la ruta ES el
--   home_id y encaja perfectamente con la condicion foldername[1]=auth_home_id()
--   que usa tickets.
--
-- Arreglo: replicar EXACTAMENTE el patron probado de tickets tambien en
-- recipe-images. Se redefinen (drop + create) las tres politicas de escritura
-- comprobando bucket_id Y (storage.foldername(name))[1] = public.auth_home_id(),
-- SIN `to authenticated`, igual que tickets_insert/update/delete de 0002.
--
-- La migracion es idempotente (drop policy if exists + create; on conflict do
-- nothing en el bucket). No se modifica ninguna migracion previa (0001-0022 son
-- inmutables) ni se borra nada mas que las propias politicas que se recrean. No
-- hay DROP TABLE ni DROP COLUMN.
-- ============================================================================

-- INSERT: subir imagenes de recetas solo si la primera carpeta de la ruta es el
-- home_id del usuario, replicando tickets_insert (sin `to authenticated`).
drop policy if exists recipe_images_insert on storage.objects;
create policy recipe_images_insert on storage.objects
  for insert with check (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

-- UPDATE: gestionar imagenes del propio hogar, replicando tickets_update.
drop policy if exists recipe_images_update on storage.objects;
create policy recipe_images_update on storage.objects
  for update using (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

-- DELETE: borrar imagenes del propio hogar, replicando tickets_delete.
drop policy if exists recipe_images_delete on storage.objects;
create policy recipe_images_delete on storage.objects
  for delete using (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

-- Re-asegurar el bucket publico de forma idempotente por si no existiera.
-- Al ser publico, la lectura no necesita politica de SELECT (igual que en 0013).
insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;

-- Refuerzo frente a una posible segunda causa del 403: un GRANT base ausente
-- sobre storage.objects. Las politicas RLS pueden permitir la operacion, pero
-- si el rol authenticated no tiene permiso de tabla, la operacion falla igual.
-- Este GRANT es seguro: el acceso real sigue limitado por las politicas RLS de
-- arriba (bucket_id + foldername = home_id); sin el GRANT base, el rol podria no
-- tener permiso de tabla aunque la RLS lo permitiera.
grant select, insert, update, delete on storage.objects to authenticated;
