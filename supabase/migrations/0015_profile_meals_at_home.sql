-- ============================================================================
-- PrezHome · Comidas en casa por día de la semana (comer fuera)
-- ============================================================================
-- Permite que un miembro indique, para cada comida, qué días la hace EN CASA.
-- Ej.: alguien que come fuera (trabajo) de lunes a viernes solo tendría la
-- "comida" marcada sábado/domingo, pero la "cena" todos los días.
-- Se guarda como JSON: { "lunch": [6,7], "dinner": [1,2,3,4,5,6,7], ... }
-- donde los números son días 1=Lun..7=Dom. Si una comida no aparece o su lista
-- está vacía, se asume que se hace TODOS los días (comportamiento por defecto).
-- Idempotente.
-- ============================================================================

alter table public.profiles
  add column if not exists meals_at_home jsonb;
