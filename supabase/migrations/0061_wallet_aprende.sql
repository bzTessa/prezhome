-- ============================================================================
-- PrezWallet · Aprende: onboarding y progreso de las lecciones
-- ============================================================================
-- Idempotente. Una fila por usuario: intereses y nivel elegidos en el
-- onboarding, lecciones terminadas y racha. Es solo del usuario (no se
-- comparte con el hogar). Si no hay fila, la app muestra el onboarding.
-- ============================================================================

create table if not exists public.wallet_learner (
  user_id        uuid primary key default auth.uid()
                   references auth.users (id) on delete cascade,
  interests      text[] not null default '{}',
  level          smallint not null default 0 check (level between 0 and 2),
  completed      text[] not null default '{}',
  streak         integer not null default 0 check (streak >= 0),
  last_lesson_on date
);

alter table public.wallet_learner enable row level security;

drop policy if exists wallet_learner_own on public.wallet_learner;
create policy wallet_learner_own on public.wallet_learner
  for all using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

grant select, insert, update, delete on public.wallet_learner to authenticated;
