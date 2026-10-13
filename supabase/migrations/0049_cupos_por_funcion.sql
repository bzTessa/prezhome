-- ============================================================================
-- PrezHome · Cupos de IA por función y plan (bases del modelo gratis / Pro)
-- ============================================================================
-- Idempotente. Antes había una sola bolsa de 20 usos al mes por hogar para
-- todo. Ahora cada función tiene su cupo según el plan, en una tabla
-- (plan_quotas): cambiar un cupo es editar una fila, sin publicar la app.
-- El uso se cuenta por hogar, función y mes en ai_usage.
--
-- consume_ai_credit(hogar, función) cobra un uso si queda cupo;
-- refund_ai_credit(hogar, función) lo devuelve cuando la petición falla.
-- La versión antigua consume_ai_credit(hogar) se deja hasta que todas las
-- funciones desplegadas usen la nueva.
--
-- NOTA DE CI: activa RLS y cambia grants, así que el check de revisión manual
-- fallará a propósito hasta que se apruebe.
-- ============================================================================

create table if not exists public.plan_quotas (
  plan          text not null check (plan in ('free', 'pro')),
  feature       text not null,
  monthly_limit integer not null check (monthly_limit >= 0),
  primary key (plan, feature)
);

insert into public.plan_quotas (plan, feature, monthly_limit) values
  ('free', 'scan_ticket', 15),
  ('free', 'recipes',     15),
  ('free', 'meal_photo',  10),
  ('free', 'import_link', 10),
  ('pro',  'scan_ticket', 100),
  ('pro',  'recipes',     100),
  ('pro',  'meal_photo',  100),
  ('pro',  'import_link', 300)
on conflict (plan, feature) do nothing;

create table if not exists public.ai_usage (
  home_id      uuid not null references public.homes (id) on delete cascade,
  feature      text not null,
  period_start date not null,
  used         integer not null default 0 check (used >= 0),
  primary key (home_id, feature, period_start)
);

-- Solo las Edge Functions (service_role) leen y escriben estas tablas.
alter table public.plan_quotas enable row level security;
alter table public.ai_usage enable row level security;

create or replace function public.consume_ai_credit(
  target_home_id uuid,
  target_feature text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  lim     integer;
  charged boolean;
begin
  insert into public.subscriptions (home_id) values (target_home_id)
  on conflict (home_id) do nothing;

  select q.monthly_limit into lim
  from public.subscriptions s
  join public.plan_quotas q on q.plan = s.plan and q.feature = target_feature
  where s.home_id = target_home_id;

  -- Función sin cupo definido o cupo 0: no se cobra nada.
  if coalesce(lim, 0) <= 0 then
    return false;
  end if;

  -- Una sola sentencia: dos peticiones a la vez no pueden pasarse del cupo.
  insert into public.ai_usage as u (home_id, feature, period_start, used)
  values (target_home_id, target_feature, date_trunc('month', now())::date, 1)
  on conflict (home_id, feature, period_start)
  do update set used = u.used + 1
  where u.used < lim
  returning true into charged;

  return coalesce(charged, false);
end;
$$;

create or replace function public.refund_ai_credit(
  target_home_id uuid,
  target_feature text
)
returns void
language sql
security definer
set search_path = public
as $$
  update public.ai_usage
  set used = greatest(used - 1, 0)
  where home_id = target_home_id
    and feature = target_feature
    and period_start = date_trunc('month', now())::date;
$$;

revoke all on function public.consume_ai_credit(uuid, text) from public, anon, authenticated;
revoke all on function public.refund_ai_credit(uuid, text) from public, anon, authenticated;
grant execute on function public.consume_ai_credit(uuid, text) to service_role;
grant execute on function public.refund_ai_credit(uuid, text) to service_role;
