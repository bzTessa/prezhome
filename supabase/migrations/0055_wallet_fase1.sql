-- ============================================================================
-- PrezWallet · Fase 1 (Apuntar): cuentas, categorías y movimientos
-- ============================================================================
-- Idempotente. Tablas de PrezWallet (PrezWallet/docs/PREZWALLET.md §4) en el
-- mismo proyecto que PrezHome. Todo es del usuario (owner_id) y no necesita
-- hogar: PrezWallet funciona sin PrezHome. Si el usuario tiene hogar, puede
-- compartir una cuenta o un movimiento poniéndole home_id (= "Hogar").
-- Importes con signo: gasto < 0, ingreso > 0, así el saldo es una suma.
-- ============================================================================

create table if not exists public.wallet_accounts (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  home_id         uuid references public.homes (id) on delete set null,
  name            text not null check (length(trim(name)) > 0),
  type            text not null default 'bank'
                    check (type in ('bank', 'cash', 'card', 'investment',
                                    'property', 'loan')),
  currency        text not null default 'EUR',
  opening_balance numeric not null default 0,
  archived        boolean not null default false,
  created_at      timestamptz not null default now()
);
create index if not exists wallet_accounts_owner_idx on public.wallet_accounts (owner_id);
create index if not exists wallet_accounts_home_idx on public.wallet_accounts (home_id);

-- owner_id nulo = categoría por defecto, visible para todos.
create table if not exists public.wallet_categories (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid default auth.uid() references auth.users (id) on delete cascade,
  home_id    uuid references public.homes (id) on delete cascade,
  name       text not null check (length(trim(name)) > 0),
  icon       text not null default 'otros',
  color      text,
  kind       text not null default 'expense' check (kind in ('expense', 'income')),
  nature     text check (nature in ('need', 'want', 'must')),
  sort       int not null default 100,
  created_at timestamptz not null default now()
);
create unique index if not exists wallet_categories_default_uq
  on public.wallet_categories (name, kind) where owner_id is null;
create index if not exists wallet_categories_owner_idx on public.wallet_categories (owner_id);

create table if not exists public.wallet_transactions (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  home_id     uuid references public.homes (id) on delete set null,
  account_id  uuid references public.wallet_accounts (id) on delete cascade,
  category_id uuid references public.wallet_categories (id) on delete set null,
  amount      numeric not null check (amount <> 0),
  date        date not null default (now()::date),
  note        text,
  source      text not null default 'manual'
                check (source in ('manual', 'ticket', 'notification', 'import',
                                  'recurring')),
  created_at  timestamptz not null default now()
);
create index if not exists wallet_transactions_owner_date_idx
  on public.wallet_transactions (owner_id, date desc);
create index if not exists wallet_transactions_home_date_idx
  on public.wallet_transactions (home_id, date desc);
create index if not exists wallet_transactions_account_idx
  on public.wallet_transactions (account_id);

-- Saldo de cada cuenta. security_invoker: suma solo lo que el RLS deja ver.
create or replace view public.wallet_account_balances
with (security_invoker = true) as
  select a.id as account_id,
         a.opening_balance + coalesce(sum(t.amount), 0) as balance
  from public.wallet_accounts a
  left join public.wallet_transactions t on t.account_id = a.id
  group by a.id;

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.wallet_accounts enable row level security;
alter table public.wallet_categories enable row level security;
alter table public.wallet_transactions enable row level security;

-- Cuentas: las ve el dueño y, si es de Hogar, su hogar. Solo el dueño las cambia.
drop policy if exists wallet_accounts_select on public.wallet_accounts;
create policy wallet_accounts_select on public.wallet_accounts
  for select using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_accounts_insert on public.wallet_accounts;
create policy wallet_accounts_insert on public.wallet_accounts
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
  );

drop policy if exists wallet_accounts_update on public.wallet_accounts;
create policy wallet_accounts_update on public.wallet_accounts
  for update using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
  );

drop policy if exists wallet_accounts_delete on public.wallet_accounts;
create policy wallet_accounts_delete on public.wallet_accounts
  for delete using (owner_id = auth.uid());

-- Categorías: las de por defecto, las propias y las del hogar.
drop policy if exists wallet_categories_select on public.wallet_categories;
create policy wallet_categories_select on public.wallet_categories
  for select using (
    owner_id is null
    or owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_categories_insert on public.wallet_categories;
create policy wallet_categories_insert on public.wallet_categories
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
  );

drop policy if exists wallet_categories_update on public.wallet_categories;
create policy wallet_categories_update on public.wallet_categories
  for update using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
  );

drop policy if exists wallet_categories_delete on public.wallet_categories;
create policy wallet_categories_delete on public.wallet_categories
  for delete using (owner_id = auth.uid());

-- Movimientos: los ve y edita el dueño; los de Hogar, también su hogar.
-- La cuenta, si la hay, tiene que ser una que el usuario pueda ver.
drop policy if exists wallet_transactions_select on public.wallet_transactions;
create policy wallet_transactions_select on public.wallet_transactions
  for select using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

drop policy if exists wallet_transactions_insert on public.wallet_transactions;
create policy wallet_transactions_insert on public.wallet_transactions
  for insert with check (
    owner_id = auth.uid()
    and (home_id is null or home_id = public.auth_home_id())
    and (account_id is null or exists (
      select 1 from public.wallet_accounts a
      where a.id = account_id
        and (a.owner_id = auth.uid()
             or (a.home_id is not null and a.home_id = public.auth_home_id()))
    ))
  );

drop policy if exists wallet_transactions_update on public.wallet_transactions;
create policy wallet_transactions_update on public.wallet_transactions
  for update using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  )
  with check (
    ((home_id is null and owner_id = auth.uid())
     or (home_id is not null and home_id = public.auth_home_id()))
    and (account_id is null or exists (
      select 1 from public.wallet_accounts a
      where a.id = account_id
        and (a.owner_id = auth.uid()
             or (a.home_id is not null and a.home_id = public.auth_home_id()))
    ))
  );

drop policy if exists wallet_transactions_delete on public.wallet_transactions;
create policy wallet_transactions_delete on public.wallet_transactions
  for delete using (
    owner_id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

grant select, insert, update, delete on public.wallet_accounts to authenticated;
grant select, insert, update, delete on public.wallet_categories to authenticated;
grant select, insert, update, delete on public.wallet_transactions to authenticated;
grant select on public.wallet_account_balances to authenticated;

-- ----------------------------------------------------------------------------
-- Categorías por defecto (icon = clave que la app traduce a un icono)
-- ----------------------------------------------------------------------------
insert into public.wallet_categories (owner_id, name, icon, kind, nature, sort) values
  (null, 'Supermercado',   'super',       'expense', 'need', 10),
  (null, 'Casa',           'casa',        'expense', 'must', 20),
  (null, 'Transporte',     'transporte',  'expense', 'need', 30),
  (null, 'Restaurantes',   'restaurante', 'expense', 'want', 40),
  (null, 'Ocio',           'ocio',        'expense', 'want', 50),
  (null, 'Salud',          'salud',       'expense', 'need', 60),
  (null, 'Ropa',           'ropa',        'expense', 'want', 70),
  (null, 'Suscripciones',  'suscripcion', 'expense', 'must', 80),
  (null, 'Regalos',        'regalo',      'expense', 'want', 90),
  (null, 'Otros',          'otros',       'expense', null,   100),
  (null, 'Nómina',         'nomina',      'income',  null,   10),
  (null, 'Otros ingresos', 'ingreso',     'income',  null,   20)
on conflict (name, kind) where owner_id is null do nothing;
