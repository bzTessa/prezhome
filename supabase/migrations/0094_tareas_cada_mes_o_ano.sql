-- Mantenimiento de la casa: tareas que vuelven cada N meses o años (filtros,
-- caldera, ITV, colchón...). Amplía interval_unit de ('day','week') a
-- ('day','week','month','year'). Idempotente.
do $$
declare
  c record;
begin
  -- La restricción de 0010 se creó sin nombre: se busca por su definición.
  for c in
    select con.conname
    from pg_constraint con
    where con.conrelid = 'public.tasks'::regclass
      and con.contype = 'c'
      and pg_get_constraintdef(con.oid) ilike '%interval_unit%'
  loop
    execute format('alter table public.tasks drop constraint %I', c.conname);
  end loop;
end $$;

alter table public.tasks
  add constraint tasks_interval_unit_check
  check (interval_unit in ('day', 'week', 'month', 'year'));
