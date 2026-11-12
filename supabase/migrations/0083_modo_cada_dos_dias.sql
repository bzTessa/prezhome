-- Modo de cocina "Cada dos días" ('alternate'): se cocina de más un día y al
-- siguiente se comen las sobras. Idempotente.
alter table public.profiles
  drop constraint if exists profiles_cooking_mode_check;
alter table public.profiles
  add constraint profiles_cooking_mode_check
    check (cooking_mode in ('daily', 'mealprep', 'alternate'));
