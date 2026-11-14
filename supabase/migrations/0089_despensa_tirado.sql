-- Lo que se tira y lo que se salva.
--
-- pantry_log ya guarda lo que sale de la despensa (consumido o en una receta).
-- (a) Nuevo motivo 'tirado': lo que se va a la basura desde "Revisar despensa".
-- (b) rescued: se gastó cuando estaba a punto de caducar. Con las dos cosas el
--     resumen del mes cuenta lo aprovechado y lo tirado.

alter table public.pantry_log
  drop constraint if exists pantry_log_reason_check;
alter table public.pantry_log
  add constraint pantry_log_reason_check
  check (reason in ('consumido', 'receta', 'tirado'));

alter table public.pantry_log
  add column if not exists rescued boolean not null default false;
