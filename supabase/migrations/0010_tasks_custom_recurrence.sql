-- ============================================================================
-- PrezHome · Recurrencia personalizada de tareas
-- ============================================================================
-- Amplía la recurrencia más allá de once/daily/weekly:
--   - 'custom_interval': cada N días o semanas (interval_count + interval_unit)
--   - 'custom_weekdays': días concretos de la semana (weekdays: array 1..7, L..D)
-- Se mantienen las opciones simples por compatibilidad.
-- Idempotente.
-- ============================================================================

-- Permitir los nuevos valores de recurrence.
alter table public.tasks drop constraint if exists tasks_recurrence_check;
alter table public.tasks
  add constraint tasks_recurrence_check
  check (recurrence in ('once', 'daily', 'weekly', 'custom_interval', 'custom_weekdays'));

-- Cada N unidades (para custom_interval)
alter table public.tasks
  add column if not exists interval_count integer;      -- ej. 3
alter table public.tasks
  add column if not exists interval_unit text
  check (interval_unit in ('day', 'week'));             -- 'day' | 'week'

-- Días de la semana (para custom_weekdays): 1=Lun .. 7=Dom
alter table public.tasks
  add column if not exists weekdays smallint[];
