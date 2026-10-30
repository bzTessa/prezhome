-- ============================================================================
-- PrezHome · País del hogar
-- ============================================================================
-- homes.country_code: código ISO de 2 letras (ES, DE, FR, IT, BA, US...). Decide
-- la moneda, los súper del catálogo y los precios de referencia. Los hogares
-- que ya existen son de España. En los nuevos queda vacío y la app lo rellena
-- con el país del móvil la primera vez (create_home_and_join no cambia).
-- La política homes_update (0021) ya deja editarlo a los miembros.
-- Idempotente.
-- ============================================================================

alter table public.homes
  add column if not exists country_code text
    check (country_code ~ '^[A-Z]{2}$');

update public.homes set country_code = 'ES' where country_code is null;
