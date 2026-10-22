-- ============================================================================
-- PrezHome · Precios de referencia compartidos entre hogares (anónimos)
-- ============================================================================
-- product_prices (0039) solo ve los tickets del PROPIO hogar, así que un hogar
-- nuevo no tiene precios hasta que escanea. Esta función devuelve la MEDIANA
-- del precio unitario de cada producto entre todos los hogares, para usarla
-- cuando el hogar aún no tiene precio propio.
--
-- Privacidad: solo agregados, y solo productos vistos en 3+ hogares distintos
-- en los últimos 180 días (nadie puede deducir el ticket de otro hogar). No
-- devuelve home_id ni nombres escritos por otros (solo la clave normalizada).
-- security definer porque RLS de product_prices limita al propio hogar.
-- ============================================================================

create or replace function public.shared_product_prices()
returns table (name_normalized text, median_unit_price numeric, homes integer)
language sql
stable
security definer
set search_path = public
as $$
  select p.name_normalized,
         percentile_cont(0.5) within group (order by p.last_unit_price)::numeric,
         count(distinct p.home_id)::integer
  from public.product_prices p
  where p.last_unit_price > 0
    and p.last_seen > now() - interval '180 days'
  group by p.name_normalized
  having count(distinct p.home_id) >= 3
$$;

revoke all on function public.shared_product_prices() from public, anon;
grant execute on function public.shared_product_prices() to authenticated;
