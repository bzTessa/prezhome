-- ============================================================================
-- PrezHome · Comparar la lista de la compra entre súpers (v2)
-- ============================================================================
-- Incluye unit_price, unit, ean y member_price para que la app compare por
-- igual producto y cantidad (€/kg, €/L, €/ud) y pueda alinear formatos entre
-- supermercados. Sube el límite a 25 candidatos por (producto, súper) para que
-- entren todos los formatos de envase (250 ml, 500 ml, 1 L, 3 L...).
-- ============================================================================

drop function if exists public.compare_catalog_basket(text[], text[]);

create function public.compare_catalog_basket(
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
  unit_price numeric,
  unit text,
  ean text,
  member_price numeric,
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
         p.unit_price, p.unit, p.ean, p.member_price, p.image_url
  from qs q
  cross join unnest(p_stores[1:12]) as s(store)
  cross join lateral (
    select sp.product_id, sp.name, sp.brand, sp.size, sp.price,
           sp.unit_price, sp.unit, sp.ean, sp.member_price, sp.image_url
    from public.supermarket_products sp
    where sp.store = s.store
      and sp.price is not null
      -- La primera palabra va aparte para que use el índice de trigramas.
      and sp.name_normalized ilike '%' || q.ws[1] || '%'
      and sp.name_normalized ilike all (
        select '%' || w || '%' from unnest(q.ws) w
      )
    -- Primero lo que EMPIEZA por lo buscado, priorizando los que traen precio
    -- unitario y, dentro, los nombres cortos.
    order by (sp.name_normalized like q.ws[1] || '%') desc,
             (sp.unit_price is not null) desc,
             length(sp.name_normalized)
    limit 25
  ) p
  where cardinality(q.ws) > 0;
$$;

grant execute on function public.compare_catalog_basket(text[], text[]) to authenticated;
