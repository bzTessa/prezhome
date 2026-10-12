# prez_ui

Componentes de interfaz compartidos por las apps Prez.

- `FloatingNavBar`: barra inferior flotante en píldora. Las pestañas
  inactivas muestran solo el icono; la activa se expande con icono + texto.
  Opcionalmente, un botón circular de acción rápida a la derecha ("+").

Uso desde una app del monorepo (`apps/<app>/pubspec.yaml`):

```yaml
dependencies:
  prez_ui:
    path: ../../packages/prez_ui
```

Tests: `flutter test` desde esta carpeta.
