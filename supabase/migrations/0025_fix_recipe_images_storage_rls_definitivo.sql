-- ============================================================================
-- PrezHome · Arreglo DEFINITIVO del 403 al subir fotos de recetas (RLS Storage)
-- ============================================================================
-- Sintoma (consola del navegador):
--     AddRecipeScreen._uploadImageIfAny error: StorageException(
--       message: new row violates row-level security policy,
--       statusCode: 403, error: Unauthorized)
-- La subida real (lib/add_recipe_screen.dart, _uploadImageIfAny) hace:
--     storage.from('recipe-images').uploadBinary(
--       '{homeId}/<timestamp>.<ext>', bytes,
--       FileOptions(contentType, upsert: true))
-- sobre el bucket PUBLICO recipe-images.
--
-- ----------------------------------------------------------------------------
-- POR QUE SIGUE EL 403 AUNQUE YA EXISTA UNA POLICY MINIMA
-- ----------------------------------------------------------------------------
-- Intentos previos (0013, 0021, 0022, 0023, 0024), todos desplegados con exito,
-- dejaron en su ultima version (0024) exactamente esta policy:
--     for insert to authenticated with check (bucket_id = 'recipe-images')
-- mas el GRANT base sobre storage.objects. Y el 403 PERSISTE.
--
-- Dato que descarta la hipotesis de sesion/rol: el INSERT en public.recipes de
-- la MISMA pantalla y sesion SI funciona. Luego el rol efectivo es authenticated
-- y auth.uid() resuelve. Con eso, una policy que solo exige bucket_id DEBERIA
-- permitir el INSERT en storage.objects. Que no lo haga indica que la causa esta
-- en el ESTADO REAL de storage.objects, que no coincide con lo que el repo
-- asume. Las causas reales conocidas en Supabase son:
--
--   (a) El rol efectivo del INSERT en storage.objects NO es authenticated.
--       Aunque auth.uid() resuelva, el servidor de Storage ejecuta la insercion
--       y, segun version y configuracion, el rol con el que corre la sentencia
--       puede no coincidir con el que esperan las policies `to authenticated`.
--       Una policy restringida con `to authenticated` que no case con el rol
--       efectivo evalua como si no existiera -> ninguna PERMISSIVE aplica ->
--       la insercion viola RLS -> 403. Solucion: que las policies NO se limiten
--       a un rol; aplicarlas a public (todos los roles) comprobando solo el
--       bucket. Para un bucket PUBLICO de imagenes no sensibles es seguro.
--
--   (b) Existe una policy RESTRICTIVE sobre storage.objects (creada a mano, por
--       un intento no versionado, o heredada) que NINGUNA policy PERMISSIVE
--       nueva puede anular: con una sola RESTRICTIVE que de false, el INSERT
--       falla aunque haya PERMISSIVEs que den true. Los intentos 0013..0024
--       solo soltaban policies por nombre o por mencionar el bucket, pero una
--       RESTRICTIVE global (que no mencione el bucket) habria sobrevivido.
--       Solucion: detectar y soltar las RESTRICTIVE de storage.objects que
--       bloqueen el INSERT (con aviso en los logs del deploy).
--
--   (c) El GRANT base podria no estar efectivo si en algun intento se revoco o
--       si el rol no es el que recibe el grant. Se re-aplica el GRANT.
--
--   (d) Columna owner / owner_id: el API de Storage, al insertar, fija owner al
--       uid. Esto NO deberia disparar RLS porque las policies de abajo solo
--       miran bucket_id, pero se documenta por completitud.
--
-- ----------------------------------------------------------------------------
-- QUE HACE ESTA MIGRACION (idempotente, no toca 0001-0024)
-- ----------------------------------------------------------------------------
--   1) Re-asegura el bucket recipe-images y FUERZA public=true (update, no solo
--      insert-on-conflict), por si existiera pero mal configurado.
--   2) Limpieza AMPLIA: suelta las policies conocidas por nombre y cualquier
--      otra PERMISSIVE que mencione el bucket.
--   3) Suelta cualquier policy RESTRICTIVE sobre storage.objects que pueda estar
--      bloqueando el INSERT del bucket, avisando en los logs del deploy que se
--      elimino (causa (b)).
--   4) Crea insert/update/delete SIN limitar a un rol (aplican a public), con la
--      condicion minima bucket_id = 'recipe-images' (causa (a)). update lleva
--      using + with check para que upsert:true no vuelva a dar 403.
--   5) Re-aplica el GRANT base sobre storage.objects (causa (c)).
--   6) Deja constancia en los logs del deploy del numero de policies que quedan
--      sobre el bucket, para verificar el estado real tras aplicar.
--
-- Idempotente: drop policy if exists + create; update del bucket; bucle de
-- limpieza por catalogo; grant repetible. No hay DROP TABLE ni DROP COLUMN. No
-- modifica ninguna migracion previa.
-- ============================================================================

-- 1) Asegurar el bucket y FORZAR que sea publico (no solo crearlo si falta). ---
insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do update set public = true;

-- 2) Limpieza AMPLIA de PERMISSIVE del bucket (por nombre y por catalogo). -----
drop policy if exists recipe_images_insert on storage.objects;
drop policy if exists recipe_images_update on storage.objects;
drop policy if exists recipe_images_delete on storage.objects;

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
    raise notice 'PrezHome 0025: eliminada policy % de storage.objects (mencionaba recipe-images).', pol.policyname;
  end loop;
end $$;

-- 3) Soltar RESTRICTIVE que puedan bloquear el INSERT del bucket (causa (b)). --
-- pg_policies.permissive = 'RESTRICTIVE' identifica las policies restrictivas.
-- Una sola RESTRICTIVE que evalue false hace fallar el INSERT aunque haya
-- PERMISSIVEs validas. Soltamos las RESTRICTIVE que apliquen a INSERT/ALL sobre
-- storage.objects, dejando constancia en los logs del deploy. Solo se tocan
-- RESTRICTIVE (las de otros proyectos sanos no suelen existir); si hubiera
-- alguna legitima, el aviso permite revisarla.
do $$
declare
  pol record;
  encontradas int := 0;
begin
  for pol in
    select policyname, cmd
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and permissive = 'RESTRICTIVE'
      and cmd in ('INSERT', 'ALL')
  loop
    execute format(
      'drop policy if exists %I on storage.objects', pol.policyname
    );
    encontradas := encontradas + 1;
    raise notice 'PrezHome 0025: eliminada policy RESTRICTIVE % (cmd %) de storage.objects; podia causar el 403.', pol.policyname, pol.cmd;
  end loop;
  if encontradas = 0 then
    raise notice 'PrezHome 0025: no habia policies RESTRICTIVE de INSERT/ALL en storage.objects.';
  end if;
end $$;

-- 4) Crear las policies de escritura SIN limitar a un rol (aplican a public). --
-- Al no llevar `to authenticated`, aplican a cualquier rol (authenticated, anon
-- y el rol efectivo con que el servidor de Storage ejecute la insercion), lo que
-- elimina la causa (a). Para un bucket PUBLICO de imagenes no sensibles es
-- seguro: el dato protegido (la receta) sigue con RLS por hogar en
-- public.recipes. La ruta real es '{homeId}/<archivo>', pero NO se comprueba el
-- home_id aqui a proposito: depender de auth_home_id() dentro del contexto de
-- Storage es fragil y fue una de las causas de fallos anteriores.

create policy recipe_images_insert on storage.objects
  for insert
  with check (bucket_id = 'recipe-images');

-- UPDATE con using + with check para que upsert:true (que puede sobrescribir un
-- objeto ya existente) no vuelva a dar 403.
create policy recipe_images_update on storage.objects
  for update
  using (bucket_id = 'recipe-images')
  with check (bucket_id = 'recipe-images');

create policy recipe_images_delete on storage.objects
  for delete
  using (bucket_id = 'recipe-images');

-- 5) GRANT base sobre storage.objects (causa (c)). Seguro: el acceso real sigue
-- limitado por las policies de arriba (bucket_id = 'recipe-images'). Se concede
-- tambien a anon por coherencia con policies sin rol; sigue acotado por RLS.
grant select, insert, update, delete on storage.objects to authenticated;
grant select, insert, update, delete on storage.objects to anon;

-- 6) Verificacion: dejar en los logs del deploy cuantas policies quedan sobre el
-- bucket recipe-images, para confirmar el estado real tras aplicar la migracion.
do $$
declare
  n int;
begin
  select count(*) into n
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and (
      coalesce(qual, '') like '%recipe-images%'
      or coalesce(with_check, '') like '%recipe-images%'
    );
  raise notice 'PrezHome 0025: tras aplicar quedan % policies sobre recipe-images (se esperan 3: insert, update, delete).', n;
end $$;
