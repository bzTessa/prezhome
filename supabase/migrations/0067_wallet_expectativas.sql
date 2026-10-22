-- ============================================================================
-- PrezWallet · Onboarding: qué espera de la app y si quiere aprender
-- ============================================================================
-- Idempotente. Dos columnas nuevas en wallet_learner, con valores por defecto
-- para las filas que ya existen (siguen viendo Aprende).
-- ============================================================================

alter table public.wallet_learner
  add column if not exists wants_learning boolean not null default true,
  add column if not exists expectations   text[]  not null default '{}';
