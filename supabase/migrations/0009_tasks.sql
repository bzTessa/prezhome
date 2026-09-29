-- ============================================================================
-- PrezHome · Tareas del hogar (cooperativas + puntos)
-- ============================================================================
-- Tareas compartidas por el hogar. Pueden ser puntuales o recurrentes, estar
-- asignadas a un miembro o ser "de cualquiera". Al completarlas dan puntos.
-- RLS por hogar, como el resto. Idempotente.
-- ============================================================================

create table if not exists public.tasks (
  id            uuid primary key default gen_random_uuid(),
  home_id       uuid not null references public.homes (id) on delete cascade,
  title         text not null,
  notes         text,
  points        integer not null default 10,
  -- Periodicidad: 'once' (puntual) | 'daily' | 'weekly'
  recurrence    text not null default 'once'
                  check (recurrence in ('once', 'daily', 'weekly')),
  -- Asignada a un usuario concreto (null = de cualquiera del hogar)
  assigned_to   uuid references auth.users (id) on delete set null,
  due_date      date,
  is_done       boolean not null default false,
  completed_by  uuid references auth.users (id) on delete set null,
  completed_at  timestamptz,
  created_by    uuid references auth.users (id) on delete set null,
  created_at    timestamptz not null default now()
);
create index if not exists tasks_home_id_idx on public.tasks (home_id);

-- ----------------------------------------------------------------------------
-- Registro de puntos ganados (historial), para el marcador por persona.
-- ----------------------------------------------------------------------------
create table if not exists public.task_points (
  id          uuid primary key default gen_random_uuid(),
  home_id     uuid not null references public.homes (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  points      integer not null,
  task_id     uuid references public.tasks (id) on delete set null,
  created_at  timestamptz not null default now()
);
create index if not exists task_points_home_id_idx on public.task_points (home_id);
create index if not exists task_points_user_id_idx on public.task_points (user_id);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.tasks enable row level security;
alter table public.task_points enable row level security;

drop policy if exists tasks_select on public.tasks;
create policy tasks_select on public.tasks
  for select using (home_id = public.auth_home_id());

drop policy if exists tasks_insert on public.tasks;
create policy tasks_insert on public.tasks
  for insert with check (home_id = public.auth_home_id());

drop policy if exists tasks_update on public.tasks;
create policy tasks_update on public.tasks
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists tasks_delete on public.tasks;
create policy tasks_delete on public.tasks
  for delete using (home_id = public.auth_home_id());

-- task_points: el hogar puede leer; insertar solo puntos propios del hogar.
drop policy if exists task_points_select on public.task_points;
create policy task_points_select on public.task_points
  for select using (home_id = public.auth_home_id());

drop policy if exists task_points_insert on public.task_points;
create policy task_points_insert on public.task_points
  for insert with check (
    home_id = public.auth_home_id() and user_id = auth.uid()
  );

-- ----------------------------------------------------------------------------
-- GRANTs
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update, delete on public.task_points to authenticated;

-- ----------------------------------------------------------------------------
-- Vista/consulta de marcador: puntos totales por usuario del hogar.
-- (La app la calcula agregando task_points; no hace falta objeto extra.)
-- ----------------------------------------------------------------------------
