-- ============================================================================
-- PrezHome · Ver los usos del mes desde la app (pantalla "Tu plan")
-- ============================================================================
-- Idempotente. Solo lectura: el cliente ve los cupos de cada plan y el uso de
-- su propio hogar. Escribir sigue siendo cosa de las Edge Functions.
--
-- NOTA DE CI: añade políticas RLS, así que el check de revisión manual fallará
-- a propósito hasta que se apruebe.
-- ============================================================================

drop policy if exists plan_quotas_select on public.plan_quotas;
create policy plan_quotas_select on public.plan_quotas
  for select to authenticated using (true);

drop policy if exists ai_usage_select on public.ai_usage;
create policy ai_usage_select on public.ai_usage
  for select to authenticated using (home_id = public.auth_home_id());

grant select on public.plan_quotas, public.ai_usage to authenticated;
