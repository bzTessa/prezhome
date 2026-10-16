# PrezHome · Sistema de Diseño y Reglas de UX

Aplica estas reglas en TODO cambio de interfaz de PrezHome. PrezHome evoluciona
hacia un **"Asistente de Vida Proactivo"** para rutinas del hogar y batch
cooking. La identidad es **Warm Tactile** (cálida, cercana, con la mascota del
logo) y la ejecución debe sentirse **profesional, viva e interactiva**.

## 0bis. El nombre de la mascota no aparece nunca
Ningún texto de la interfaz (títulos, avisos, banners, estados vacíos,
etiquetas de accesibilidad) nombra a la mascota. Se habla de forma genérica
("Asistente", "Consejo del día", "Compañero de cocina") o solo de la acción.
La mascota es apoyo visual: imágenes estáticas movidas con transformaciones
(flotar, squish, saltito), nunca animación por fotogramas.

## 0. Regla de oro: PROHIBIDO el término "IA"
La interfaz **nunca** muestra "IA", "Inteligencia Artificial", "AI", "modelo",
"GPT", "Gemini" ni jerga equivalente al usuario. Son conceptos internos.

En su lugar, usa lenguaje de producto cercano:
- "Sugerencias predictivas" / "Sugerencias para ti"
- "Tu asistente de cocina" / "Consejo del día"
- "Planificando…" / "Pensando una idea…" / "Preparando sugerencias…"

Esto aplica a textos visibles, labels de botones, títulos, placeholders,
snackbars, estados de carga y mensajes de error de cara al usuario. El código,
los comentarios y los nombres de edge functions (p. ej. `generate-recipe`)
pueden seguir siendo técnicos; lo que se veta es lo que **ve la usuaria**.

## 1. Tokens y tema global
- Fuente única de verdad: `apps/prezhome/lib/theme/app_theme.dart` y los tokens asociados
  (`AppColors`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppTextStyles`,
  `AppMotion`). **No** introducir literales de color `0xFF…`, paddings a ojo ni
  tamaños de fuente sueltos: usar siempre los tokens.
- Paleta Cozy: cream/wood/woodDark/ink + pares pastel (sage, terracotta, peach,
  frost) + estados de caducidad (fresh/soon/expired). Reutilizar; ampliar solo
  con justificación y sin romper nombres existentes.
- Grises: usar `AppColors.inkMuted`, nunca `Colors.grey[xxx]`.

## 2. Forma: radios y superficies
- Radios: `AppRadius.lg` (20) tarjetas grandes y hojas, `AppRadius.md` (14)
  celdas de despensa, tareas y compra y campos, `AppRadius.sm` (10) botones y
  chips, `AppRadius.pill` solo para píldoras.
- Superficies táctiles: borde carbón `AppColors.stroke` de 1,5–2 px y sombra
  dura sin desenfoque (`AppElevation.level1` = 3 px, `level2` = 6 px,
  `pressed` = 0: la pieza baja al pulsar). Usar `AppTheme.surfaceDecoration`
  o `AppTheme.tactileDecoration`; nada de sombras difusas.

## 3. Motion Design — animaciones "cero esfuerzo"
Objetivo: dar vida a una app con **PNGs estáticos** de la mascota, sin Lottie
(la usuaria no aporta archivos Lottie) y sin recargar la UX ni el rendimiento.

- Librería de animación: usar el paquete **`flutter_animate`** cuando simplifique
  (efectos declarativos encadenables: `.animate()`, shimmer, scale, slide,
  shake, fadeIn, elastic) **o** las utilidades nativas ya existentes del repo
  (`AppMotion`, `PressScale`, `StaggeredEntrance`, `AnimatedCounter`,
  `Celebrate`). Preferir reutilizar lo que ya hay; añadir `flutter_animate` solo
  si aporta y declararlo en `pubspec.yaml`.
- Duraciones suaves (~150–350 ms), curvas con mesura (easeOut / easeOutBack /
  elastic solo para celebraciones puntuales).
- **Accesibilidad**: honrar `MediaQuery.disableAnimations` (reduce motion). Con
  el flag activo, renderizar el estado final estático sin perder función.
- Rendimiento: nada que bloquee el scroll ni anime listas enteras en bucle.

### Efectos aplicados a los PNG de Miau según estado vacío (empty states)
Las poses viven en `assets/images/` y se muestran vía el widget
`MiauCharacter`. Cada estado vacío usa una pose + un efecto concreto:

| Pose (PNG)              | Dónde                                   | Efecto de animación                                   |
|-------------------------|-----------------------------------------|-------------------------------------------------------|
| `miau_saludando.png`    | Solo en **Onboarding**                  | Entrada suave (fade + scale de bienvenida)            |
| `miau_pensando.png`     | **Búsqueda sin resultados** o **despensa vacía** | Balanceo suave continuo (rotación/translación leve)   |
| `miau_cocinando.png`    | **Pantalla de recetas vacía**           | **Slide** entrando desde abajo                        |
| `miau_durmiendo.png`    | **0 tareas pendientes**                 | Efecto "respiración" (scale lento 1.0↔~1.04 en bucle) |
| `miau_celebrando.png`   | Al **vaciar la lista de la compra**     | Rebote **elástico** + **confeti por código** (sin assets externos) |

Regla: un empty state de PrezHome **siempre** muestra a Miau con su pose y
efecto correctos y un texto cercano (sin tono de error).

## 4. Formularios
- `TextFormField` con `OutlineInputBorder` de radio `AppRadius.md`.
- Campos de contraseña: `suffixIcon` de ojo para alternar `obscureText`.
- Respetar `SafeArea`; el teclado nunca debe tapar los botones de acción
  (usar scroll/`resizeToAvoidBottomInset` y padding por el inset del teclado).

## 5. Lenguaje y tono
- Todo en **español**, cercano y claro, pensado para una usuaria no técnica.
- Preferir verbos de acción y mensajes breves. La app habla en primera persona
  con calidez ("Te he preparado…"), sin nombrar a la mascota.
- No inventar cifras ni datos. Los importes/aproximados deben etiquetarse como
  tales ("coste estimado", "aprox.").

## 6. Checklist antes de dar por terminada una pantalla
1. ¿Aparece en algún sitio la palabra "IA"/"AI"? → eliminar y reemplazar.
2. ¿Radios y sombras de los tokens (`AppRadius`, `AppElevation`)? ¿Sale el nombre
   de la mascota en algún texto?
3. ¿El empty state usa la pose + efecto de Miau que toca?
4. ¿Las animaciones respetan reduce-motion?
5. ¿Formularios con SafeArea y sin que el teclado tape acciones?
