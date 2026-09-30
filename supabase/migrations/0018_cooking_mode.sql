-- ============================================================================
-- PrezHome · Modo de cocina del usuario
-- ============================================================================
-- Define cómo cocina cada persona, para que la app adapte su experiencia:
--   'daily'    -> "Del día": cocina y lo que sobra a la nevera para mañana.
--                 Interfaz sencilla, sin gestión de congelador ni lotes.
--   'mealprep' -> "Meal prep": cocina en lote y congela para varios días.
--                 Se activan congelador inteligente, lotes y planificación larga.
-- Por defecto 'daily' (lo más común / menos complejo).
--
-- También un modo de porciones: 'practical' (formatos de súper, redondeo) o
-- 'strict' (cantidades exactas al gramo).
-- Idempotente.
-- ============================================================================

alter table public.profiles
  add column if not exists cooking_mode text not null default 'daily'
    check (cooking_mode in ('daily', 'mealprep'));

alter table public.profiles
  add column if not exists portion_mode text not null default 'practical'
    check (portion_mode in ('practical', 'strict'));
