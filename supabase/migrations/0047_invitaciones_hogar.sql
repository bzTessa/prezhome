-- ============================================================================
-- PrezHome · Invitaciones al hogar con código que caduca
-- ============================================================================
-- Idempotente. Hasta ahora el "código de invitación" era el id del hogar: no
-- caducaba, no se podía cambiar y quien lo tuviera entraba para siempre. Además
-- un usuario podía cambiar su propio profiles.home_id directamente.
--
-- (a) Tabla public.home_invites: códigos de 8 caracteres (sin 0/O/1/I para
--     que no se confundan), válidos 7 días y hasta 10 usos. Crear uno nuevo
--     anula los anteriores del hogar. Solo se lee desde el hogar; se escribe
--     solo por RPC.
-- (b) RPC:
--     - create_home_invite(): genera un código nuevo para tu hogar.
--     - join_home_with_code(code): te une al hogar del código (y te saca del
--       anterior).
--     - remove_home_member(user_id): el administrador quita a un miembro.
--     - leave_home(): salir del hogar; si se va el único administrador, pasa a
--       serlo el miembro más antiguo.
-- (c) Trigger en profiles: el cliente ya no puede cambiar home_id por su
--     cuenta; solo las funciones de arriba (que corren como propietario).
-- (d) join_home(uuid) (unirse con el id del hogar) deja de estar disponible.
--
-- NOTA DE CI: toca RLS/permisos, así que el check de revisión manual fallará
-- a propósito hasta que se apruebe.
-- ============================================================================

-- (a) Códigos de invitación ---------------------------------------------------
create table if not exists public.home_invites (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references public.homes(id) on delete cascade,
  code text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  max_uses integer not null default 10 check (max_uses > 0),
  uses integer not null default 0 check (uses >= 0),
  revoked_at timestamptz
);

create index if not exists home_invites_home_id_idx
  on public.home_invites (home_id);

alter table public.home_invites enable row level security;

drop policy if exists home_invites_select on public.home_invites;
create policy home_invites_select on public.home_invites
  for select to authenticated
  using (home_id = public.auth_home_id());

revoke all on public.home_invites from anon;
revoke insert, update, delete on public.home_invites from authenticated;
grant select on public.home_invites to authenticated;

-- (b) RPC ---------------------------------------------------------------------
create or replace function public.create_home_invite()
returns table (invite_code text, invite_expires_at timestamptz)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_home uuid := public.auth_home_id();
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- 32
  v_code text;
  v_bytes bytea;
  i integer;
begin
  if v_home is null then
    raise exception 'No autenticado o sin hogar asignado';
  end if;

  -- Un solo código activo por hogar: el nuevo anula los anteriores.
  update public.home_invites
     set revoked_at = now()
   where home_id = v_home
     and revoked_at is null;

  loop
    v_bytes := gen_random_bytes(8);
    v_code := '';
    for i in 0..7 loop
      v_code := v_code || substr(v_alphabet, 1 + (get_byte(v_bytes, i) % 32), 1);
    end loop;
    exit when not exists (
      select 1 from public.home_invites hi where hi.code = v_code
    );
  end loop;

  insert into public.home_invites (home_id, code, created_by)
  values (v_home, v_code, auth.uid());

  return query
    select hi.code, hi.expires_at
      from public.home_invites hi
     where hi.code = v_code;
end;
$$;

create or replace function public.join_home_with_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_inv public.home_invites%rowtype;
begin
  if auth.uid() is null then
    raise exception 'No autenticado';
  end if;

  select * into v_inv
    from public.home_invites
   where code = v_code
   for update;

  if not found
     or v_inv.revoked_at is not null
     or v_inv.expires_at < now()
     or v_inv.uses >= v_inv.max_uses then
    raise exception 'Código no válido o caducado';
  end if;

  -- Se sale del hogar anterior (si lo había) y entra en el nuevo.
  delete from public.home_members
   where user_id = auth.uid()
     and home_id <> v_inv.home_id;

  insert into public.home_members (home_id, user_id, role)
  values (v_inv.home_id, auth.uid(), 'member')
  on conflict (home_id, user_id) do nothing;

  update public.profiles
     set home_id = v_inv.home_id
   where id = auth.uid();

  update public.home_invites
     set uses = uses + 1
   where id = v_inv.id;

  return v_inv.home_id;
end;
$$;

create or replace function public.remove_home_member(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_home uuid := public.auth_home_id();
begin
  if v_home is null then
    raise exception 'No autenticado o sin hogar asignado';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Para irte usa "Salir del hogar"';
  end if;
  if not exists (
    select 1 from public.home_members
     where home_id = v_home and user_id = auth.uid() and role = 'owner'
  ) then
    raise exception 'Solo el administrador puede quitar miembros';
  end if;

  delete from public.home_members
   where home_id = v_home and user_id = p_user_id;

  update public.profiles
     set home_id = null
   where id = p_user_id and home_id = v_home;
end;
$$;

create or replace function public.leave_home()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_home uuid := public.auth_home_id();
  v_next uuid;
begin
  if v_home is null then
    return;
  end if;

  -- Si se va el único administrador, el miembro más antiguo pasa a serlo.
  if exists (
       select 1 from public.home_members
        where home_id = v_home and user_id = auth.uid() and role = 'owner'
     )
     and not exists (
       select 1 from public.home_members
        where home_id = v_home and user_id <> auth.uid() and role = 'owner'
     ) then
    select user_id into v_next
      from public.home_members
     where home_id = v_home and user_id <> auth.uid()
     order by created_at
     limit 1;
    if v_next is not null then
      update public.home_members
         set role = 'owner'
       where home_id = v_home and user_id = v_next;
    end if;
  end if;

  delete from public.home_members
   where home_id = v_home and user_id = auth.uid();

  update public.profiles
     set home_id = null
   where id = auth.uid();
end;
$$;

-- (c) El cliente no cambia su hogar a mano ------------------------------------
-- Las RPC SECURITY DEFINER corren como su propietario, así que pasan; un
-- UPDATE directo desde la app (rol authenticated/anon) se rechaza.
create or replace function public.guard_profile_home_change()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.home_id is distinct from old.home_id
     and current_user in ('authenticated', 'anon') then
    raise exception 'El hogar solo se cambia con una invitación';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_home_change on public.profiles;
create trigger profiles_guard_home_change
  before update of home_id on public.profiles
  for each row execute function public.guard_profile_home_change();

-- (d) Permisos ----------------------------------------------------------------
revoke execute on function public.create_home_invite() from public, anon;
revoke execute on function public.join_home_with_code(text) from public, anon;
revoke execute on function public.remove_home_member(uuid) from public, anon;
revoke execute on function public.leave_home() from public, anon;
revoke execute on function public.guard_profile_home_change() from public, anon, authenticated;

grant execute on function public.create_home_invite() to authenticated;
grant execute on function public.join_home_with_code(text) to authenticated;
grant execute on function public.remove_home_member(uuid) to authenticated;
grant execute on function public.leave_home() to authenticated;

-- Unirse con el id del hogar ya no está permitido.
revoke execute on function public.join_home(uuid) from public, anon, authenticated;
