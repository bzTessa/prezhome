-- ============================================================================
-- PrezHome · Preferencias del dashboard de Inicio (por usuario)
-- ============================================================================
-- Permite que cada usuario PERSONALICE su pantalla de Inicio: qué tarjetas ve,
-- en qué orden y qué accesos rápidos quiere. Se guarda como JSON en el perfil
-- (dato de UI por persona), p. ej.:
--   {
--     "cards": ["meals","expiry","tasks","calories","spending","calendar"],
--     "hidden": ["spending"],
--     "quick": ["add_inventory","shopping","scan_ticket"]
--   }
-- La app interpreta el JSON; si es null usa el orden por defecto. Es un dato
-- operativo del propio usuario, así que NO toca RLS: profiles ya tiene sus
-- políticas desde 0001 (el usuario solo edita su fila). Idempotente.
-- ============================================================================

alter table public.profiles
  add column if not exists dashboard_prefs jsonb;
