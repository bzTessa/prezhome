-- ============================================================================
-- PrezHome · Quitar a usuarios sin sesión la ejecución de funciones privilegiadas
-- ============================================================================
-- Idempotente. El asesor de seguridad de Supabase avisaba de que el rol `anon`
-- (sin iniciar sesión) puede llamar por /rest/v1/rpc/ a funciones SECURITY
-- DEFINER. Todas comprueban auth.uid() y fallan sin sesión, así que no había
-- fuga, pero no tiene sentido exponerlas:
--
-- - RPC de la app (crear/unirse a hogar, puntos, recompensas): solo para
--   usuarios con sesión (`authenticated`).
-- - Funciones de trigger (alta de perfil, RLS automática): nadie las llama por
--   la API; se quitan a `anon` y `authenticated`. Los triggers siguen
--   funcionando porque no comprueban el permiso EXECUTE al dispararse.
-- - public.auth_home_id() se deja como está: la usan las políticas RLS en
--   cualquier consulta y, sin sesión, devuelve null (no ve nada).
-- ============================================================================

revoke execute on function public.create_home_and_join(text) from public, anon;
revoke execute on function public.join_home(uuid) from public, anon;
revoke execute on function public.award_task_points(uuid, uuid) from public, anon;
revoke execute on function public.redeem_reward(uuid) from public, anon;

grant execute on function public.create_home_and_join(text) to authenticated;
grant execute on function public.join_home(uuid) to authenticated;
grant execute on function public.award_task_points(uuid, uuid) to authenticated;
grant execute on function public.redeem_reward(uuid) to authenticated;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
