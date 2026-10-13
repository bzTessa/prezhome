# Memoria del proyecto

Léelo al empezar una sesión: evita volver a explorar el repo. Actualízalo
cuando cambie algo de lo que aquí se dice (breve, sin historia).

## Cómo trabajar
- Flutter: `export PATH=/opt/flutter-sdk/flutter/bin:$PATH` y comandos desde
  `apps/prezhome`. Tras `flutter analyze`/`test`/`pub get`, deshacer cambios
  en `analysis_options.yaml` (`git checkout analysis_options.yaml`).
- Antes de push: `dart format .`, `flutter analyze`, `flutter test`, y
  `dart run tool/architecture/dependency_map.dart` (CI lo comprueba con
  `--check`; regenera `apps/prezhome/docs/architecture/dependency-map.md`).
- Entrega por PR a `main` desde `claude/life-management-apps-ffjpwf`. Al
  fusionar, `deploy.yml` hace `supabase db push`.
- Migraciones que tocan RLS/grants/DROP: el check "Revisión manual requerida"
  de `ai-development.yml` falla a propósito; lo aprueba Tessa.
- Supabase: proyecto `ubrihtnnkbwcbchvvlno`. RLS por `auth_home_id()`.
  `pgcrypto` está en el esquema `extensions`. Última migración: 0047.
- No ejecutar SQL de prueba largo en producción (se corta a 60 s).

## Preferencias de Tessa (producto y textos)
- Nada que huela a IA: sin destellos/estrellitas, sin decir "IA".
- Textos cortos, sin sobreexplicar ni ejemplos cutres. Siempre mayúscula
  inicial. Nombres en español (p. ej. modos del plan).
- Fotos de producto de Open Food Facts (se ven enteras, `contain` sobre
  blanco), no Unsplash. El usuario puede poner su foto.
- Deshacer en vez de diálogos de confirmación. Háptica en acciones.
- Trabajar con autonomía y entregar en PR; respuestas en español.

## Mapa del código (`apps/prezhome/lib`)
- Navegación: `main_shell.dart` + barra `packages/prez_ui/lib/src/floating_nav_bar.dart`
  (se desliza el dedo para cambiar). Pestañas en `tabs/`.
- Diseño: `theme/` (`AppColors`, `AppTextStyles` Plus Jakarta Sans,
  `AppRadius`, `AppSpacing`, `AppMotion`). Widgets comunes: `widgets/empty_state.dart`,
  `widgets/list_skeleton.dart`, `widgets/food_image.dart`.
- Offline: `services/offline_repository.dart` (+ `offline_merge.dart`,
  `supabase_remote_sender.dart`, `offline_provider.dart`). Ids locales
  `local-`. Errores permanentes (`PermanentSyncError`) se descartan.
- Compra: `shopping_list_screen.dart`, `services/shopping_checkout.dart`
  (comprado → despensa por zona, "Todo comprado", tarea "compra" completada
  marca la lista), `services/plan_shopping.dart` (lista desde el plan).
- Fotos: `services/product_photo_resolver.dart` (caché `food_photo_cache` →
  búsqueda OFF), `services/product_search_service.dart` (8/min, caché).
- Despensa: `inventory_screen.dart`, `services/shelf_life.dart`
  (`pantryZoneFor`; categorías válidas: Despensa, Nevera, Congelador,
  Especias, Bebidas, Limpieza, Hogar).
- Plan de comidas: `meal_plan_screen.dart`, `services/meal_planner.dart`,
  `meal_prep_*`. Recetas: `recipes_screen.dart`, `recipe_detail_screen.dart`,
  `cook_mode_screen.dart`, `utils/recipe_steps.dart`.
- Hogar e invitaciones: `household_screen.dart`, `services/home_invites.dart`
  (códigos de 8 caracteres, 7 días, 10 usos; RPC `create_home_invite`,
  `join_home_with_code`, `remove_home_member`, `leave_home`).
- Edge Functions: `supabase/functions/` (validan JWT).

## Pendiente
- Tessa: activar "Leaked password protection" en Supabase Auth.
- Tessa enviará imágenes (animaciones del gato Miau y otras).
- Ofrecido, sin decidir: modo oscuro; precios con Open Prices.
