-- Lo que no se puede (o no se quiere) comer en casa, para que el plan
-- automático lo respete. Las alergias y la dieta de cada persona están en su
-- perfil, que los demás solo ven si lo hizo público; esta función devuelve
-- únicamente esas tres columnas de cada miembro del hogar de quien llama,
-- sin nombre ni otros datos.
create or replace function public.home_food_restrictions()
returns table (diet text, allergies text[], disliked text[])
language sql
stable
security definer
set search_path = public
as $$
  select p.diet, p.allergies, p.disliked
  from public.profiles p
  where p.home_id is not null
    and p.home_id = public.auth_home_id();
$$;

revoke all on function public.home_food_restrictions() from public, anon;
grant execute on function public.home_food_restrictions() to authenticated;
