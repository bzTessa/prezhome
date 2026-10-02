-- ============================================================================
-- PrezHome · Enlace de video en recetas
-- ============================================================================
-- Guarda un enlace de video opcional para la receta (Instagram, TikTok,
-- YouTube...). No se descarga ni transcribe nada: solo se almacena la URL para
-- poder abrirla desde la pantalla de detalle. Puede ser null (sin enlace).
-- Idempotente.
-- ============================================================================

alter table public.recipes
  add column if not exists video_url text;
