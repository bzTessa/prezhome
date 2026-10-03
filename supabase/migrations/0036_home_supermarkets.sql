-- ============================================================================
-- PrezHome · Supermercados del hogar
-- ============================================================================
-- Guarda la lista de supermercados en los que el hogar hace la compra (p. ej.
-- Mercadona, Lidl...). Es OPCIONAL y a nivel de HOGAR (compartida), pero
-- cualquier miembro puede editarla (como el nombre del hogar). Sirve para que
-- la generación de recetas tenga en cuenta los productos/formatos típicos de
-- esos supermercados (vía IA y, más adelante, Open Food Facts).
--
-- Se admite MÁS DE UNO porque el hogar puede comprar en varios súpers. El
-- valor son claves canónicas en minúsculas (p. ej. 'mercadona', 'lidl'); la
-- app mapea cada clave a su etiqueta visible.
--
-- No requiere RLS nueva: homes ya tiene homes_select (0001) y homes_update
-- (0021) por public.auth_home_id(), que cubren cualquier columna de la tabla.
-- Idempotente (add column if not exists). Las filas existentes quedan con el
-- array por defecto vacío, sin romper datos.
-- ============================================================================

alter table public.homes
  add column if not exists supermarkets text[] not null default '{}';
