-- ============================================================================
-- PrezHome · FASE 1.5 — Control de uso mensual de IA (server-side)
-- ============================================================================
-- La lógica de límite vive en el SERVIDOR (SECURITY DEFINER). El cliente NO
-- puede modificar su límite ni su contador (subscriptions no tiene políticas de
-- escritura para el rol authenticated). Esta RPC:
--   1. Asegura que exista la fila de subscriptions del hogar.
--   2. Resetea el contador si empezó un mes nuevo (ai_period_start).
--   3. Comprueba el límite y, si hay margen, incrementa el uso y devuelve true.
-- La llaman las Edge Functions (con la service_role key) antes de usar la IA.
-- ============================================================================

-- Añadir marca de inicio de periodo para el reset mensual
alter table public.subscriptions
  add column if not exists ai_period_start date not null default date_trunc('month', now())::date;

-- ----------------------------------------------------------------------------
-- RPC: consume_ai_credit(home) -> boolean
-- Devuelve true si se pudo consumir 1 crédito de IA; false si se alcanzó el límite.
-- ----------------------------------------------------------------------------
create or replace function public.consume_ai_credit(target_home_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  sub        public.subscriptions%rowtype;
  this_month date := date_trunc('month', now())::date;
begin
  -- Asegurar que existe la fila de suscripción del hogar
  insert into public.subscriptions (home_id) values (target_home_id)
  on conflict (home_id) do nothing;

  select * into sub from public.subscriptions
  where home_id = target_home_id
  for update;

  -- Reset mensual: si estamos en un mes posterior al periodo guardado
  if sub.ai_period_start < this_month then
    update public.subscriptions
    set ai_used_this_month = 0,
        ai_period_start = this_month,
        updated_at = now()
    where home_id = target_home_id;
    sub.ai_used_this_month := 0;
  end if;

  -- Comprobar límite
  if sub.ai_used_this_month >= sub.ai_monthly_limit then
    return false;
  end if;

  -- Consumir 1 crédito
  update public.subscriptions
  set ai_used_this_month = ai_used_this_month + 1,
      updated_at = now()
  where home_id = target_home_id;

  return true;
end;
$$;

-- Solo el service_role (usado por las Edge Functions) debe ejecutar esto.
-- No lo concedemos a authenticated para que el cliente no pueda "gastar" créditos
-- directamente saltándose la Edge Function.
revoke all on function public.consume_ai_credit(uuid) from public;
grant execute on function public.consume_ai_credit(uuid) to service_role;
