-- ============================================================================
-- PrezHome · Comparar la lista de la compra entre súpers
-- ============================================================================
-- Una sola llamada busca cada producto de la lista en el catálogo de varios
-- súpers (supermarket_products) y devuelve hasta 15 candidatos con precio por
-- producto y súper. La app elige luego el que de verdad es ese producto
-- (rankProducts) y suma cuánto costaría la lista en cada súper.
--
-- p_queries: una entrada por producto, con las palabras ya normalizadas que
-- prepara la app (minúsculas, sin tildes, separadas por espacios). Solo se
-- usan letras y números de cada palabra. Como mucho 60 productos y 12 súpers.
-- Solo lee el catálogo (security invoker: aplica su RLS de lectura).
-- ============================================================================

create or replace function public.compare_catalog_basket(
  p_stores text[],
  p_queries text[]
)
returns table (
  query_idx int,
  store text,
  product_id text,
  name text,
  brand text,
  size text,
  price numeric,
  image_url text
)
language sql
stable
security invoker
set search_path = public
as $$
  with qs as (
    select q.idx::int as idx,
           array(
             select regexp_replace(w, '[^a-z0-9]', '', 'g')
             from unnest(string_to_array(lower(q.words), ' ')) w
             where regexp_replace(w, '[^a-z0-9]', '', 'g') <> ''
           ) as ws
    from unnest(p_queries[1:60]) with ordinality as q(words, idx)
  )
  select q.idx, s.store, p.product_id, p.name, p.brand, p.size, p.price,
         p.image_url
  from qs q
  cross join unnest(p_stores[1:12]) as s(store)
  cross join lateral (
    select sp.product_id, sp.name, sp.brand, sp.size, sp.price, sp.image_url
    from public.supermarket_products sp
    where sp.store = s.store
      and sp.price is not null
      -- La primera palabra va aparte para que use el índice de trigramas.
      and sp.name_normalized ilike '%' || q.ws[1] || '%'
      and sp.name_normalized ilike all (
        select '%' || w || '%' from unnest(q.ws) w
      )
    -- Primero lo que EMPIEZA por lo buscado y, dentro, los nombres cortos.
    order by (sp.name_normalized like q.ws[1] || '%') desc,
             length(sp.name_normalized)
    limit 15
  ) p
  where cardinality(q.ws) > 0;
$$;

-- ============================================================================
-- Precios de los tickets por súper
-- ============================================================================
-- Los súpers sin catálogo (Dia, Carrefour, Alcampo, Eroski…) entran en el
-- comparador con los precios que traen los tickets escaneados. El nombre del
-- comercio del ticket es texto libre ("MERCADONA S.A.", "Dia %"): esta
-- función lo pasa a la clave del súper que usa la app (homes.supermarkets).
-- ============================================================================

create or replace function public.store_key_for_merchant(p_merchant text)
returns text
language sql
immutable
set search_path = public
as $$
  select case
    when m like '%mercadona%' then 'mercadona'
    when m like '%carrefour%' then 'carrefour'
    when m like '%lidl%' then 'lidl'
    when m like '%alcampo%' then 'alcampo'
    when m like '%auchan%' then 'auchan'
    when m like '%eroski%' then 'eroski'
    when m like '%consum%' then 'consum'
    when m like '%ahorramas%' then 'ahorramas'
    when m like '%bonarea%' or m like '%bon area%' then 'bonarea'
    when m like '%aldi%' then 'aldi'
    when m like '%corte ingles%' or m like '%hipercor%'
      or m like '%supercor%' then 'elcorteingles'
    when m like '%gadis%' then 'gadis'
    when m like '%caprabo%' then 'caprabo'
    when m like '%condis%' then 'condis'
    when m like '%hiperdino%' then 'hiperdino'
    when m like '%continente%' then 'continente'
    when m like '%pingo doce%' or m like '%pingodoce%' then 'pingodoce'
    when m like '%rewe%' then 'rewe'
    when m like '%edeka%' then 'edeka'
    when m like '%kaufland%' then 'kaufland'
    when m like '%esselunga%' then 'esselunga'
    when m like '%leclerc%' then 'leclerc'
    when m like '%intermarche%' then 'intermarche'
    when m ~ '(^|[^a-z])dia([^a-z]|$)' then 'dia'
    when m ~ '(^|[^a-z])bm([^a-z]|$)' then 'bm'
    when m ~ '(^|[^a-z])spar([^a-z]|$)' then 'spar'
  end
  from (
    select translate(lower(coalesce(p_merchant, '')),
                     'áàäâéèëêíìïîóòöôúùüûñç',
                     'aaaaeeeeiiiioooouuuunc') as m
  ) x
$$;

-- Precio de cada producto buscado en cada súper según los tickets de los
-- últimos 120 días, del mismo país que el hogar de quien pregunta.
--
-- Privacidad (como 0064): de los tickets de OTROS hogares solo sale la
-- mediana, y solo si ese producto en ese súper lo han comprado 3+ hogares.
-- Los tickets del propio hogar siempre cuentan. Nunca sale home_id ni el
-- texto escrito por otros: solo la clave normalizada del producto.
-- security definer porque RLS de tickets limita al propio hogar.
create or replace function public.ticket_store_prices(p_queries text[])
returns table (
  query_idx int,
  store text,
  name_normalized text,
  price numeric,
  homes int,
  own boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with me as (
    select h.id as home_id, h.country_code
    from public.homes h
    where h.id = public.auth_home_id()
  ),
  qs as (
    select q.idx::int as idx,
           array(
             select regexp_replace(w, '[^a-z0-9]', '', 'g')
             from unnest(string_to_array(lower(q.words), ' ')) w
             where regexp_replace(w, '[^a-z0-9]', '', 'g') <> ''
           ) as ws
    from unnest(p_queries[1:60]) with ordinality as q(words, idx)
  ),
  lines as (
    select public.store_key_for_merchant(t.merchant) as store,
           trim(regexp_replace(
             translate(lower(ti.name), 'áàäâéèëêíìïîóòöôúùüûñç',
                       'aaaaeeeeiiiioooouuuunc'),
             '[^a-z0-9]+', ' ', 'g')) as name_normalized,
           coalesce(
             nullif(ti.unit_price, 0),
             ti.total_price / nullif(ti.quantity, 0),
             ti.total_price
           ) as price,
           ti.home_id,
           ti.home_id = (select home_id from me) as own
    from public.ticket_items ti
    join public.tickets t on t.id = ti.ticket_id
    join public.homes h on h.id = ti.home_id
    where t.purchased_at > current_date - 120
      and h.country_code is not distinct from (select country_code from me)
      and exists (select 1 from me)
  ),
  matched as (
    select q.idx, l.*
    from qs q
    join lines l
      on l.store is not null
     and l.price > 0
     and l.name_normalized ilike all (
       select '%' || w || '%' from unnest(q.ws) w
     )
    where cardinality(q.ws) > 0
  ),
  own_prices as (
    select idx, store, name_normalized,
           percentile_cont(0.5) within group (order by price)::numeric as price,
           1 as homes, true as own
    from matched
    where own
    group by idx, store, name_normalized
  ),
  shared_prices as (
    select idx, store, name_normalized,
           percentile_cont(0.5) within group (order by price)::numeric as price,
           count(distinct home_id)::int as homes, false as own
    from matched
    group by idx, store, name_normalized
    having count(distinct home_id) >= 3
  )
  select * from own_prices
  union all
  select s.* from shared_prices s
  where not exists (
    select 1 from own_prices o
    where o.idx = s.idx and o.store = s.store
      and o.name_normalized = s.name_normalized
  )
$$;

revoke all on function public.ticket_store_prices(text[]) from public, anon;
grant execute on function public.ticket_store_prices(text[]) to authenticated;
