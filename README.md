# prezhome

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Automatizacion CI/CD y secrets

El repositorio incluye automatizacion con GitHub Actions (integracion continua,
despliegue de migraciones de Supabase y validacion de cambios). Para que funcione
hay que configurar algunos secrets en GitHub, y esos los configura la usuaria
porque contienen credenciales de Supabase y de Google.

La guia paso a paso, en espanol y pensada para una persona no tecnica, esta en
[docs/CI_CD_SECRETS.md](docs/CI_CD_SECRETS.md).
