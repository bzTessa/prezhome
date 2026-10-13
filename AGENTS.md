# prezhome - Guidelines for AI Agents

**Al empezar, lee `docs/MEMORIA.md`** (comandos, preferencias, mapa del código y
pendientes). Úsalo en vez de explorar el repo y mantenlo al día.

## Estructura (monorepo)
- `apps/prezhome/`: app PrezHome (Flutter). Los comandos de Flutter se ejecutan desde ahí.
- `packages/prez_ui/`: componentes de interfaz compartidos entre apps (sin colores propios: cada app pasa los suyos).
- `supabase/`: migraciones y Edge Functions compartidas.
- `docs/`: documentación de producto (PREZHOME.md, PREZWALLET.md, ESTRATEGIA.md).

## Tech Stack
- Frontend: Flutter (Dart)
- Backend: Supabase (Auth, Database, Storage)

## Database Context
- Las tablas y esquemas de base de datos están descritos en supabase_schema.sql (o explica aquí tus tablas: tareas, gastos, etc.).

## Rules
- Mantén el código modular en la carpeta `lib/` de cada app (p. ej. `apps/prezhome/lib`).
- Siempre ejecuta `flutter pub get` (desde la carpeta de la app) si añades nuevos paquetes a su `pubspec.yaml`.
- No toques claves secretas directamente en el código; usa variables de entorno o constantes de configuración.
