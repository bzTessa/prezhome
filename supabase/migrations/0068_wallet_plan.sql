-- ============================================================================
-- PrezWallet · Tu plan: datos de jubilación y perfil de inversor
-- ============================================================================
-- Idempotente. Una columna jsonb en wallet_learner (la fila ya es privada de
-- cada persona): birth_year, retire_age, spending, pension y risk (0 a 2).
-- ============================================================================

alter table public.wallet_learner
  add column if not exists plan jsonb not null default '{}';
