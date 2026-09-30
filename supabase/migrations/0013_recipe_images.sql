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

-- Escritura: cualquier usuario AUTENTICADO puede subir/gestionar imágenes de
-- recetas. La imagen de un plato no es dato sensible; el dato protegido (la
-- receta) sigue con RLS por hogar. Esto evita problemas de evaluación de
-- auth_home_id() dentro del contexto de Storage.
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

-- Lectura: al ser bucket público, cualquiera con la URL puede ver la imagen.
