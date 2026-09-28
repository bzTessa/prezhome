-- 1. Crear tabla de perfiles (Profiles)
create table public.profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    home_id uuid default gen_random_uuid() not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Habilitar RLS (Row Level Security)
alter table public.profiles enable row level security;

-- 3. Políticas RLS estrictas
create policy "Los usuarios pueden ver su propio perfil"
    on public.profiles
    for select
    using (auth.uid() = id);

create policy "Los usuarios pueden actualizar su propio perfil"
    on public.profiles
    for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- 4. Crear Función Segura para el Trigger
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, home_id)
  values (new.id, gen_random_uuid());
  return new;
end;
$$;

-- 5. Crear el Trigger en la tabla interna de Supabase (auth.users)
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();