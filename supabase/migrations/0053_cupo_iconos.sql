-- ============================================================================
-- PrezHome · Cupo para los iconos dibujados (función product-icon)
-- ============================================================================
-- Idempotente. Cada icono nuevo se dibuja una sola vez y lo comparten todos
-- los hogares; este cupo no se enseña en "Tu plan", solo frena abusos.
-- ============================================================================

insert into public.plan_quotas (plan, feature, monthly_limit) values
  ('free', 'product_icon', 30),
  ('pro',  'product_icon', 150)
on conflict (plan, feature) do nothing;
