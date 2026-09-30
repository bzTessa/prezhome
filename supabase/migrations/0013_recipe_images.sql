-- ============================================================================
-- PrezHome · Imágenes de recetas
-- ============================================================================
-- Las fotos de recetas van en un bucket PÚBLICO (a diferencia de los tickets,
-- que son privados). Las recetas no son datos sensibles y así se muestran con
-- una URL directa sencilla. La escritura sigue restringida por hogar.
-- Idempotente.
-- ============================================================================

-- Campo de imagen en la receta (ruta en el bucket)
alter table public.recipes
  add column if not exists image_path text;

-- Bucket público para imágenes de recetas
insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;

-- Lectura pública (el bucket es público) + escritura restringida al hogar.
-- Ruta: recipe-images/{home_id}/{archivo}
drop policy if exists recipe_images_insert on storage.objects;
create policy recipe_images_insert on storage.objects
  for insert with check (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

drop policy if exists recipe_images_update on storage.objects;
create policy recipe_images_update on storage.objects
  for update using (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

drop policy if exists recipe_images_delete on storage.objects;
create policy recipe_images_delete on storage.objects
  for delete using (
    bucket_id = 'recipe-images'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

-- Lectura: al ser bucket público, cualquiera con la URL puede ver la imagen.
-- (No hace falta política de select para lectura pública por URL.)
