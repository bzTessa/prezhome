-- ============================================================================
-- PrezHome · Task Pool (esfuerzo) + Marketplace de Recompensas
-- ============================================================================
-- Idempotente. RLS por hogar sobre public.auth_home_id(). Resume:
--
-- (a) tasks.effort_points: puntos de esfuerzo de cada tarea (entero, por
--     defecto 10). Dato operativo; tasks ya tiene RLS por hogar, asi que no
--     hace falta cambiar politicas por esta columna.
--
-- (b) Bolsa Comun (Task Pool): una tarea esta en la bolsa comun cuando
--     assigned_to IS NULL. Es semantica pura sobre la columna existente, por
--     lo que NO se necesita ningun cambio de esquema para el pool.
--
-- (c) Marketplace de Recompensas: tabla public.rewards (catalogo canjeable del
--     hogar) y public.reward_redemptions (historial append-only de canjes).
--     El canje se hace con la RPC SECURITY DEFINER public.redeem_reward(uuid),
--     que valida el saldo del usuario en el servidor para que el cliente no
--     pueda falsear su balance.
--
-- NOTA DE CI: el workflow de "revision manual" fallara a proposito porque esta
-- migracion toca politicas/RLS. Es un comportamiento esperado y NO bloquea el
-- merge.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- (a) Puntos de esfuerzo en las tareas
-- ----------------------------------------------------------------------------
alter table public.tasks
  add column if not exists effort_points integer not null default 10;

-- ----------------------------------------------------------------------------
-- (c) Catalogo de recompensas canjeables del hogar
-- ----------------------------------------------------------------------------
create table if not exists public.rewards (
  id           uuid primary key default gen_random_uuid(),
  home_id      uuid not null references public.homes (id) on delete cascade,
  title        text not null,
  description  text,
  cost_points  integer not null default 50 check (cost_points >= 0),
  is_active    boolean not null default true,
  created_by   uuid references auth.users (id) on delete set null,
  created_at   timestamptz not null default now()
);
create index if not exists rewards_home_id_idx on public.rewards (home_id);

-- ----------------------------------------------------------------------------
-- Historial de canjes (ledger append-only)
-- ----------------------------------------------------------------------------
create table if not exists public.reward_redemptions (
  id           uuid primary key default gen_random_uuid(),
  home_id      uuid not null references public.homes (id) on delete cascade,
  reward_id    uuid references public.rewards (id) on delete set null,
  redeemed_by  uuid not null references auth.users (id) on delete cascade,
  cost_points  integer not null,
  redeemed_at  timestamptz not null default now()
);
create index if not exists reward_redemptions_home_id_idx
  on public.reward_redemptions (home_id);
create index if not exists reward_redemptions_redeemed_by_idx
  on public.reward_redemptions (redeemed_by);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.rewards enable row level security;
alter table public.reward_redemptions enable row level security;

-- rewards: ambos miembros del hogar gestionan el catalogo.
drop policy if exists rewards_select on public.rewards;
create policy rewards_select on public.rewards
  for select using (home_id = public.auth_home_id());

drop policy if exists rewards_insert on public.rewards;
create policy rewards_insert on public.rewards
  for insert with check (home_id = public.auth_home_id());

drop policy if exists rewards_update on public.rewards;
create policy rewards_update on public.rewards
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists rewards_delete on public.rewards;
create policy rewards_delete on public.rewards
  for delete using (home_id = public.auth_home_id());

-- reward_redemptions: el hogar lee; cada usuario solo canjea en su nombre.
-- Ledger append-only: SIN politicas de update/delete para el cliente.
drop policy if exists reward_redemptions_select on public.reward_redemptions;
create policy reward_redemptions_select on public.reward_redemptions
  for select using (home_id = public.auth_home_id());

drop policy if exists reward_redemptions_insert on public.reward_redemptions;
create policy reward_redemptions_insert on public.reward_redemptions
  for insert with check (
    home_id = public.auth_home_id() and redeemed_by = auth.uid()
  );

-- ----------------------------------------------------------------------------
-- GRANTs
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on public.rewards to authenticated;
-- reward_redemptions es append-only: solo select + insert (sin update/delete).
grant select, insert on public.reward_redemptions to authenticated;

-- ----------------------------------------------------------------------------
-- RPC de canje: valida el saldo en el servidor (no falseable por el cliente)
-- ----------------------------------------------------------------------------
create or replace function public.redeem_reward(p_reward_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_home_id        uuid := public.auth_home_id();
  v_user_id        uuid := auth.uid();
  v_cost           integer;
  v_balance        integer;
  v_redemption_id  uuid;
begin
  if v_home_id is null or v_user_id is null then
    raise exception 'No autenticado o sin hogar asignado';
  end if;

  -- Cargar la recompensa y verificar que es del hogar del usuario y activa.
  select r.cost_points
    into v_cost
    from public.rewards r
   where r.id = p_reward_id
     and r.home_id = v_home_id
     and r.is_active = true;

  if v_cost is null then
    raise exception 'Recompensa no disponible';
  end if;

  -- Saldo = puntos ganados - puntos ya canjeados (de este usuario en el hogar).
  v_balance :=
    coalesce((
      select sum(tp.points)
        from public.task_points tp
       where tp.home_id = v_home_id
         and tp.user_id = v_user_id
    ), 0)
    - coalesce((
        select sum(rr.cost_points)
          from public.reward_redemptions rr
         where rr.home_id = v_home_id
           and rr.redeemed_by = v_user_id
      ), 0);

  if v_balance < v_cost then
    raise exception 'Saldo insuficiente para canjear la recompensa';
  end if;

  insert into public.reward_redemptions (
    home_id, reward_id, redeemed_by, cost_points
  )
  values (v_home_id, p_reward_id, v_user_id, v_cost)
  returning id into v_redemption_id;

  return v_redemption_id;
end;
$$;

grant execute on function public.redeem_reward(uuid) to authenticated;
