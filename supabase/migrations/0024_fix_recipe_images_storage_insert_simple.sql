-- ============================================================================
-- PrezHome · Arreglo del 403 al subir fotos de recetas (RLS de Storage), v5
-- ============================================================================
-- Al guardar una receta con foto, Supabase Storage sigue devolviendo:
--     new row violates row-level security policy (statusCode 403, Unauthorized)
-- La subida real (lib/add_recipe_screen.dart, _uploadImageIfAny) hace:
--     storage.from('recipe-images').uploadBinary('{homeId}/<timestamp>.<ext>',
--       bytes, FileOptions(contentType, upsert: true))
-- sobre el bucket PUBLICO recipe-images.
--
-- Historico de intentos fallidos (el 403 persistio en TODOS):
--   0013: insert/update/delete to authenticated + bucket_id = 'recipe-images'.
--   0021: re-asegura lo mismo (to authenticated + bucket_id).
--   0022: quita `to authenticated`, deja solo bucket_id.
--   0023: copia el patron del bucket tickets:
--           bucket_id = 'recipe-images'
--           and (storage.foldername(name))[1] = public.auth_home_id()::text
--         sin `to authenticated`, mas grant base sobre storage.objects.
--
-- IMPORTANTE · lectura honesta del historico (por que esta migracion NO es un
-- simple "volver a 0021"):
--   La policy minima `for insert to authenticated with check (bucket_id =
--   'recipe-images')` ya la desplegaron 0013 y 0021, y bajo ella el 403 YA
--   ocurria. El GRANT sobre storage.objects ya se anadio en 0023 y el 403
--   persistio. Es decir, (policy de 0021) + (grant de 0023) ya coexistieron en
--   produccion mientras el 403 seguia. Por tanto, recrear SOLO esas piezas no
--   aporta evidencia nueva de que resuelva el problema. Esta migracion anade un
--   elemento genuinamente distinto (limpieza AMPLIA de politicas, abajo) y, muy
--   importante, se acompana de un diagnostico del lado de la app (ver nota al
--   final) porque la causa mas probable del 403 parece estar FUERA de estas
--   migraciones.
--
-- Dato clave que debilita la hipotesis "la sesion no esta autenticada / rol
-- anon": la MISMA pantalla (add_recipe_screen.dart, _save) hace un INSERT en la
-- tabla public.recipes protegida por RLS por hogar (home_id =
-- public.auth_home_id()) y ESO SI funciona (la receta se guarda; solo falla la
-- foto). Si la sesion no fuese `authenticated` y auth.uid() fuese null, el
-- INSERT en recipes tambien fallaria. Luego, en el momento de la subida, el rol
-- efectivo es authenticated y auth.uid() resuelve. Esto hace improbable que la
-- causa sea el rol o la sesion.
--
-- Por que la comparacion con el bucket tickets NO es fiable (descartamos 0023):
--   La premisa de 0023 era "tickets funciona, replico su patron". Pero tickets
--   NUNCA sube una imagen de verdad: en lib/scan_ticket_screen.dart la insercion
--   usa 'storage_path': '' con el comentario "(futuro: subir la imagen al
--   bucket)". Las politicas de storage de tickets basadas en foldername +
--   auth_home_id() JAMAS se han ejercitado en un INSERT real de storage.objects.
--   Copiar ese patron (0023) carecia de fundamento. Ademas, depender de
--   auth_home_id() dentro del contexto de una request de Storage es fragil: si
--   no resuelve igual que en el contexto de public, la condicion da false y
--   Storage responde 403. Para un bucket PUBLICO de imagenes NO sensibles no
--   hace falta esa comprobacion por hogar.
--
-- Arreglo que aplica esta migracion:
--   1) LIMPIEZA AMPLIA (elemento nuevo frente a intentos previos): ademas de
--      soltar las politicas conocidas recipe_images_insert/update/delete, se
--      recorren TODAS las politicas definidas sobre storage.objects cuya
--      definicion (qual o with_check) mencione 'recipe-images' y se eliminan.
--      Esto cubre el caso de que en la BD real de la usuaria haya quedado alguna
--      politica con OTRO nombre (creada a mano o por un intento no versionado en
--      el repo) que este imponiendo una condicion que provoca el 403, o una
--      policy "owner based" por defecto. Los intentos anteriores solo soltaban
--      los tres nombres fijos, asi que una politica huerfana con otro nombre
--      habria sobrevivido a 0013..0023 y seguiria bloqueando.
--   2) Se crea UNA version limpia y consistente de insert/update/delete para el
--      rol authenticated comprobando solo el bucket. update/delete usan la misma
--      condicion para que upsert:true (que puede sobrescribir un objeto ya
--      existente) no vuelva a dar 403.
--   3) Se re-asegura el bucket publico y se mantiene el GRANT base.
--
-- Esta migracion es idempotente (drop policy if exists + create; bucle de
-- limpieza por catalogo; on conflict do nothing en el bucket; grant repetible).
-- No modifica ninguna migracion previa (0001-0023 son inmutables) ni borra nada
-- mas que politicas de storage.objects que referencian 'recipe-images'. No
-- contiene DROP TABLE ni DROP COLUMN.
-- ============================================================================

-- 1a) Eliminar las politicas conocidas por nombre (idempotente).
drop policy if exists recipe_images_insert on storage.objects;
drop policy if exists recipe_images_update on storage.objects;
drop policy if exists recipe_images_delete on storage.objects;

-- 1b) LIMPIEZA AMPLIA: eliminar cualquier OTRA politica sobre storage.objects
-- cuya definicion mencione el bucket recipe-images, sea cual sea su nombre.
-- Cubre politicas huerfanas de intentos no versionados o creadas a mano en la
-- BD real que los drops por nombre de 0013..0023 nunca tocaron y que podrian
-- estar causando el 403. Solo afecta a politicas que referencian este bucket.
do $$
declare
  pol record;
begin
  for pol in
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname not in (
        'recipe_images_insert', 'recipe_images_update', 'recipe_images_delete'
      )
      and (
        coalesce(qual, '') like '%recipe-images%'
        or coalesce(with_check, '') like '%recipe-images%'
      )
  loop
    execute format(
      'drop policy if exists %I on storage.objects', pol.policyname
    );
  end loop;
end $$;

-- 2) INSERT: cualquier usuario autenticado puede subir imagenes al bucket
-- publico recipe-images. Solo se comprueba el bucket (nada de auth_home_id en
-- el contexto de storage).
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

-- 3) Re-asegurar el bucket publico de forma idempotente por si no existiera. Al
-- ser publico, la lectura no necesita politica de SELECT (igual que en 0013).
insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;

-- GRANT base sobre storage.objects para el rol authenticated. Las politicas RLS
-- pueden permitir la operacion, pero sin permiso de tabla la operacion falla
-- igual. Este GRANT es seguro: el acceso real sigue limitado por las policies
-- RLS de arriba (bucket_id = 'recipe-images').
grant select, insert, update, delete on storage.objects to authenticated;

-- ============================================================================
-- NOTA TECNICA (por que el 403 puede NO depender de estas migraciones)
-- ----------------------------------------------------------------------------
-- Como el INSERT en public.recipes (misma pantalla, misma sesion) SI funciona,
-- el rol efectivo es authenticated y auth.uid() resuelve. Con eso, la policy de
-- INSERT de arriba (que solo exige bucket_id) deberia permitir la subida. Si
-- aun asi vuelve el 403, la causa mas probable esta FUERA de lo que este repo
-- puede cambiar via migraciones, por ejemplo:
--   - Que las politicas 0013/0021/0022/0023 NUNCA llegaran a aplicarse en la BD
--     real de la usuaria (p. ej. un deploy fallido), de modo que el estado real
--     de storage.objects no es el que el repo asume. Esta migracion, al aplicar
--     la limpieza amplia y recrear las politicas, deberia corregir ese desfase.
--   - Una politica RESTRICTIVE o un trigger del lado GESTIONADO de Supabase
--     sobre storage.objects que el repo no versiona y que ninguna migracion de
--     aqui puede ver ni soltar (una policy PERMISSIVE nueva no anula una
--     RESTRICTIVE existente).
-- Por eso, en paralelo a esta migracion, se ha mejorado el manejo de errores de
-- la subida en lib/add_recipe_screen.dart para capturar y mostrar el detalle
-- REAL del StorageException (message, statusCode y, si existe, error/cuerpo).
-- Si el 403 reaparece tras desplegar, ese detalle dira exactamente que condicion
-- o politica lo provoca y permitira actuar con datos en vez de a ciegas.
-- ============================================================================
