# Rediseño integral de PrezHome · revisión y plan

> Revisión de la app (octubre 2026) para hacerla más práctica, coherente y
> personalizable para distintos tipos de público (ver perfiles en
> [ESTRATEGIA.md](ESTRATEGIA.md) §1). Cifras medidas sobre `apps/prezhome/lib`.

## 1. Ya hecho

| Cambio | Qué resuelve |
|--------|--------------|
| Barra inferior flotante (`packages/prez_ui`) | Navegación más limpia y la misma en PrezWallet. |
| "Meal Prep" → **Comida**; "Batch Cooking" → **Cocina en lote** | Sin anglicismos; se entiende para cualquier público. |
| **Fotos de recetas**: búsqueda con idioma correcto, nombre en inglés de la IA, "Otra foto" que trae una distinta, sin fotos de envases para platos | Las fotos fallaban o salían genéricas, y "buscar otra" repetía la misma. |
| **Lista de la compra** rediseñada: campo "Añadir producto" que entiende "2 kg tomates", cabecera compacta con progreso y coste, secciones ligeras, opciones de vista guardadas | Se veía recargada, añadir era lento y dos botones flotantes tapaban la lista. |
| Erratas de tildes en compra y asistente de perfil | Aspecto descuidado. |

## 2. Hallazgos

### 2.1 Navegación
- **La lista de la compra está escondida**: Despensa → pestaña "Compra" (2 toques).
  Es probablemente lo más usado de la app.
- **"Hogar" ocupa una pestaña** pero es sobre todo ajustes (miembros,
  economía, perfil nutricional). Los ajustes no suelen merecer pestaña.
- **No hay acción rápida global** ("apunta esto"): para añadir una tarea, un
  producto o un gasto hay que ir primero a su pantalla.

### 2.2 Coherencia visual
- **67 colores escritos a mano** fuera del tema (los que más: alta de receta 21,
  perfil nutricional 20, detalle de receta 8) y **183 usos de
  `Colors.grey/red/...`** sueltos. Por eso cada pantalla se ve un poco distinta,
  y es lo que impide tener estilos (Clean/Oscuro): hoy cambiar el tema no
  cambiaría esos colores.
- **19 emojis en la interfaz** (iconos de categoría, marcadores de recetas
  sin foto, Inicio), aunque la guía de diseño dice "sin emojis".
- **14 formularios en diálogos** (`AlertDialog`). En móvil se manejan mejor
  como hojas inferiores, con el teclado sin tapar los campos.

### 2.3 Practicidad
- **60 mensajes de error técnicos** enseñados tal cual ("Error: $e",
  "No se pudo …: PostgrestException(...)"). Deberían ser frases normales con
  una acción ("Sin conexión, se guardará al volver").
- **8 pantallas de más de 1.100 líneas** (lista de la compra antes del
  rediseño 2.100, Inicio 1.670, plan de comidas 1.430, inventario 1.390…).
  Cada cambio es lento y arriesgado; hay que partirlas en piezas como se ha
  hecho con la compra (`widgets/shopping/`).

### 2.4 Personalización y accesibilidad
- **No hay modo oscuro** ni estilos alternativos (ver ESTRATEGIA.md §3).
- **La app no declara el idioma español** (`locale`/`localizationsDelegates`):
  selectores de fecha y textos del sistema pueden salir en inglés.
- Ya existe una buena base: **módulos activables** (`HomeModule`), **tarjetas de
  Inicio reordenables/ocultables** (`DashboardPrefs`) y **estilo de cocina**.

## 3. Propuesta de navegación (decisión pendiente)

Máximo 5 pestañas, con la compra arriba del todo y los ajustes fuera:

| Hoy | Comida | **Compra** | Despensa | Tareas* |
|-----|--------|------------|----------|---------|

- **Compra** pasa a pestaña propia.
- **Hogar/ajustes** pasa a un botón de perfil arriba a la derecha en Hoy.
- **Tareas*** solo si el módulo está activo (como hoy).
- El **"+" de la barra** abre "Añadir rápido": producto a la compra, tarea,
  receta o gasto.

## 4. Personalización para distintos públicos

1. **Primer uso**: "¿Qué quieres que te resuelva?" (comidas, compra, tareas,
   cocina en lote, gastos). Activa solo esos módulos y elige la pestaña de
   inicio. Ya existe el mecanismo: falta la pantalla.
2. **Estilo**: Cozy (por defecto), Clean, Oscuro; color de acento; Miau sí/no.
   Requiere antes el punto 2.2 (colores del tema).
3. **Densidad**: cómoda / compacta (la compra ya tiene la suya: fotos sí/no,
   agrupar por pasillo).
4. **Tono de textos**: cercano o neutro.

## 5. Plan por fases (un PR cada una)

| Fase | Contenido | Por qué en este orden |
|------|-----------|-----------------------|
| **1. Base** | Español declarado en la app; mensajes de error amables (una función común); emojis → iconos. | Rápido, se nota en toda la app. |
| **2. Navegación** | Compra como pestaña, ajustes al perfil, "+" de añadir rápido. | Lo que más tiempo ahorra cada día. |
| **3. Tokens** | Sustituir colores a mano por colores del tema; formularios a hojas inferiores. | Requisito para los estilos. |
| **4. Pantallas** | Rediseñar y partir Inicio, Plan de comidas e Inventario como se hizo con la compra. | Las más usadas y las más grandes. |
| **5. Estilos** | Clean y Oscuro, acento, Miau sí/no, densidad, tono. | Ya con todo el color en el tema. |
| **6. Primer uso** | Pantalla "¿qué quieres resolver?" que configura módulos. | Cierra la adaptación a cada público. |
