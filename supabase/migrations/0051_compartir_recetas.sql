-- ============================================================================
-- PrezHome · Compartir recetas con un código
-- ============================================================================
-- Idempotente. share_recipe(receta) guarda una copia de la receta (con sus
-- ingredientes) bajo un código de 8 caracteres y lo devuelve; volver a
-- compartirla actualiza la copia y mantiene el código. get_shared_recipe(código)
-- devuelve esa copia a cualquier usuario con sesión, que la guarda en su hogar.
-- La tabla no se lee directamente: solo a través de estas funciones.
--
-- NOTA DE CI: activa RLS y cambia grants, así que el check de revisión manual
-- fallará a propósito hasta que se apruebe.
-- ============================================================================

create table if not exists public.shared_recipes (
  code       text primary key,
  recipe_id  uuid not null unique references public.recipes (id) on delete cascade,
  recipe     jsonb not null,
  created_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.shared_recipes enable row level security;
revoke all on public.shared_recipes from anon, authenticated;

create or replace function public.share_recipe(p_recipe_id uuid)
returns text
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_snapshot jsonb;
  v_code text;
  v_bytes bytea;
  i integer;
begin
  select to_jsonb(r) - 'id' - 'home_id' - 'is_favorite' - 'created_at'
         || jsonb_build_object('ingredients', coalesce((
              select jsonb_agg(jsonb_build_object(
                       'name', ri.name, 'quantity', ri.quantity, 'unit', ri.unit)
                     order by ri.position)
                from public.recipe_ingredients ri
               where ri.recipe_id = r.id), '[]'::jsonb))
    into v_snapshot
    from public.recipes r
   where r.id = p_recipe_id
     and r.home_id = public.auth_home_id();
  if v_snapshot is null then
    raise exception 'Receta no encontrada';
  end if;

  select code into v_code from public.shared_recipes where recipe_id = p_recipe_id;
  if v_code is not null then
    update public.shared_recipes
       set recipe = v_snapshot, updated_at = now()
     where code = v_code;
    return v_code;
  end if;

  loop
    v_bytes := gen_random_bytes(8);
    v_code := '';
    for i in 0..7 loop
      v_code := v_code || substr(v_alphabet, 1 + (get_byte(v_bytes, i) % 32), 1);
    end loop;
    exit when not exists (select 1 from public.shared_recipes where code = v_code);
  end loop;

  insert into public.shared_recipes (code, recipe_id, recipe, created_by)
  values (v_code, p_recipe_id, v_snapshot, auth.uid());
  return v_code;
end;
$$;

create or replace function public.get_shared_recipe(p_code text)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select recipe from public.shared_recipes
   where auth.uid() is not null
     and code = upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
$$;

revoke all on function public.share_recipe(uuid) from public, anon;
revoke all on function public.get_shared_recipe(text) from public, anon;
grant execute on function public.share_recipe(uuid) to authenticated;
grant execute on function public.get_shared_recipe(text) to authenticated;
