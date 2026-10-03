# Fotos automáticas en las recetas

Esta guía está pensada para ti, Tessa, en lenguaje sencillo y sin tecnicismos.
Explica cómo hacer que las recetas que crea la app con inteligencia artificial
salgan **con una foto bonita automáticamente**, usando un banco de imágenes
gratuito llamado **Pexels**.

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
app buscará una foto apropiada en Pexels y la pondrá sola. Si por lo que sea no
encuentra foto, no pasa nada: se queda el dibujo cozy y la receta se guarda
igual.

## Paso 1: crear una cuenta en Pexels y conseguir la clave

1. Entra en la web de Pexels para desarrolladores: <https://www.pexels.com/api/>.
2. Crea una cuenta gratuita (o entra si ya tienes una).
3. Pide tu **API Key** (es como una contraseña larga que identifica a la app).
   Pexels te la da en su panel. Cópiala y guárdala a mano un momento.

La clave es gratuita y es solo para buscar fotos. No cuesta dinero ni gasta los
créditos de inteligencia artificial de la app.

## Paso 2: guardar la clave en Supabase (el "cerebro" de la app)

La clave hay que guardarla como un **secret** (un dato privado) en Supabase.
Esto se hace una sola vez, con este comando (sustituye `TU_CLAVE_AQUI` por la
clave que te dio Pexels):

```
supabase secrets set PEXELS_API_KEY=TU_CLAVE_AQUI
```

## Paso 3: activar la función de las fotos

La parte de la app que busca las fotos se llama `recipe-photo` y hay que
"encenderla" una vez con este comando:

```
supabase functions deploy recipe-photo
```

A partir de aquí, las recetas nuevas creadas con la IA saldrán con foto
automáticamente.

## Resumen rápido

| ¿Qué quiero? | ¿Qué hago? |
| --- | --- |
| Usar la app tal cual | Nada. Ya funciona (rediseño, dibujos cozy y filtros). |
| Ponerle foto a una receta a mano | Como siempre, desde la propia receta. |
| Que las recetas con IA salgan con foto solas | Los pasos 1, 2 y 3 de esta guía. |

Si en algún momento quieres dejar de usar las fotos automáticas, basta con no
configurar la clave: la app seguirá funcionando con los dibujos cozy.
