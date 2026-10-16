-- Personas de casa sin cuenta (p. ej. un niño o alguien que no usa la app).
-- Se pueden asignar a tareas, marcar como quien la hizo y ganar puntos.
--
-- (a) Tabla home_people, visible y editable solo por el propio hogar.
-- (b) tasks.assigned_to / tasks.completed_by / task_points.user_id dejan de
--     apuntar a auth.users: ahora guardan el id de un miembro con cuenta O el
--     de una persona sin cuenta. Dos triggers mantienen lo que hacían las FK:
--     al borrar una cuenta o una persona se limpian sus tareas y puntos.
-- (c) award_task_points acepta también a las personas sin cuenta del hogar.

-- (a) ------------------------------------------------------------------------
create table if not exists public.home_people (
  id         uuid primary key default gen_random_uuid(),
  home_id    uuid not null references public.homes (id) on delete cascade,
  name       text not null check (char_length(btrim(name)) between 1 and 40),
  created_at timestamptz not null default now()
);

create index if not exists home_people_home_id_idx on public.home_people (home_id);

alter table public.home_people enable row level security;

drop policy if exists home_people_select on public.home_people;
create policy home_people_select on public.home_people
  for select using (home_id = public.auth_home_id());

drop policy if exists home_people_insert on public.home_people;
create policy home_people_insert on public.home_people
  for insert with check (home_id = public.auth_home_id());

drop policy if exists home_people_update on public.home_people;
create policy home_people_update on public.home_people
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists home_people_delete on public.home_people;
create policy home_people_delete on public.home_people
  for delete using (home_id = public.auth_home_id());

grant select, insert, update, delete on public.home_people to authenticated;

-- (b) ------------------------------------------------------------------------
alter table public.tasks drop constraint if exists tasks_assigned_to_fkey;
alter table public.tasks drop constraint if exists tasks_completed_by_fkey;
alter table public.task_points drop constraint if exists task_points_user_id_fkey;

-- Mismo efecto que las FK quitadas: tareas sin responsable y puntos borrados.
create or replace function public.forget_task_person()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.tasks set assigned_to = null where assigned_to = old.id;
  update public.tasks set completed_by = null where completed_by = old.id;
  delete from public.task_points where user_id = old.id;
  return old;
end;
$$;

revoke execute on function public.forget_task_person() from public, anon, authenticated;

drop trigger if exists home_people_forget on public.home_people;
create trigger home_people_forget
  after delete on public.home_people
  for each row execute function public.forget_task_person();

drop trigger if exists auth_users_forget_tasks on auth.users;
create trigger auth_users_forget_tasks
  after delete on auth.users
  for each row execute function public.forget_task_person();

-- (c) ------------------------------------------------------------------------
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
  v_point_id   uuid;
begin
  if v_home_id is null then
    raise exception 'No autenticado o sin hogar asignado';
  end if;

  select t.points
    into v_points
    from public.tasks t
   where t.id = p_task_id
     and t.home_id = v_home_id;

  if v_points is null then
    raise exception 'Tarea no encontrada en tu hogar';
  end if;

  -- Quien la hizo debe ser del MISMO hogar: miembro con cuenta o persona sin cuenta.
  if not exists (
       select 1 from public.profiles p
        where p.id = p_done_by and p.home_id = v_home_id)
     and not exists (
       select 1 from public.home_people h
        where h.id = p_done_by and h.home_id = v_home_id) then
    raise exception 'El miembro no pertenece a tu hogar';
  end if;

  insert into public.task_points (home_id, user_id, points, task_id)
  values (v_home_id, p_done_by, v_points, p_task_id)
  returning id into v_point_id;

  return v_point_id;
end;
$$;

revoke execute on function public.award_task_points(uuid, uuid) from public, anon;
grant execute on function public.award_task_points(uuid, uuid) to authenticated;
