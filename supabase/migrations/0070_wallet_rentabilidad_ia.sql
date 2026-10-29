-- ============================================================================
-- PrezWallet · Rentabilidad completa y análisis de cartera con IA
-- ============================================================================
-- Idempotente.
-- wallet_trades.fee / tax: comisión e impuestos (retenciones) de cada compra o
--   venta, para la ganancia neta y la TIR.
-- wallet_ai_reports: cada análisis de cartera con IA (nota 0-100 y texto). Lo
--   escribe solo la función wallet-analysis con la clave de servicio; cada
--   persona lee los suyos. También sirve para contar el cupo del mes, porque
--   en PrezWallet se puede estar sin hogar.
-- plan_quotas: cupo mensual de wallet_analysis.
-- ============================================================================

alter table public.wallet_trades
  add column if not exists fee numeric not null default 0 check (fee >= 0),
  add column if not exists tax numeric not null default 0 check (tax >= 0);

create table if not exists public.wallet_ai_reports (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users (id) on delete cascade,
  score       integer not null check (score between 0 and 100),
  report      jsonb not null,
  created_at  timestamptz not null default now()
);
create index if not exists wallet_ai_reports_owner_idx
  on public.wallet_ai_reports (owner_id, created_at desc);

alter table public.wallet_ai_reports enable row level security;

drop policy if exists wallet_ai_reports_select on public.wallet_ai_reports;
create policy wallet_ai_reports_select on public.wallet_ai_reports
  for select using (owner_id = auth.uid());

insert into public.plan_quotas (plan, feature, monthly_limit) values
  ('free', 'wallet_analysis', 3),
  ('pro',  'wallet_analysis', 20)
on conflict (plan, feature) do nothing;
