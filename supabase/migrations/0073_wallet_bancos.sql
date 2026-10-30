-- ============================================================================
-- PrezWallet · Bancos conectados (open banking con Enable Banking)
-- ============================================================================
-- Cada usuario registra su propia aplicación de Enable Banking en modo
-- personal (gratis, solo sus cuentas) y guarda en la app su Application ID y
-- su clave privada. La clave va cifrada en Vault y solo la lee la Edge
-- Function wallet-bank con la clave de servicio.
--
-- wallet_bank_apps:  aplicación de cada usuario (id + referencia al secreto).
-- wallet_bank_auth:  autorizaciones en curso (state -> usuario), solo servidor.
-- wallet_bank_links: bancos conectados (sesión de Enable Banking y caducidad).
-- wallet_accounts.bank_uid/bank_ref / wallet_transactions.external_id: enlazan cuentas
-- y movimientos con los del banco para no duplicarlos.
-- ============================================================================

create table if not exists public.wallet_bank_apps (
  owner_id      uuid primary key default auth.uid()
                  references auth.users (id) on delete cascade,
  app_id        text not null,
  key_secret_id uuid not null,
  created_at    timestamptz not null default now()
);
alter table public.wallet_bank_apps enable row level security;
-- El usuario solo puede ver si tiene aplicación; la escribe la función.
create policy wallet_bank_apps_select on public.wallet_bank_apps
  for select using (owner_id = auth.uid());

create table if not exists public.wallet_bank_auth (
  state         uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references auth.users (id) on delete cascade,
  aspsp_name    text not null,
  aspsp_country text not null,
  created_at    timestamptz not null default now()
);
-- Sin políticas: solo la clave de servicio.
alter table public.wallet_bank_auth enable row level security;

create table if not exists public.wallet_bank_links (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null default auth.uid()
                  references auth.users (id) on delete cascade,
  session_id    text not null,
  aspsp_name    text not null,
  aspsp_country text not null,
  valid_until   timestamptz,
  last_sync     timestamptz,
  created_at    timestamptz not null default now()
);
create index if not exists wallet_bank_links_owner_idx
  on public.wallet_bank_links (owner_id);
alter table public.wallet_bank_links enable row level security;
create policy wallet_bank_links_select on public.wallet_bank_links
  for select using (owner_id = auth.uid());
create policy wallet_bank_links_delete on public.wallet_bank_links
  for delete using (owner_id = auth.uid());

alter table public.wallet_accounts
  add column if not exists bank_link_id uuid
    references public.wallet_bank_links (id) on delete set null,
  add column if not exists bank_uid text,
  -- Identifica la cuenta del banco entre sesiones (bank_uid cambia al
  -- reconectar). Índice completo: los nulos no chocan y sirve para upsert.
  add column if not exists bank_ref text;
create unique index if not exists wallet_accounts_bank_ref_uq
  on public.wallet_accounts (owner_id, bank_ref);

alter table public.wallet_transactions
  add column if not exists external_id text;
create unique index if not exists wallet_transactions_external_uq
  on public.wallet_transactions (account_id, external_id);
alter table public.wallet_transactions
  drop constraint if exists wallet_transactions_source_check;
alter table public.wallet_transactions
  add constraint wallet_transactions_source_check
  check (source in ('manual', 'ticket', 'notification', 'import',
                    'recurring', 'bank'));

-- Guarda o cambia la aplicación de un usuario. Solo la clave de servicio.
create or replace function public.wallet_bank_app_set(
  p_owner uuid, p_app_id text, p_pem text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_secret uuid;
begin
  select key_secret_id into v_secret
    from public.wallet_bank_apps where owner_id = p_owner;
  if v_secret is null then
    v_secret := vault.create_secret(p_pem, 'wallet_bank_' || p_owner);
  else
    perform vault.update_secret(v_secret, p_pem);
  end if;
  insert into public.wallet_bank_apps (owner_id, app_id, key_secret_id)
    values (p_owner, p_app_id, v_secret)
    on conflict (owner_id) do update set app_id = excluded.app_id;
end $$;

-- Application ID y clave privada de un usuario. Solo la clave de servicio.
create or replace function public.wallet_bank_app_key(p_owner uuid)
returns table (app_id text, pem text)
language sql security definer set search_path = '' as $$
  select a.app_id, s.decrypted_secret
    from public.wallet_bank_apps a
    join vault.decrypted_secrets s on s.id = a.key_secret_id
   where a.owner_id = p_owner;
$$;

revoke all on function public.wallet_bank_app_set(uuid, text, text)
  from public, anon, authenticated;
revoke all on function public.wallet_bank_app_key(uuid)
  from public, anon, authenticated;
grant execute on function public.wallet_bank_app_set(uuid, text, text)
  to service_role;
grant execute on function public.wallet_bank_app_key(uuid) to service_role;

-- Al borrar la aplicación (o la cuenta del usuario) se borra su clave.
create or replace function public.wallet_bank_apps_drop_secret()
returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from vault.secrets where id = old.key_secret_id;
  return old;
end $$;
revoke all on function public.wallet_bank_apps_drop_secret()
  from public, anon, authenticated;

drop trigger if exists wallet_bank_apps_drop_secret on public.wallet_bank_apps;
create trigger wallet_bank_apps_drop_secret
  after delete on public.wallet_bank_apps
  for each row execute function public.wallet_bank_apps_drop_secret();
