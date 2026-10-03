# Fotos automáticas en las recetas

Esta guía está pensada para ti, Tessa, en lenguaje sencillo y sin tecnicismos.
Explica cómo hacer que las recetas que crea la app con inteligencia artificial
salgan **con una foto bonita automáticamente**, usando un banco de imágenes
gratuito llamado **Unsplash**.

## Lo primero: la app ya funciona sin hacer nada de esto

Muy importante y tranquilizador: **la app ya está lista y funciona perfectamente
sin configurar nada.** Con el rediseño nuevo tienes:

- Las recetas en una rejilla bonita de dos columnas, estilo app moderna.
- Tarjetas con etiquetas de colores (tipo de plato, tiempo, calorías...).
- Un dibujo cálido y cozy en cada receta que todavía no tiene foto (ya no sale
  el cubierto gris triste de antes).
- Filtros para ver solo desayunos, comidas, cenas, snacks, postres, tus
  favoritas o las recetas rápidas.
- Y, como siempre, **puedes ponerle tú una foto a mano a cualquier receta.** Eso
  no ha cambiado y sigue funcionando igual.

Lo único que falta hasta que hagas los pasos de abajo es que las fotos reales
aparezcan **solas** cuando creas una receta con la IA. Mientras tanto, se ve el
dibujo cozy del tipo de plato. Nada se rompe.

## Qué consigues al activar las fotos automáticas

Cuando termines estos pasos, cada vez que crees una receta nueva con la IA, la
app buscará una foto apropiada en Unsplash y la pondrá sola. Si por lo que sea no
encuentra foto, no pasa nada: se queda el dibujo cozy y la receta se guarda
igual.

## Paso 1: crear una app en Unsplash y conseguir la clave

1. Entra en la web de Unsplash para desarrolladores:
   <https://unsplash.com/developers>.
2. Crea una cuenta gratuita (o entra si ya tienes una).
3. Crea una **aplicación nueva** (botón "New Application"). Acepta las
   condiciones y ponle un nombre que reconozcas, por ejemplo "PrezHome fotos".
4. Con el modo de demostración (demo) te sobra: permite **50 peticiones por
   hora**, más que suficiente para las fotos de tus recetas. No hace falta pedir
   producción ni nada especial.
5. En la ficha de la aplicación verás una **Access Key** (clave de acceso). Es
   como una contraseña larga que identifica a la app. Cópiala y guárdala a mano
   un momento.

La clave es gratuita y es solo para buscar fotos. No cuesta dinero ni gasta los
créditos de inteligencia artificial de la app.

## Paso 2: guardar la clave en Supabase (desde la web, sin terminal)

La clave hay que guardarla como un **secret** (un dato privado) dentro de
Supabase. Esto se hace **una sola vez y desde el navegador**, sin escribir
ningún comando. En el panel de Supabase:

1. Entra en tu proyecto en Supabase.
2. Ve a **Edge Functions** y busca el apartado **Secrets** (en algunas versiones
   del panel está en **Project Settings** -> **Edge Functions** -> **Secrets**).
3. Añade un secret nuevo con este nombre, escrito **exactamente** así (en
   mayúsculas y con guion bajo):

   ```
   UNSPLASH_ACCESS_KEY
   ```

4. En el valor, pega la **Access Key** que copiaste de Unsplash en el paso 1.
5. Guarda.

Un solo carácter distinto en el nombre haría que la app no encontrara la clave,
así que cópialo tal cual aparece arriba.

## Paso 3: nada más (se activa solo)

No tienes que hacer nada más. La parte de la app que busca las fotos se llama
`recipe-photo` y **se instala y actualiza sola** mediante la automatización del
proyecto cada vez que hay un cambio en `main`. Ya no hace falta ejecutar ningún
comando como `supabase functions deploy`: se despliega solo.

En cuanto el secret `UNSPLASH_ACCESS_KEY` esté guardado en Supabase, las recetas
nuevas creadas con la IA empezarán a salir con foto automáticamente.

## Resumen rápido

| ¿Qué quiero? | ¿Qué hago? |
| --- | --- |
| Usar la app tal cual | Nada. Ya funciona (rediseño, dibujos cozy y filtros). |
| Ponerle foto a una receta a mano | Como siempre, desde la propia receta. |
| Que las recetas con IA salgan con foto solas | Pasos 1 y 2: crear la app en Unsplash y guardar `UNSPLASH_ACCESS_KEY` en Supabase. |

Si en algún momento quieres dejar de usar las fotos automáticas, basta con no
configurar la clave: la app seguirá funcionando con los dibujos cozy.
