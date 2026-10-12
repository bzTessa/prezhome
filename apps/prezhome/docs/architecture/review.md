# Architecture Review · Estado actual

Este diagnóstico documenta los principales puntos de acoplamiento observados en
`lib/` para preparar una refactorización gradual sin romper comportamiento.

## Hallazgos principales

1. **Capas mezcladas en el mismo nivel de carpetas**
   - Hay pantallas, dominio y utilidades coexistiendo en raíz de `lib/`.
   - Muchas pantallas importan servicios, modelos y otras pantallas a la vez.

2. **Dependencias inversas entre capas**
   - `utils/` y `services/` dependen de `widgets/` en varios puntos.
   - Esto acopla lógica de negocio con presentación y complica pruebas unitarias
     puras.

3. **Navegación y composición con alto fan-in**
   - `tabs/home_tab.dart` y `main_shell.dart` concentran muchas importaciones de
     features diferentes.
   - Es una señal de crecimiento horizontal sin límites claros de módulos.

4. **Ausencia de guardas automáticas de arquitectura**
   - No había una validación recurrente de dependencias internas por módulo.
   - Cualquier PR podía aumentar acoplamiento sin visibilidad estructural.

## Objetivo de este paquete de cambios

- Hacer visible el grafo de módulos de `lib/`.
- Crear una base de refactor por fases pequeñas.
- Añadir una guarda de CI para detectar desviaciones estructurales temprano.
