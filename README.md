# Prez

Monorepo de las apps Prez (Flutter + Supabase):

| Carpeta | Contenido |
|---------|-----------|
| `apps/prezhome/` | App **PrezHome** (organización del hogar). Proyecto Flutter completo. |
| `packages/prez_ui/` | Componentes de interfaz compartidos (barra flotante…). |
| `supabase/` | Migraciones y Edge Functions, compartidas por todas las apps. |
| `docs/` | Documentación de producto y guías. |

Más adelante se añadirá `apps/prezwallet/` (ver
[docs/PREZWALLET.md](docs/PREZWALLET.md) §6).

## Empezar

```bash
cd apps/prezhome
flutter pub get
flutter run
```

Comprobaciones que ejecuta el CI (desde `apps/prezhome`):

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Automatizacion CI/CD y secrets

El repositorio incluye automatizacion con GitHub Actions (integracion continua,
despliegue de migraciones de Supabase y validacion de cambios). Para que funcione
hay que configurar algunos secrets en GitHub, y esos los configura la usuaria
porque contienen credenciales de Supabase y de Google.

La guia paso a paso, en espanol y pensada para una persona no tecnica, esta en
[docs/CI_CD_SECRETS.md](docs/CI_CD_SECRETS.md).

## Fotos automaticas en las recetas

Las recetas pueden mostrar una foto automatica (de Unsplash) cuando se crean con
la IA. La app funciona igual sin configurarlo (con dibujos cozy por tipo de
plato), y la guia sencilla para activarlo esta en
[docs/RECETAS_FOTOS.md](docs/RECETAS_FOTOS.md).

## Producto

- [docs/ESTRATEGIA.md](docs/ESTRATEGIA.md): perfiles, apps independientes, personalización y publicación en tiendas.
- [docs/PREZHOME.md](docs/PREZHOME.md): visión de PrezHome (quitar carga mental).
- [docs/PREZWALLET.md](docs/PREZWALLET.md): app hermana de gastos y patrimonio.
- [docs/REDISENO.md](docs/REDISENO.md): revisión de la app y plan del rediseño integral.

## Arquitectura y refactor

Para apoyar el rediseño de la app hay una base de arquitectura en:

- [apps/prezhome/docs/architecture/review.md](apps/prezhome/docs/architecture/review.md)
- [apps/prezhome/docs/architecture/refactor-plan.md](apps/prezhome/docs/architecture/refactor-plan.md)
- `apps/prezhome/docs/architecture/dependency-map.md` (generado, no versionado;
  el CI lo publica como artefacto `dependency-map`)

Comandos útiles (desde `apps/prezhome`):

- Generar mapa de dependencias (no se commitea, está en `.gitignore`):
  `dart run tool/architecture/dependency_map.dart`
