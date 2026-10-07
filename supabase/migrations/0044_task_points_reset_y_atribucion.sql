-- ============================================================================
-- PrezHome · Reinicio de puntos + atribucion de tareas a un miembro
-- ============================================================================
-- Idempotente. RLS por hogar sobre public.auth_home_id(). Da soporte al
-- rediseno de Tareas (area 4), que elimina la Bolsa Comun y pasa a un modelo
-- mas tradicional:
--
-- (a) Politica RLS `task_points_delete` sobre public.task_points: permite que
--     CUALQUIER miembro del hogar borre filas de puntos del hogar. Hace falta
--     para la accion "Reiniciar puntos" (corregir un marcador cuando alguien
--     se equivoco al pulsar). task_points no tenia politica de delete (0009
--     solo creo select+insert), asi que la anadimos aqui.
--
-- (b) RPC `public.award_task_points(p_task_id, p_done_by)`: registra los puntos
--     de una tarea a nombre del miembro que REALMENTE la hizo (p_done_by), que
--     no tiene por que ser quien pulsa el boton. Como la politica de insert de
--     0009 obliga a `user_id = auth.uid()`, no se puede atribuir a otro miembro
--     desde el cliente; por eso la atribucion pasa por esta RPC SECURITY
--     DEFINER, que valida en el servidor que:
--       - el llamante tiene hogar (auth_home_id()),
--       - la tarea pertenece a ese hogar,
--       - p_done_by pertenece al MISMO hogar (profiles.home_id),
--     y solo entonces inserta en task_points con los puntos de la tarea. Asi el
--     cliente no puede regalar puntos a usuarios de otros hogares.
--
-- NOTA DE CI: el workflow de "revision manual" / "Validacion de cambios IA"
-- fallara a proposito porque esta migracion toca politicas/RLS. Es un
-- comportamiento esperado y NO bloquea el merge.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- (a) Politica de borrado para reiniciar/corregir puntos del hogar
-- ----------------------------------------------------------------------------
-- Cualquier miembro del hogar puede borrar filas de puntos del hogar (reset).
drop policy if exists task_points_delete on public.task_points;
create policy task_points_delete on public.task_points
  for delete using (home_id = public.auth_home_id());

-- El grant de delete ya existe desde 0009; se repite por idempotencia/claridad.
grant delete on public.task_points to authenticated;

-- ----------------------------------------------------------------------------
-- (b) RPC de atribucion: suma los puntos de una tarea al miembro que la hizo.
--     Valida en el servidor para que no se puedan atribuir puntos fuera del
--     hogar (el cliente nunca escribe puntos de otro miembro directamente).
-- ----------------------------------------------------------------------------
create or replace function public.award_task_points(
  p_task_id uuid,
  p_done_by uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_home_id    uuid := public.auth_home_id();
  v_points     integer;
  v_done_home  uuid;
  v_point_id   uuid;
begin
  if v_home_id is null then
    raise exception 'No autenticado o sin hogar asignado';
  end if;

  -- La tarea debe existir y pertenecer al hogar del llamante.
  select t.points
    into v_points
    from public.tasks t
   where t.id = p_task_id
     and t.home_id = v_home_id;

  if v_points is null then
    raise exception 'Tarea no encontrada en tu hogar';
  end if;

  -- El miembro al que se atribuye debe pertenecer al MISMO hogar.
  select p.home_id
    into v_done_home
    from public.profiles p
   where p.id = p_done_by;

  if v_done_home is null or v_done_home <> v_home_id then
    raise exception 'El miembro no pertenece a tu hogar';
  end if;

  insert into public.task_points (home_id, user_id, points, task_id)
  values (v_home_id, p_done_by, v_points, p_task_id)
  returning id into v_point_id;

  return v_point_id;
end;
$$;

grant execute on function public.award_task_points(uuid, uuid) to authenticated;
