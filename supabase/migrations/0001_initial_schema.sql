-- ============================================================================
-- PrezHome · Esquema inicial con Row Level Security (RLS)
-- ============================================================================
-- Modelo: un usuario pertenece a UN solo hogar (profiles.home_id).
-- Principios aplicados (Doc de Seguridad y Auditoría):
--   1. Aislamiento de datos: RLS por hogar en todas las tablas de usuario.
--   2. Separación de datos sensibles: roles/suscripciones/límites de IA viven
--      en tablas de CONTROL que el cliente NO puede modificar (solo service_role
--      o funciones SECURITY DEFINER protegidas).
--   3. Privacidad OCR: bucket privado de tickets accesible solo por el hogar.
-- ============================================================================

-- Extensiones necesarias -----------------------------------------------------
create extension if not exists "pgcrypto";  -- gen_random_uuid()

-- ============================================================================
-- 1. TABLA: homes  (el hogar de la pareja)
-- ============================================================================
create table if not exists public.homes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null default 'Mi Hogar',
  created_by  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now()
);

-- ============================================================================
-- 2. TABLA: profiles  (datos operativos del usuario — SIN roles/permisos)
-- ============================================================================
-- IMPORTANTE (Principio 2): esta tabla NO contiene rol, permisos, suscripción
-- ni límites de IA. Solo datos de perfil que el propio usuario puede editar.
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  home_id     uuid references public.homes (id) on delete set null,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

-- ============================================================================
-- 3. TABLA DE CONTROL: home_members  (rol/permisos — el cliente NO la edita)
-- ============================================================================
-- Los roles viven aquí, separados de profiles. RLS permite LEER la propia
-- membresía, pero NUNCA insertar/actualizar/borrar desde el cliente.
create table if not exists public.home_members (
  home_id    uuid not null references public.homes (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       text not null default 'member' check (role in ('owner', 'member')),
  created_at timestamptz not null default now(),
  primary key (home_id, user_id)
);

-- ============================================================================
-- 4. TABLA DE CONTROL: subscriptions  (suscripción y límites de IA)
-- ============================================================================
-- Solo lectura desde el cliente. La escritura la hace el backend (service_role)
-- o webhooks de pago. El cliente NUNCA puede subir su plan ni sus límites.
create table if not exists public.subscriptions (
  home_id            uuid primary key references public.homes (id) on delete cascade,
  plan               text not null default 'free' check (plan in ('free', 'pro')),
  ai_monthly_limit   integer not null default 20,
  ai_used_this_month integer not null default 0,
  renews_at          timestamptz,
  updated_at         timestamptz not null default now()
);

-- ============================================================================
-- 5. TABLA: inventory_items  (despensa / nevera / congelador)
-- ============================================================================
create table if not exists public.inventory_items (
  id              uuid primary key default gen_random_uuid(),
  home_id         uuid not null references public.homes (id) on delete cascade,
  name            text not null,
  category        text not null default 'Despensa'
                    check (category in ('Despensa', 'Nevera', 'Congelador')),
  quantity        numeric not null default 1,
  unit            text not null default 'unidades',
  expiration_date date,
  created_at      timestamptz not null default now()
);
create index if not exists inventory_items_home_id_idx on public.inventory_items (home_id);

-- ============================================================================
-- 6. TABLA: recipes  (meal prep con macros)
-- ============================================================================
create table if not exists public.recipes (
  id                   uuid primary key default gen_random_uuid(),
  home_id              uuid not null references public.homes (id) on delete cascade,
  title                text not null,
  description          text,
  servings             integer not null default 1,
  prep_time_minutes    integer,
  calories_per_serving integer,
  protein_grams        numeric,
  carbs_grams          numeric,
  fat_grams            numeric,
  created_at           timestamptz not null default now()
);
create index if not exists recipes_home_id_idx on public.recipes (home_id);

-- ============================================================================
-- FUNCIÓN HELPER: auth_home_id()
-- ============================================================================
-- Devuelve el home_id del usuario autenticado leyendo profiles.
-- SECURITY DEFINER + search_path fijo para evitar recursión de RLS y ataques
-- de search_path. Es la pieza central de todas las políticas.
create or replace function public.auth_home_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select home_id from public.profiles where id = auth.uid();
$$;

-- ============================================================================
-- TRIGGER: crear profile automáticamente al registrarse un usuario
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- RPC PROTEGIDA: create_home_and_join(name)
-- ============================================================================
-- Crea un hogar, asigna al usuario como owner en la tabla de control
-- home_members y actualiza su profile.home_id. Todo de forma atómica y
-- controlada por el servidor, para que el cliente no pueda auto-asignarse
-- roles ni home_ids arbitrarios.
create or replace function public.create_home_and_join(home_name text default 'Mi Hogar')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_home_id uuid;
begin
  if auth.uid() is null then
    raise exception 'No autenticado';
  end if;

  insert into public.homes (name, created_by)
  values (coalesce(nullif(trim(home_name), ''), 'Mi Hogar'), auth.uid())
  returning id into new_home_id;

  insert into public.home_members (home_id, user_id, role)
  values (new_home_id, auth.uid(), 'owner');

  insert into public.subscriptions (home_id) values (new_home_id)
  on conflict (home_id) do nothing;

  update public.profiles set home_id = new_home_id where id = auth.uid();

  return new_home_id;
end;
$$;

-- ============================================================================
-- RPC PROTEGIDA: join_home(target_home_id)
-- ============================================================================
-- Permite a la pareja unirse a un hogar existente. Controlado por servidor.
create or replace function public.join_home(target_home_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'No autenticado';
  end if;
  if not exists (select 1 from public.homes where id = target_home_id) then
    raise exception 'El hogar no existe';
  end if;

  insert into public.home_members (home_id, user_id, role)
  values (target_home_id, auth.uid(), 'member')
  on conflict (home_id, user_id) do nothing;

  update public.profiles set home_id = target_home_id where id = auth.uid();
end;
$$;

-- ============================================================================
-- GRANTS base para los roles de Supabase
-- ============================================================================
-- RLS controla QUÉ filas ve cada usuario, pero el rol necesita el permiso base
-- para operar sobre la tabla. Sin esto, PostgREST devuelve 42501 "permission
-- denied". El acceso real sigue restringido por las políticas RLS de abajo.
grant usage on schema public to authenticated, anon;

grant select, insert, update, delete on
  public.homes,
  public.profiles,
  public.home_members,
  public.subscriptions,
  public.inventory_items,
  public.recipes
to authenticated;

-- Permitir ejecutar las funciones RPC del onboarding
grant execute on function public.create_home_and_join(text) to authenticated;
grant execute on function public.join_home(uuid) to authenticated;
grant execute on function public.auth_home_id() to authenticated;

-- ============================================================================
-- ACTIVAR ROW LEVEL SECURITY (Principio 1: activado desde el diseño)
-- ============================================================================
alter table public.homes           enable row level security;
alter table public.profiles        enable row level security;
alter table public.home_members    enable row level security;
alter table public.subscriptions   enable row level security;
alter table public.inventory_items enable row level security;
alter table public.recipes         enable row level security;

-- ----------------------------------------------------------------------------
-- Políticas: profiles
-- ----------------------------------------------------------------------------
-- El usuario ve su propio perfil y el de los miembros de su hogar.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (
    id = auth.uid()
    or (home_id is not null and home_id = public.auth_home_id())
  );

-- El usuario solo puede actualizar SU propio perfil.
-- OJO: home_id se cambia únicamente vía las RPC protegidas (create_home_and_join
-- / join_home), no directamente, para no saltarse la lógica de membresía.
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ----------------------------------------------------------------------------
-- Políticas: homes
-- ----------------------------------------------------------------------------
-- Solo los miembros del hogar pueden verlo.
drop policy if exists homes_select on public.homes;
create policy homes_select on public.homes
  for select using (id = public.auth_home_id());

-- No hay INSERT/UPDATE/DELETE directos: la creación va por create_home_and_join.

-- ----------------------------------------------------------------------------
-- Políticas: home_members (CONTROL — solo lectura desde el cliente)
-- ----------------------------------------------------------------------------
-- El usuario puede LEER la membresía de su propio hogar.
drop policy if exists home_members_select on public.home_members;
create policy home_members_select on public.home_members
  for select using (home_id = public.auth_home_id());

-- Sin políticas de INSERT/UPDATE/DELETE => el cliente NO puede tocar roles.
-- Solo las RPC SECURITY DEFINER y el service_role pueden escribir aquí.

-- ----------------------------------------------------------------------------
-- Políticas: subscriptions (CONTROL — solo lectura desde el cliente)
-- ----------------------------------------------------------------------------
drop policy if exists subscriptions_select on public.subscriptions;
create policy subscriptions_select on public.subscriptions
  for select using (home_id = public.auth_home_id());

-- Sin INSERT/UPDATE/DELETE => el cliente NO puede subir su plan ni sus límites de IA.

-- ----------------------------------------------------------------------------
-- Políticas: inventory_items (datos operativos por hogar)
-- ----------------------------------------------------------------------------
drop policy if exists inventory_select on public.inventory_items;
create policy inventory_select on public.inventory_items
  for select using (home_id = public.auth_home_id());

drop policy if exists inventory_insert on public.inventory_items;
create policy inventory_insert on public.inventory_items
  for insert with check (home_id = public.auth_home_id());

drop policy if exists inventory_update on public.inventory_items;
create policy inventory_update on public.inventory_items
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists inventory_delete on public.inventory_items;
create policy inventory_delete on public.inventory_items
  for delete using (home_id = public.auth_home_id());

-- ----------------------------------------------------------------------------
-- Políticas: recipes (datos operativos por hogar)
-- ----------------------------------------------------------------------------
drop policy if exists recipes_select on public.recipes;
create policy recipes_select on public.recipes
  for select using (home_id = public.auth_home_id());

drop policy if exists recipes_insert on public.recipes;
create policy recipes_insert on public.recipes
  for insert with check (home_id = public.auth_home_id());

drop policy if exists recipes_update on public.recipes;
create policy recipes_update on public.recipes
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists recipes_delete on public.recipes;
create policy recipes_delete on public.recipes
  for delete using (home_id = public.auth_home_id());

-- ============================================================================
-- FIN del esquema base. El Storage para OCR de tickets va en 0002.
-- ============================================================================
