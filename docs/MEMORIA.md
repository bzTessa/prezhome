# Memoria del proyecto

Léelo al empezar una sesión: evita volver a explorar el repo. Actualízalo
cuando cambie algo de lo que aquí se dice (breve, sin historia).

## Cómo trabajar
- Flutter: `export PATH=/opt/flutter-sdk/flutter/bin:$PATH` y comandos desde
  `apps/prezhome` (si no está, descargar el stable de
  `storage.googleapis.com/flutter_infra_release` en `/opt/flutter-sdk`). Tras `flutter analyze`/`test`/`pub get`, deshacer cambios
  en `analysis_options.yaml` (`git checkout analysis_options.yaml`).
- Antes de push: `dart format .`, `flutter analyze`, `flutter test`, y
  `dart run tool/architecture/dependency_map.dart` (CI lo comprueba con
  `--check`; regenera `apps/prezhome/docs/architecture/dependency-map.md`).
- Entrega por PR a `main` desde `claude/life-management-apps-ffjpwf`. Al
  fusionar, `deploy.yml` hace `supabase db push`.
- Migraciones que tocan RLS/grants/DROP: el check "Revisión manual requerida"
  de `ai-development.yml` falla a propósito; lo aprueba Tessa.
- Supabase: proyecto `ubrihtnnkbwcbchvvlno`. RLS por `auth_home_id()`.
  `pgcrypto` está en el esquema `extensions`. Última migración: 0048.
- No ejecutar SQL de prueba largo en producción (se corta a 60 s).

## Preferencias de Tessa (producto y textos)
- Nada que huela a IA: sin destellos/estrellitas, sin decir "IA".
- Textos cortos, sin sobreexplicar ni ejemplos cutres. Siempre mayúscula
  inicial. Nombres en español (p. ej. modos del plan).
- Fotos de producto de Open Food Facts (se ven enteras, `contain` sobre
  blanco), no Unsplash. El usuario puede poner su foto.
- Eliminar pide confirmación ("¿Eliminar…?"); vaciar/quitar en bloque, además,
  deshacer. Los avisos con acción llevan `persist: false`. Háptica en acciones.
- Trabajar con autonomía y entregar en PR; respuestas en español.

## Mapa del código (`apps/prezhome/lib`)
- Navegación: `main_shell.dart` + barra `packages/prez_ui/lib/src/floating_nav_bar.dart`
  (se desliza el dedo para cambiar). Pestañas en `tabs/`.
- Diseño: `theme/` (`AppColors`, `AppTextStyles` Plus Jakarta Sans,
  `AppRadius`, `AppSpacing`, `AppMotion`). Modo oscuro: `AppColors` son
  getters claro/oscuro según `AppColors.dark`, que fija `main.dart` según
  `theme/theme_preference.dart` (claro por defecto; Claro/Oscuro/Sistema en
  Hogar y ajustes; sin sesión, siempre claro) (no usar `const` con `AppColors`; nada de `Colors.white`
  para superficies: `AppColors.card`). Widgets comunes: `widgets/empty_state.dart`,
  `widgets/list_skeleton.dart`, `widgets/food_image.dart`.
- Ilustraciones (de Tessa, PNG 512 transparentes) en `assets/images/`:
  poses `miau_*` (`MiauMood`),
  `vacio_*` (EmptyState `image:`), `zona_<etiqueta>` (Mi cocina), `onb_*`.
- Offline: `services/offline_repository.dart` (+ `offline_merge.dart`,
  `supabase_remote_sender.dart`, `offline_provider.dart`). Ids locales
  `local-`. Errores permanentes (`PermanentSyncError`) se descartan.
- Compra: `shopping_list_screen.dart`, `services/shopping_checkout.dart`
  (comprado → despensa por zona, "Todo comprado", tarea "compra" completada
  marca la lista), `services/plan_shopping.dart` (lista desde el plan).
- Fotos: `services/product_photo_resolver.dart` (caché `food_photo_cache` →
  búsqueda OFF), `services/product_search_service.dart` (8/min, caché; las
  búsquedas en segundo plano solo pueden gastar 4 para no bloquear a la persona).
  Las fotos de OFF se comparten entre hogares en `product_photo_shared` (solo
  URLs de OFF; las de galería no salen del hogar; claves `v2|<nombre>`).
  Solo se pone foto sola si el producto es claramente el buscado
  (`productMatchScore`/`confidentProductPhoto`): mejor sin foto que errónea.
  Toda foto de OFF guardada se comprueba leyendo el producto por su código
  de barras (`photoMatches`, `productByCode`) y, si no es ese producto, se
  cambia o se quita. La búsqueda quita resultados sin relación (`rankProducts`).
- Chips: el seleccionado va en `AppColors.wood` con texto en tinta (tema).
- Despensa ("Mi cocina"): `inventory_screen.dart` (zonas en rejilla de 3, sin
  deslizar, como pestañas +
  "Revisar"; filas compactas; une repetidos con `findPantryDuplicates`; repinta
  con `OfflineRepository.changes`), `services/shelf_life.dart`
  (`pantryZoneFor`; categorías válidas: Despensa, Nevera, Congelador,
  Especias, Bebidas, Limpieza, Hogar).
- Plan de comidas: un solo calendario, `meal_plan_screen.dart` (semana con
  flechas; va dentro de Comidas > Plan con `embedded: true`; no hay vista de
  mes). La pestaña Hoy usa icono de casa, no de calendario.
- Tareas: `tasks_screen.dart` (anillo de hoy, tarjetas por tipo con icono y
  color de `utils/task_kinds.dart`, próximos días, hechas hoy; nueva tarea en
  hoja con tareas típicas; editar/más opciones con `AddTaskScreen(task:)`).
  Si solo hay una persona no se pregunta quién la hizo.
- Plan de comidas (código): `services/meal_planner.dart`,
  `meal_prep_*`. Recetas: `recipes_screen.dart`, `recipe_detail_screen.dart`,
  `cook_mode_screen.dart` (paso a paso con `CookStep`, varios temporizadores,
  pantalla encendida, manos libres por voz: `services/hands_free.dart` +
  `utils/cook_voice.dart`), `utils/recipe_steps.dart`. Tanda:
  `batch_prep_timeline_screen.dart` (cada receta se prepara antes de ir a su
  aparato; acaba con el reparto en tápers del `PrepBatch`).
- Gasto y datos: `stats_screen.dart` ("Tus datos": gráficas de gasto con
  previsión `services/spend_forecast.dart`, compra, despensa, comidas y
  tareas; se abre desde Inicio y Hogar). `economy_screen.dart` = "Gastos y
  tickets" (siempre visible; puntos solo con Modo Puntos, `showPoints`).
  Escanear ticket: `scan_ticket_screen.dart`.
- Hogar e invitaciones: `household_screen.dart`, `services/home_invites.dart`
  (códigos de 8 caracteres, 7 días, 10 usos; RPC `create_home_invite`,
  `join_home_with_code`, `remove_home_member`, `leave_home`).
- Edge Functions: `supabase/functions/` (validan JWT).

## Pendiente
- Tessa: activar "Leaked password protection" en Supabase Auth.
- Ofrecido, sin decidir: precios con Open Prices; selector manual claro/oscuro.
