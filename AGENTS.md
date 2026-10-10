# prezhome - Guidelines for AI Agents

## Tech Stack
- Frontend: Flutter (Dart)
- Backend: Supabase (Auth, Database, Storage)

## Database Context
- Las tablas y esquemas de base de datos están descritos en supabase_schema.sql (o explica aquí tus tablas: tareas, gastos, etc.).

## Rules
- Mantén el código modular en la carpeta /lib.
- Siempre ejecuta `flutter pub get` si añades nuevos paquetes a `pubspec.yaml`.
- No toques claves secretas directamente en el código; usa variables de entorno o constantes de configuración.
