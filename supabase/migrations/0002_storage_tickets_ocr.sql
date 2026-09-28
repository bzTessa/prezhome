-- ============================================================================
-- PrezHome · Storage privado para OCR de tickets (Principio 3: Privacidad OCR)
-- ============================================================================
-- Las imágenes de tickets se guardan en un bucket PRIVADO. El acceso se limita
-- a los miembros del hogar mediante convención de rutas:
--     tickets/{home_id}/{archivo}
-- La primera carpeta de la ruta debe coincidir con el home_id del usuario.
-- ============================================================================

-- Crear el bucket privado (public = false) -----------------------------------
insert into storage.buckets (id, name, public)
values ('tickets', 'tickets', false)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- Políticas de Storage: solo el hogar accede a sus tickets
-- ----------------------------------------------------------------------------
-- storage.foldername(name)[1] = primera carpeta de la ruta = home_id esperado.

drop policy if exists tickets_select on storage.objects;
create policy tickets_select on storage.objects
  for select using (
    bucket_id = 'tickets'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

drop policy if exists tickets_insert on storage.objects;
create policy tickets_insert on storage.objects
  for insert with check (
    bucket_id = 'tickets'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

drop policy if exists tickets_update on storage.objects;
create policy tickets_update on storage.objects
  for update using (
    bucket_id = 'tickets'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

drop policy if exists tickets_delete on storage.objects;
create policy tickets_delete on storage.objects
  for delete using (
    bucket_id = 'tickets'
    and (storage.foldername(name))[1] = public.auth_home_id()::text
  );

-- ============================================================================
-- (Opcional) Tabla para datos económicos extraídos del ticket por OCR.
-- Datos operativos por hogar, con RLS. Sanitiza antes de guardar (Principio 3).
-- ============================================================================
create table if not exists public.tickets (
  id           uuid primary key default gen_random_uuid(),
  home_id      uuid not null references public.homes (id) on delete cascade,
  storage_path text not null,               -- tickets/{home_id}/archivo.jpg
  merchant     text,
  total_amount numeric,
  purchased_at date,
  created_at   timestamptz not null default now()
);
create index if not exists tickets_home_id_idx on public.tickets (home_id);

alter table public.tickets enable row level security;

drop policy if exists tickets_row_select on public.tickets;
create policy tickets_row_select on public.tickets
  for select using (home_id = public.auth_home_id());

drop policy if exists tickets_row_insert on public.tickets;
create policy tickets_row_insert on public.tickets
  for insert with check (home_id = public.auth_home_id());

drop policy if exists tickets_row_update on public.tickets;
create policy tickets_row_update on public.tickets
  for update using (home_id = public.auth_home_id())
  with check (home_id = public.auth_home_id());

drop policy if exists tickets_row_delete on public.tickets;
create policy tickets_row_delete on public.tickets
  for delete using (home_id = public.auth_home_id());
