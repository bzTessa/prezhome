-- ============================================================================
-- PrezHome · Foto automatica de recetas (URL externa de banco de imagenes)
-- ============================================================================
-- Anade una columna image_url (text) a public.recipes para guardar la URL
-- COMPLETA de una foto EXTERNA (banco de imagenes Pexels) obtenida al generar
-- la receta con IA.
--
-- Es DISTINTA de image_path (ver 0013_recipe_images.sql): image_path guarda la
-- RUTA dentro del bucket publico recipe-images (foto subida manualmente por la
-- usuaria), mientras que image_url guarda una URL http(s) completa a un recurso
-- externo. La foto MANUAL (image_path) tiene prioridad sobre la de Pexels.
--
-- Es un dato OPERATIVO del hogar, NO de control de acceso: NO toca RLS, policies
-- ni grants, que ya existen desde 0001. La seguridad por hogar sigue siendo
-- 'home_id = public.auth_home_id()', sin cambios.
--
-- Idempotente (add column if not exists). Las recetas existentes quedan con
-- image_url NULL (caen al placeholder cozy o a la foto de image_path si la hay),
-- sin romper datos. Sigue el estilo de 0031 (comentarios en espanol, guardas
-- idempotentes).
-- ============================================================================

-- Columna image_url para la URL externa de la foto (Pexels). NULL por defecto.
alter table public.recipes
  add column if not exists image_url text;
