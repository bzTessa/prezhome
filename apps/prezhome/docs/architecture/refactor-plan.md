# Refactor Plan · Arquitectura objetivo

Plan incremental para reducir acoplamiento y mejorar mantenibilidad sin reescritura.

## Estructura objetivo

```
lib/
  app/                # arranque, shell, rutas, tema global
  core/               # utilidades compartidas y contratos comunes
  features/
    <feature>/
      data/           # acceso a Supabase/APIs, mappers, DTOs
      domain/         # entidades y reglas puras
      presentation/   # pantallas, widgets y estado UI
```

## Reglas de dependencia

1. `presentation` puede depender de `domain` y `core`.
2. `data` puede depender de `domain` y `core`.
3. `domain` solo depende de `core` (o nada).
4. `core` no depende de `features`.
5. Ninguna utilidad de negocio puede depender de `widgets` o pantallas.

## Fases de ejecución

### Fase 1 · Baseline y visibilidad
- Mantener el mapa de dependencias versionado en `docs/architecture`.
- Revisar en cada PR los cruces con mayor volumen.

### Fase 2 · Separación de UI y lógica
- Mover lógica no visual fuera de pantallas y widgets hacia `services`/`domain`.
- Eliminar dependencias de `utils` y `services` hacia `widgets`.

### Fase 3 · Vertical slice por features
- Agrupar por dominios funcionales (recetas, despensa, tareas, meal-plan).
- Reducir imports cruzados entre features por APIs internas claras.

### Fase 4 · Endurecimiento de reglas
- Añadir comprobaciones de límites de capas por carpetas objetivo.
- Exigir cumplimiento de reglas antes de merge.

## Criterio de éxito

- Módulos con dependencias dirigidas y estables.
- Menos imports cruzados entre áreas no relacionadas.
- Cambios de producto localizados por feature y más fáciles de testear.
