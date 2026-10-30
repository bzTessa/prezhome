-- ============================================================================
-- PrezWallet · Permisos que faltaban en 0073 (y 0070)
-- ============================================================================
-- Este proyecto no da permisos por defecto a las tablas nuevas: sin GRANT, el
-- RLS ni se llega a evaluar y la app recibe 403 ("permission denied"). La
-- pantalla Bancos se quedaba cargando por eso. Las políticas ya existen.
-- ============================================================================

grant select on public.wallet_bank_apps to authenticated;
grant select, delete on public.wallet_bank_links to authenticated;
-- Mismo fallo en la nota de la cartera (0070): la app lee el último informe.
grant select on public.wallet_ai_reports to authenticated;
