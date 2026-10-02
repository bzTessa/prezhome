-- ============================================================================
-- PrezHome · Reprogramacion real de tareas recurrentes
-- ============================================================================
-- Hasta ahora las tareas recurrentes solo sumaban puntos al completarlas pero
-- nunca "avanzaban" de fecha, asi que no desaparecian de hoy ni reaparecian en
-- su proxima ocurrencia. Esta migracion anade el soporte de datos para que la
-- app pueda reprogramar la tarea sobre la MISMA fila:
--   - next_due:          proxima fecha en la que la tarea debe volver a
--                        aparecer como pendiente. Para 'once' coincide con la
--                        fecha limite (si la hay); para recurrentes la app la
--                        avanza al completar segun la regla de recurrencia.
--   - last_completed_at: ultima vez que se completo (para historico/depuracion;
--                        completed_at ya existe pero lo dejamos explicito para
--                        no pisar su semantica actual).
--
-- Mantiene compatibilidad con is_done/completed_at/completed_by ya existentes
-- (0009). NO modifica 0009/0010/0011. Idempotente (add column if not exists).
-- No toca RLS, policies ni grants: las columnas nuevas viven en public.tasks,
-- cuya seguridad por hogar ya esta definida en 0009 y no cambia aqui.
--
-- CI: nombre NNNN_nombre.sql y parentesis balanceados fuera de comentarios.
-- ============================================================================

-- Columnas nuevas en public.tasks.
alter table public.tasks
  add column if not exists next_due date;
alter table public.tasks
  add column if not exists last_completed_at timestamptz;

-- Backfill razonable para filas existentes:
--   - Tareas puntuales ('once'): su proxima (y unica) aparicion es su fecha
--     limite, si la tienen; si no, se deja en null (sin fecha concreta).
--   - Tareas recurrentes sin next_due: arrancan en su due_date o, en su
--     defecto, hoy, para que entren en el flujo de reprogramacion.
update public.tasks
  set next_due = due_date
  where next_due is null
    and recurrence = 'once';

update public.tasks
  set next_due = coalesce(due_date, current_date)
  where next_due is null
    and recurrence <> 'once';

-- Indice para filtrar rapido las tareas por su proxima fecha (hoy / mes).
create index if not exists tasks_next_due_idx on public.tasks (next_due);
