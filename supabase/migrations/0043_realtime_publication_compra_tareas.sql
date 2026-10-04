-- ============================================================================
-- PrezHome · Realtime para la lista de la compra y las tareas
-- ============================================================================
-- Para que un cambio hecho por un miembro del hogar (tachar un producto de la
-- lista de la compra, reclamar una tarea de la "Bolsa Común") se refleje al
-- instante en la pantalla del otro miembro, Postgres solo emite cambios en
-- tiempo real para las tablas incluidas en la publicación `supabase_realtime`.
-- Esta migración añade ahí `shopping_list_items` y `tasks`.
--
-- NO es un cambio de RLS/políticas: las políticas por hogar (home_id) ya
-- existen desde migraciones anteriores, de modo que cada cliente solo recibe
-- los cambios de SU hogar (el filtro Realtime por home_id en la app es defensa
-- en profundidad). Idempotente: comprueba pg_publication_tables antes de
-- añadir, así re-ejecutar la migración no falla si las tablas ya están.
-- ============================================================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shopping_list_items'
  ) then
    alter publication supabase_realtime add table public.shopping_list_items;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'tasks'
  ) then
    alter publication supabase_realtime add table public.tasks;
  end if;
end $$;
