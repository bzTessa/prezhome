-- ============================================================================
-- PrezHome · Seguridad: el bucket recipe-images solo se escribe en tu hogar
-- ============================================================================
-- 0025 dejó insert/update/delete con solo bucket_id = 'recipe-images' y sin rol,
-- así que cualquiera con la clave pública (incluso sin sesión) podía subir,
-- sobrescribir o borrar fotos de cualquier hogar. Todas las subidas de la app
-- usan la ruta '{homeId}/<archivo>' y las Edge Functions (icons/...) usan la
-- service role, que no pasa por RLS. Comprobado en producción que
-- auth_home_id() resuelve con el rol authenticated. Además: solo jpg/png y 5 MB.
-- Idempotente.
-- ============================================================================

update storage.buckets
   set file_size_limit = 5242880,
       allowed_mime_types = array['image/jpeg', 'image/png']
 where id = 'recipe-images';

drop policy if exists recipe_images_insert on storage.objects;
drop policy if exists recipe_images_update on storage.objects;
drop policy if exists recipe_images_delete on storage.objects;

create policy recipe_images_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = (select public.auth_home_id())::text
  );

create policy recipe_images_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = (select public.auth_home_id())::text
  )
  with check (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = (select public.auth_home_id())::text
  );

create policy recipe_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = (select public.auth_home_id())::text
  );
