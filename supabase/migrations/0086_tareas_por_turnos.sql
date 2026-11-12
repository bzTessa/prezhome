-- Tareas por turnos: al completar una tarea que se repite y que va por
-- turnos, la app la asigna a la siguiente persona de casa (con o sin cuenta).
alter table public.tasks
  add column if not exists rotates boolean not null default false;
