# PrezHome · La app que te quita carga mental

> Documento de producto. Complementa a [VISION.md](VISION.md) (roadmap de comidas
> y meal prep) y a [PREZWALLET.md](PREZWALLET.md) (la app hermana de dinero).

## 1. La idea en una frase

**PrezHome se acuerda de las cosas de casa para que tú no tengas que hacerlo.**

No es una app de "gestionar el hogar" (eso ya es trabajo). Es una app que:
1. **Recoge** todo lo que te ronda la cabeza (comidas, compra, tareas, cosas que
   caducan, revisiones, papeles).
2. **Decide por defecto** lo razonable (qué comer, qué comprar, a quién le toca).
3. **Te avisa solo cuando hace falta**, con una única pantalla de "Hoy".

Regla de oro: si una función obliga a pensar más de lo que ahorra, sobra o va
escondida en Ajustes.

Perfiles principales: quien lleva la casa en la cabeza (pareja o
convivientes que cocinan en casa) y quien hace meal prep. La app funciona
completa **sin** PrezWallet. Detalle en [ESTRATEGIA.md](ESTRATEGIA.md).

## 2. Separación con PrezWallet

| Pregunta                         | App        |
|----------------------------------|------------|
| ¿Qué como / qué compro / qué hago hoy en casa? | PrezHome   |
| ¿Cuánto me gasto / cuánto tengo / cómo van mis inversiones? | PrezWallet |

### Regla para repartir: el *qué* frente al *cuánto*

Un mismo ticket del súper tiene dos lecturas, y cada app se queda la suya:

| Del ticket…                                   | Lo usa     | Para responder |
|-----------------------------------------------|------------|----------------|
| **Las líneas** (producto, precio, súper)      | PrezHome   | ¿Dónde está más barato el aceite? ¿Cuánto me cuesta esta receta / el plan de la semana? ¿En qué comida se me va el dinero? |
| **El total** (importe, fecha, comercio, cuenta) | PrezWallet | ¿Cuánto llevo de súper este mes? ¿Voy dentro del presupuesto? |

Así que **los tickets se quedan en PrezHome**: es donde se escanean y donde se
analiza el gasto *por producto, por súper y por comida*, porque esas
respuestas sirven para decidir qué comprar y dónde. PrezWallet solo recibe el
total como un movimiento más. Ver sección 7.

## 3. Estado actual (qué ya existe)

Pestañas hoy (`lib/main_shell.dart`): **Hoy · Tareas · Meal Prep · Despensa · Hogar**.

- **Comidas:** recetas (con IA, importar enlace, foto), perfil nutricional,
  plan semanal que se reajusta, meal prep / batch cooking, raciones por persona.
- **Despensa:** inventario por niveles (ingrediente / preparado / plato listo),
  nevera y congelador con caducidades, escáner de código de barras.
- **Compra:** listas por categorías, memoria de precios, escaneo de tickets.
- **Tareas:** recurrencias, puntos por esfuerzo, marketplace de recompensas.
- **Infra:** Supabase con RLS por hogar, realtime, modo offline con cola de sync.
- **Economía:** `economy_screen.dart` + tablas `expenses` y `budgets` (básico).
  → **Candidato a migrar a PrezWallet.**

Lo que falta no es tanto funcionalidad como **simplicidad y diseño**: hay
muchas piezas, pero la sensación de "la app piensa por mí" aún no llega.

## 4. Pilares

### 4.1 Hoy (el corazón)
Una sola pantalla que responde "¿qué tengo que hacer hoy en casa?":
- Qué se come hoy y si hay que sacar algo del congelador para mañana.
- Tareas de hoy (las mías y las del hogar), ordenadas por urgencia.
- Avisos proactivos: "caduca el pollo el jueves", "te queda poco aceite".
- Máximo 5–7 tarjetas. Lo demás, en su pestaña.

### 4.2 Comer (Meal Prep + Despensa)
Ya es lo más avanzado. Siguiente paso según `VISION.md`: planificador que use el
congelador, registro "por defecto se hizo" y lista de la compra para X días.

### 4.3 Compra
Una lista que **se escribe sola** a partir del plan y del inventario, con precio
estimado (memoria de precios) para saber cuánto va a costar antes de ir.

**Tickets y precios** (se quedan aquí, ver §2):
- Escanear ticket → líneas a `ticket_items` + `product_prices`, y repone la
  despensa.
- Estadísticas de cocina, no de finanzas: gasto por **súper**, por
  **categoría de comida** (carne, fruta, snacks…), **coste por receta / ración**
  y coste del plan semanal; "este producto es un 20 % más barato en X".
- Sugerencia útil, no informe: "si compras estos 6 productos en X ahorras
  ~8 € al mes".

### 4.4 Tareas y rutinas
- Rutinas recurrentes con reparto justo entre miembros.
- **Mantenimiento del hogar** (nuevo): filtros, revisión caldera, ITV, cambio de
  sábanas, limpiar nevera… con recurrencias largas (meses / años).
- **Bandeja de entrada mental** (nuevo): botón "+" para soltar cualquier cosa en
  2 segundos ("comprar regalo a mamá", "llamar al fontanero"). Luego la app
  propone convertirlo en tarea, compra o recordatorio.

### 4.5 Hogar
Miembros, ajustes, módulos activables (cada quien ve solo lo que usa).

## 5. Diseño

### 5.1 Barra inferior flotante (referencia: vídeo de @marcodev04)
Es el patrón que se adopta para **las dos apps**, para que se sientan familia:

```
 ╭──────────────────────────────────────────╮   ╭───╮
 │  ⌂     ☰     ▣    (▮ Análisis)           │   │ + │
 ╰──────────────────────────────────────────╯   ╰───╯
```

- **Píldora flotante** separada de los bordes (margen ~16 px), esquinas
  totalmente redondeadas, fondo claro con sombra suave. El contenido se ve por
  detrás al hacer scroll.
- Pestañas inactivas: **solo icono**.
- Pestaña activa: se **expande** en una cápsula con fondo tintado del color de
  marca + icono + texto. Transición animada (ancho + fundido del texto,
  ~250 ms, `AppMotion`).
- **Botón "+" circular aparte**, a la derecha, con el color de marca sólido. Es
  la acción rápida principal (en PrezHome: bandeja de entrada / añadir; en
  PrezWallet: nuevo movimiento).
- Máximo 4 pestañas + el "+".

Propuesta de pestañas PrezHome: **Hoy · Comer · Tareas · Hogar** + **[+]**.
(Despensa y Compra pasan a vivir dentro de "Comer" con pestañas superiores.)

Implementación: widget propio `FloatingNavBar` en un paquete compartido
(ver sección 7) que sustituye al `NavigationBar` de `main_shell.dart`, con
`extendBody: true` en el `Scaffold`.

### 5.2 Estilo
- Estilo por defecto **Cozy** (amarillo pastel, madera clara, tarjetas
  redondeadas) con Presidente Miau. Sin emojis en la interfaz.
- **Personalizable**: estilo Clean u Oscuro, color de acento, mascota sí/no y
  tono de los textos. Ver [ESTRATEGIA.md](ESTRATEGIA.md) §3.
- Tokens ya existentes en `lib/theme/` (spacing, radius, elevation, motion,
  text styles): todo componente nuevo debe usarlos.
- Una idea por tarjeta, mucho aire, textos cortos.

## 6. Prioridades (orden propuesto)

1. **Rediseño de navegación**: barra flotante + 4 pestañas + "+".
2. **Pantalla Hoy** limpia (máx. 7 tarjetas, prioridad por urgencia).
3. **Bandeja de entrada mental** detrás del "+".
4. Lista de la compra automática desde plan + inventario (peldaño 7 de VISION).
5. Mantenimiento del hogar (recurrencias largas).
6. Sacar `Economía` de PrezHome y llevarla a PrezWallet.

## 7. Conexión con PrezWallet

Decisión recomendada: **dos apps, un mismo backend**.

- **Mismo proyecto Supabase** → misma cuenta, mismo login, mismo `home_id`.
  Iniciar sesión en una deja el usuario listo en la otra.
- **Paquete compartido** (`packages/prez_core`): cliente Supabase, auth, tema
  Cozy, `FloatingNavBar`, Miau. Las dos apps lo importan → mismo look & feel.
- **Puentes concretos** (solo los que aportan):
  - Ticket escaneado en PrezHome → crea un **movimiento** en PrezWallet
    con el total (categoría Supermercado). Las líneas se quedan en PrezHome.
  - Pago en un súper registrado en PrezWallet (notificación de pago, ver
    PREZWALLET.md §3.6) → en PrezHome aparece "**ticket pendiente**" para
    escanearlo si quieres el desglose. Al escanearlo se enlaza al mismo
    movimiento, no se duplica.
  - Lista de la compra muestra "**te quedan X € del presupuesto de súper**"
    (dato que vive en PrezWallet).
  - Recibos / suscripciones de PrezWallet (luz, IBI, seguro) → **recordatorio**
    en la pantalla Hoy de PrezHome unos días antes.
  - Deep links: tocar un gasto en PrezHome abre PrezWallet en ese movimiento.

Ver detalle técnico y modelo de datos en [PREZWALLET.md](PREZWALLET.md).
