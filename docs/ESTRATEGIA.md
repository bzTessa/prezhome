# Estrategia común · PrezHome + PrezWallet

> Decisiones que afectan a las dos apps: para quién son, cómo conviven, cómo se
> personalizan y qué hace falta para publicarlas. Detalle de cada app en
> [PREZHOME.md](PREZHOME.md) y [PREZWALLET.md](PREZWALLET.md).

## 1. Perfiles a los que van dirigidas

Una app que intenta servir a todo el mundo acaba sin servir a nadie. Se eligen
**perfiles principales** (se diseña para ellos) y **secundarios** (se aceptan,
no se optimiza para ellos todavía).

### PrezHome

| Perfil | Quién es | Qué le duele | Qué le damos |
|--------|----------|--------------|--------------|
| **Principal: "Quien lleva la casa en la cabeza"** | 25–40 años, vive en pareja o con alguien, trabaja, cocina en casa casi a diario. Suele ser una sola persona la que se acuerda de todo. | Carga mental: qué comemos, qué falta, qué caduca, quién hace qué. Sensación de reparto injusto. | Pantalla Hoy, plan de comidas que se ajusta solo, compra automática, reparto de tareas visible y justo. |
| **Principal: "Meal prep / comer bien"** | Cocina en lote, controla kcal o macros, quiere ahorrar tiempo entre semana. | Planificar lotes, congelador, raciones. | Lo que ya está construido (meal prep, congelador, raciones por persona). |
| Secundario: piso compartido | Compañeros de piso. | Tareas y gastos comunes. | Tareas + gastos del hogar. Sin funciones de "quién debe a quién" por ahora. |
| Secundario: familia con niños | — | Muchas más variables (cole, extraescolares). | Funciona lo básico; no se diseña para ello todavía. |

### PrezWallet

| Perfil | Quién es | Qué le duele | Qué le damos |
|--------|----------|--------------|--------------|
| **Principal: "Empiezo a ordenar mi dinero"** | 25–40 años en España, sueldo fijo, quiere ahorrar y ha empezado (o quiere empezar) a invertir: fondos indexados, ETFs, cuenta remunerada, algo de cripto, plan de pensiones. Usa neobancos/brókers (Trade Republic, MyInvestor, Indexa…). | Tiene el dinero repartido en 4–6 apps y no sabe cuánto tiene en total ni en qué se le va. | Gastos en 1 toque + patrimonio neto en una sola pantalla + cartera clara. |
| **Principal: hogar que comparte gastos** | El mismo usuario de PrezHome. | Gastos comunes (súper, alquiler, facturas). | Movimientos "del hogar" y facturas compartidas. |
| Fuera de alcance | Traders activos, autónomos que **emiten** facturas, empresas. | — | Otro producto. Se dice claramente para no prometer lo que no hay. |

**Lo que diferencia a las dos apps de las referencias:** en español y pensadas
para España (productos, bancos, impuestos, euro), **sin anuncios**, privadas
por defecto y simples. Mis Gastos tiene anuncios; Wallet y getquin son
genéricas y en inglés de origen.

### Cómo se usan los perfiles en la app
El onboarding pregunta **qué quieres resolver** (no datos personales) y activa
los módulos que tocan. Ya existe el mecanismo en PrezHome
(`HomeModule` en `lib/models/dashboard_prefs.dart`); PrezWallet usa el mismo:
quien no invierte no ve la pestaña de cartera, quien vive solo no ve "hogar".

## 2. Dos apps independientes, un mismo ecosistema

Mucha gente usará **solo una** de las dos. Por eso:

- **Cada app es completa por sí sola.** Dos fichas distintas en las tiendas,
  dos identificadores (`com.prez.home` / `com.prez.wallet`, a definir), y
  ninguna función esencial depende de tener la otra.
  - PrezHome sin PrezWallet: sigue escaneando tickets y viendo gasto por súper,
    producto y comida.
  - PrezWallet sin PrezHome: el hogar es opcional; las facturas, gastos y
    patrimonio funcionan igual.
- **Los puentes aparecen solo si usas las dos** con la misma cuenta (ticket →
  movimiento, recibo → aviso en Hoy, presupuesto de súper en la lista de
  compra). Si no, ni se mencionan, salvo una invitación discreta y
  desactivable.
- **Una cuenta "Prez"** sirve para las dos: si un día instalas la otra, entras
  sin registrarte de nuevo y ya está conectada.

Esto es una decisión de **producto**. El **repositorio** puede seguir siendo
uno solo (monorepo con `apps/prezhome`, `apps/prezwallet` y `packages/`): de
cada carpeta de `apps/` sale una app distinta para la tienda. Que compartan
código no las acopla para el usuario, igual que dos apps de un mismo
estudio comparten librerías internas.

## 3. Personalización: no a todo el mundo le gusta lo cozy

Lo cozy es la **identidad por defecto de PrezHome**, no una obligación.

### 3.1 Estilos (temas completos)

| Estilo | Para quién | Rasgos |
|--------|-----------|--------|
| **Cozy** (defecto PrezHome) | Quien quiere algo cálido y cercano. | Crema, amarillo pastel, madera, esquinas muy redondeadas, Miau visible. |
| **Clean** (defecto PrezWallet) | Quien prefiere algo sobrio. | Blanco/gris neutro, un color de acento, esquinas medias, sin ilustraciones. |
| **Oscuro** | Uso de noche o preferencia. | Variante oscura de cualquiera de los dos. |
| *(Android)* **Color del sistema** | Quien usa Material You. | Acento tomado del fondo de pantalla. |

Además, ajustes sueltos que combinan con cualquier estilo:
- **Color de acento** (5–6 opciones probadas en claro y oscuro).
- **Mascota sí / no**: Miau se puede ocultar (a parte de los adultos les
  resulta infantil; en dinero puede restar seriedad).
- **Tono de los textos**: cercano ("¡Hoy toca sacar el pollo!") o neutro
  ("Sacar pollo del congelador").
- **Densidad**: cómoda o compacta.
- Respetar el **tamaño de letra** y **modo oscuro** del sistema.

### 3.2 Cómo se construye (para que no sea un infierno mantenerlo)
- Ningún componente usa colores, radios o sombras "a pelo": todo sale de
  **tokens semánticos** (`surface`, `accent`, `positive`, `radiusCard`…) vía
  `ThemeExtension`. Los tokens de `lib/theme/` ya van en esa dirección.
- Un estilo = un conjunto de valores para esos tokens. Añadir uno nuevo no
  toca pantallas.
- Ilustraciones y mascota detrás de un widget que decide según el estilo
  (Cozy → Miau; Clean → icono simple o nada).
- Los textos con tono van en un único sitio (claves de traducción con dos
  variantes), lo que además deja preparada la app para otros idiomas.

## 4. Preparado para App Store y Play Store

Cosas que conviene tener en cuenta **desde ya**, porque cambiarlas luego cuesta:

**Cuenta y privacidad**
- **Borrar la cuenta desde la propia app** (obligatorio en ambas tiendas) y
  también desde una web.
- Si hay login con Google, en iOS hay que ofrecer también **Iniciar sesión con
  Apple** (o equivalente que cumpla sus reglas de privacidad).
- **Política de privacidad** pública y formularios de privacidad de cada tienda
  (Data safety en Play, etiquetas de privacidad en Apple).
- Datos personales/financieros: privados por defecto, RLS en todo (ya es así),
  exportar mis datos (CSV).

**Permisos sensibles**
- Lectura de notificaciones (pagos en PrezWallet): pedirla con una pantalla
  propia que explique qué se lee y para qué, nunca en el arranque, y la app
  debe funcionar sin ella. Revisar la política de Play vigente antes de enviar.
- Cámara (tickets, códigos de barras): explicar el uso en el texto del permiso.

**Dinero**
- Play pide una **declaración de funciones financieras** a todas las apps.
- Suscripción Pro: dentro de la app debe pagarse con el sistema de compras de
  cada tienda. La tabla `subscriptions` ya existe; una cuenta Pro podría
  desbloquear las dos apps validándola en el backend.
- **Sugerencias de inversión**: ver PREZWALLET.md §3.8. Es el punto con más
  riesgo legal.

**Técnico**
- Identificadores de app, nombres e iconos definitivos antes de la primera
  subida (luego no se pueden cambiar en Play).
- Entornos separados: Supabase de desarrollo y de producción.
- Textos de la app en archivos de traducción (aunque solo haya español).
- Cuentas de desarrollador: Apple (cuota anual) y Google Play (pago único).

## 5. Identidad visual (pendiente)

Logo, iconos de app e ilustraciones de Miau los aporta la propietaria del
proyecto con sus propios diseños. Este documento no fija el estilo; solo lo
que hará falta técnicamente cuando lleguen:

**Iconos de app (por cada app)**
- Original en vectorial (SVG) o PNG de 1024×1024 como mínimo.
- Android: capa de fondo + capa delantera (lo importante dentro del 66 %
  central) y, opcional, versión monocromo para los iconos temáticos.
- iOS: cuadrado opaco, sin transparencias ni esquinas redondeadas (las pone
  el sistema).
- Comprobar que se reconoce a 48 px (tamaño real en la pantalla de inicio).

**Logo con nombre**: versión para fondo claro y para fondo oscuro.

**Ilustraciones de Miau** (PNG transparente, 500×500 o más, mismo encuadre):
hoy la app usa `MiauCharacter` (`lib/widgets/miau_character.dart`) en unas
20 pantallas con estas poses, que se sustituyen sin tocar código si se
mantienen los nombres de archivo de `assets/images/`:

| Pose (`MiauMood`) | Archivo | Uso típico |
|-------------------|---------|-----------|
| `greeting` / `neutral` | `miau_saludando.png` | Bienvenida, estados por defecto |
| `celebrating` | `miau_celebrando.png` | Tarea hecha, logros |
| `cooking` | `miau_cocinando.png` | Recetas, meal prep |
| `curious` | `miau_pensando.png` | Sugerencias, "próximamente", vacíos |
| `sleeping` | `miau_durmiendo.png` | Sin pendientes, descanso |

Al llegar los diseños también se actualizan la pantalla de carga, el icono
web/manifest y el nombre visible de la app ("PrezHome").
