-- ============================================================================
-- PrezHome · Preferencias alimentarias del perfil (personalización)
-- ============================================================================
-- Enriquece el perfil con PREFERENCIAS que personalizan la experiencia y que
-- usa el generador de recetas: tipo de dieta, alergias/intolerancias,
-- ingredientes que la persona evita, y cuánto tiempo quiere dedicar a cocinar.
-- Son datos del propio usuario (profiles ya tiene su RLS desde 0001; no se
-- toca). Idempotente. Valores por defecto neutros.
--
--   diet          : 'omnivora' | 'vegetariana' | 'vegana' | 'pescetariana' |
--                   'baja_carbo' | 'sin_gluten' (texto libre tolerado)
--   allergies     : text[]  (p. ej. {'frutos secos','lactosa'})
--   disliked      : text[]  (ingredientes que NO quiere, p. ej. {'cebolla'})
--   cook_time_pref: 'rapido' (<20 min) | 'normal' | 'elaborado' | null
-- ============================================================================

alter table public.profiles
  add column if not exists diet text;

alter table public.profiles
  add column if not exists allergies text[] not null default '{}';

alter table public.profiles
  add column if not exists disliked text[] not null default '{}';

alter table public.profiles
  add column if not exists cook_time_pref text;
