# PrezWallet · Gastos y patrimonio sin esfuerzo

> Documento de producto de la app hermana de [PrezHome](PREZHOME.md).
> Mismo backend, mismo login, misma familia visual.

## 1. La idea en una frase

**Saber en 5 segundos cuánto gasto, cuánto tengo y si voy bien.**

Fusión de tres referencias:

| Referencia            | Qué cogemos                                                   |
|-----------------------|---------------------------------------------------------------|
| **Mis Gastos**        | Apuntar un gasto en 2 toques: rejilla de categorías con icono, teclado numérico. Resumen mensual con donut por categoría y barras de %. |
| **Wallet (BudgetBakers)** | Varias cuentas, presupuestos, flujo de caja, tendencia de saldo, clasificación **Necesidad / Deseo / Obligación**. Importación bancaria (fase avanzada). |
| **getquin**           | Patrimonio neto, cartera de inversión (acciones, ETF, cripto), distribución en donut, calendario y gráfico de **dividendos** por año. |
| **Barra de @marcodev04** | Navegación flotante en píldora + botón "+" aparte (ver PREZHOME.md §5.1). |

Regla de oro (igual que PrezHome): **apuntar tiene que costar menos que no
apuntar.** Si no, no se usa.

## 2. Para quién

- **Personal**: mis cuentas, mis inversiones, mi patrimonio. **Privado por
  defecto.**
- **Hogar**: gastos compartidos con los miembros del hogar (súper, alquiler,
  facturas). Visibles para todo el hogar, como en PrezHome.

Cada movimiento es *personal* o *del hogar*; esa es la única pregunta extra.

Perfil principal: persona de 25–40 años en España que empieza a ordenar su
dinero y a invertir, con el dinero repartido en varias apps. Fuera de alcance:
traders y autónomos que emiten facturas. Detalle en
[ESTRATEGIA.md](ESTRATEGIA.md) §1. La app funciona completa **sin** PrezHome
(ESTRATEGIA.md §2).

## 3. Pestañas

**Inicio · Movimientos · Patrimonio · Análisis** + **[+]** (nuevo movimiento).

### 3.1 Inicio
- Saldo disponible del mes (ingresos – gastos) y patrimonio neto total.
- Barra de presupuesto del mes ("llevas 640 € de 900 €").
- Próximos recibos (7 días).
- Últimos 5 movimientos.

### 3.2 Movimientos
- Lista por día con icono de categoría, nota y cuenta (estilo Mis Gastos).
- Selector de mes arriba; filtros por cuenta, categoría, personal/hogar.
- Recurrentes / suscripciones en una sección propia.

### 3.3 Patrimonio
- **Patrimonio neto** = activos – deudas, con gráfico de evolución.
- Activos: cuentas, efectivo, inversiones, vivienda/vehículo (valor manual).
- Deudas: hipoteca, préstamos, tarjetas.
- **Cartera** (estilo getquin): posiciones, valor actual, rentabilidad,
  distribución por tipo/sector y **dividendos** (recibidos y previstos por año).

### 3.4 Análisis
- Donut por categoría + lista con % (Mis Gastos).
- Comparativa mes a mes / año.
- Necesidad vs Deseo vs Obligación (Wallet).
- Gasto total en súper por mes y frente al presupuesto. (El detalle por
  producto, súper y comida vive en PrezHome: ver PREZHOME.md §2.)

### 3.5 Botón [+]
Hoja inferior: importe grande → rejilla de categorías → (opcional) nota, cuenta,
personal/hogar. Guardar con el importe ya escrito y una categoría = 2 toques.
Atajos: escanear ticket (reutiliza `scan-ticket` de PrezHome), repetir último.

### 3.6 Registro de pagos con un toque (notificación)

Idea: pagas con el móvil o la tarjeta → te salta una notificación de
PrezWallet → un toque y queda apuntado con el sitio y el importe.

```
 PrezWallet                                   ahora
 12,30 € en MERCADONA · Supermercado · Hogar
 [ Registrar ]   [ Cambiar ]   [ Ignorar ]
```

**Cómo detecta el pago:**
- **Android (primero, es tu móvil):** la app pide permiso de *acceso a
  notificaciones* (`NotificationListenerService`) y lee **solo** las
  notificaciones de pago de las apps que tú elijas (app del banco, Google
  Wallet). De "Has pagado 12,30 € en MERCADONA" saca importe y comercio, y
  lanza su propia notificación con botones. Todo se procesa en el móvil; el
  texto original no se sube a ningún sitio.
- **iOS (más adelante):** iOS no deja leer notificaciones de otras apps. La
  alternativa es una automatización de Atajos ("Al pulsar la tarjeta en
  Wallet") que abre PrezWallet con importe y comercio ya rellenos.
- **Banco conectado (fase 6):** cuando exista, sirve de red de seguridad para
  los pagos que no generen notificación, con deduplicación por importe+fecha.

**Que sea de verdad "un solo toque":**
- La app **aprende comercio → categoría / cuenta / personal-hogar**
  (`wallet_bills         id, owner_id, home_id?, provider, category_id, amount,
                     rrule, next_date, remind_days_before, is_shared
wallet_bill_docs     id, bill_id, period_start, period_end, amount, file_path
wallet_risk_profile  user_id, answers jsonb, profile (conservative|moderate|
                     dynamic), updated_at
wallet_merchants`). La primera vez en "MERCADONA" eliges; las siguientes
  ya viene sugerido y "Registrar" basta.
- Para comercios de confianza: opción **"registrar siempre sin preguntar"**
  (solo se avisa, con opción de deshacer).
- Si el comercio es un súper → crea el "ticket pendiente" en PrezHome.

**Ajustes (todo desactivable):**
- Interruptor general "Detectar pagos" (apagado por defecto).
- Qué apps vigilar (lista de apps instaladas con interruptor por app).
- Por comercio: preguntar / registrar automático / ignorar siempre.
- "Pagos sin registrar": bandeja con los que ignoraste o no contestaste, por
  si quieres apuntarlos luego.

### 3.7 Facturas y recibos

Facturas **que recibes** (luz, agua, gas, internet, móvil, seguros, alquiler,
IBI, suscripciones). No es para emitir facturas (eso es otro producto).

- **Recibo recurrente** con importe, día de cargo y cuenta. Aviso unos días
  antes (y en la pantalla Hoy de PrezHome si la usas).
- **Archivo**: foto o PDF de cada factura (Supabase Storage, privado), con
  importe y periodo leídos con la misma IA que los tickets.
- **Detectar cambios**: "tu factura de luz ha subido un 18 % respecto a la
  media de los últimos 6 meses", "esta suscripción no la has usado…" (solo lo
  que se pueda saber con tus datos).
- **Gasto fijo mensual**: suma de todos los recibos = lo que te cuesta vivir
  antes de gastar nada. Es la cifra que más tranquiliza o más alerta.
- Compartidas con el hogar si se marcan así (alquiler, luz…).

### 3.8 Sugerencias de cartera según tu perfil

Sí, pero con cuidado: **recomendar a una persona concreta qué producto
financiero comprar es asesoramiento de inversión**, una actividad regulada en
España (necesita autorización de la CNMV). Una app sin esa licencia no puede
decir "compra este fondo". Lo que sí puede hacer, y es lo útil:

- **Test de perfil** (horizonte, tolerancia a caídas, objetivo, colchón de
  emergencia) → resultado educativo: "tu perfil es moderado".
- **Analizar tu propia cartera con datos, no con órdenes**:
  - Diversificación: "el 62 % de tu cartera está en una sola empresa".
  - Coherencia con tu perfil: "tu cartera tiene un riesgo más alto que el
    perfil que indicaste".
  - Costes: "pagas un 1,8 % anual en comisiones de este fondo".
  - Colchón: "tu fondo de emergencia cubre 2 meses de tus gastos fijos"
    (aquí se juntan gastos y patrimonio: lo que ninguna referencia hace).
- **Carteras de ejemplo genéricas** por perfil (p. ej. "80 % renta variable
  global / 20 % renta fija") como contenido educativo, **sin nombrar productos
  concretos ni enlazar a brókers**.
- Aviso visible: "Información educativa, no es asesoramiento financiero".
- Antes de publicar esta parte: **consultarlo con alguien experto en
  regulación financiera**. Este documento no es una opinión legal.

## 4. Modelo de datos (borrador)

Todas las tablas con RLS: lo personal por `user_id`, lo compartido por `home_id`
(mismo patrón que PrezHome). Prefijo `wallet_` para no chocar con tablas
existentes.

```
wallet_accounts      id, owner_id, home_id?, name, type (bank|cash|card|
                     investment|property|loan), currency, opening_balance,
                     is_shared, archived
wallet_categories    id, owner_id?, home_id?, name, icon, color, kind
                     (expense|income), nature (need|want|must)
wallet_transactions  id, account_id, category_id, amount, date, note,
                     is_shared, merchant_id?,
                     source (manual|ticket|notification|import|recurring),
                     ticket_id?  -> enlace con tickets de PrezHome
wallet_recurring     id, account_id, category_id, amount, rrule, next_date,
                     remind_days_before
wallet_budgets       id, scope (user|home), category_id?, month, amount
wallet_holdings      id, account_id, symbol, name, asset_type, quantity,
                     avg_price, currency
wallet_dividends     id, holding_id, pay_date, amount_per_share, total
wallet_merchants     id, owner_id, raw_name, display_name, category_id,
                     account_id, is_shared, mode (ask|auto|ignore)
                     -> lo que aprende el registro con un toque (§3.6)
wallet_snapshots     id, owner_id, date, net_worth, assets, liabilities
                     (foto diaria/semanal para el gráfico de evolución)
```

Migración de lo existente: `expenses` y `budgets` de PrezHome se copian a
`wallet_transactions` / `wallet_budgets` (cuenta "Hogar", `is_shared = true`)
y la pantalla `economy_screen.dart` se retira de PrezHome cuando PrezWallet
esté en uso.

## 5. Fases

| Fase | Contenido | Resultado |
|------|-----------|-----------|
| **1. Apuntar** | Cuentas manuales, categorías, [+] rápido, lista de movimientos, Inicio básico. | Ya sustituye a Mis Gastos. |
| **1b. Un toque** | Detección de pagos por notificación en Android + aprendizaje de comercios (§3.6). | Apuntar deja de ser un esfuerzo. |
| **2. Entender** | Análisis (donut, comparativas, necesidad/deseo), presupuestos por categoría, **facturas y recibos** con avisos y archivo (§3.7). | Sabes en qué se va el dinero. |
| **3. Conectar con PrezHome** | Tickets → movimientos, presupuesto de súper en la lista de compra, recibos → pantalla Hoy. | Las dos apps trabajan juntas. |
| **4. Patrimonio** | Activos/deudas manuales, patrimonio neto, snapshots y gráfico de evolución. | Foto completa de tu dinero. |
| **5. Inversiones** | Posiciones, precios automáticos (Edge Function + API de cotizaciones), dividendos, distribución, test de perfil y análisis de cartera (§3.8). | Sustituye a getquin. |
| **6. Automatizar** | Importar CSV/Excel del banco; más adelante agregador bancario PSD2 (Edge Function, nunca claves en la app). | Casi no hay que apuntar a mano. |

## 6. Arquitectura técnica

- **Flutter + Supabase**, igual que PrezHome. **Mismo proyecto Supabase** (un
  único login para las dos apps).
- Repositorio: **monorepo** (la app PrezHome ya vive en `apps/prezhome`):

```
apps/
  prezhome/        (la app actual)
  prezwallet/      (nueva)
packages/
  prez_core/       auth, cliente Supabase, sesión, hogar/miembros
  prez_ui/         tema Cozy, tokens, FloatingNavBar, Miau, tarjetas
supabase/          migraciones y Edge Functions compartidas
```

  Hecho: `apps/prezhome` + `supabase/` compartido. Pendiente: crear
  `packages/` y `apps/prezwallet`, y entonces unirlos con *pub workspaces*
  (Dart 3.6+) para tener un único `pubspec.lock`.
- Claves de APIs externas (cotizaciones, bancos) solo en **Edge Functions**
  como secrets de Supabase, nunca en el cliente (ver `AGENTS.md`).
- Cálculos (patrimonio, presupuestos, % por categoría) como **lógica pura y
  testeable** en `services/`, como ya se hace en PrezHome.

## 7. Diseño

- Misma barra flotante y tokens que PrezHome (paquete `prez_ui`), y los mismos
  estilos personalizables (ESTRATEGIA.md §3).
- Estilo por defecto **Clean** (sobrio, se lee como app de dinero) con acento
  **verde salvia**; quien quiera puede elegir Cozy.
- Miau (si está activado) en estados vacíos y celebraciones (presupuesto
  cumplido, nuevo máximo de patrimonio). Diseño pendiente: ver
  ESTRATEGIA.md §5. Sin emojis en la interfaz.
- Cifras grandes y legibles; negativos en tono cálido suave, no rojo chillón.

## 8. Preguntas abiertas

- ¿Moneda única (EUR) o multimoneda desde el inicio? (Propuesta: EUR primero,
  campo `currency` ya preparado.)
- ¿Los miembros del hogar ven el patrimonio de los demás? (Propuesta: no,
  solo lo marcado como compartido.)
- ¿Hasta dónde llegan las sugerencias de cartera? Validar con un experto en
  regulación antes de la fase 5 (§3.8).
- ¿Qué fuente de cotizaciones? Decidir en la fase 5 según coste y cobertura de
  ETFs europeos.
