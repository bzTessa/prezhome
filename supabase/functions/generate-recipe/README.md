# Edge Function: `generate-recipe`

Rellena una receta con IA (Google Gemini) de forma segura. La API key vive como
secreto en el servidor — NUNCA en la app Flutter.

## Requisitos previos
- Tener el **Supabase CLI** instalado (`npm i -g supabase` o ver docs oficiales).
- Una **API key de Gemini** de Google AI Studio: https://aistudio.google.com/apikey
  (empieza por `AIza...`). No confundir con la suscripción de la app Gemini.

## Despliegue (una sola vez)

Desde la raíz del proyecto (`prezhome/`):

```bash
# 1. Vincular el CLI a tu proyecto (te pedirá elegir el proyecto)
supabase link --project-ref ubrihtnnkbwcbchvvlno

# 2. Guardar la API key de Gemini como SECRETO (no va al repo ni al cliente)
supabase secrets set GEMINI_API_KEY=AIza_tu_clave_aqui

# 3. Desplegar la función
supabase functions deploy generate-recipe
```

> `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` los inyecta Supabase
> automáticamente en el entorno de la función; no hay que configurarlos.

## Requisito de base de datos
Antes de usarla, ejecuta la migración `0004_ai_usage.sql` en el SQL Editor
(crea la RPC `consume_ai_credit` y el control de límite mensual).

## Cómo la usa la app
`AddRecipeScreen` llama a `supabase.functions.invoke('generate-recipe', body: {query})`.
La función valida la sesión, comprueba el límite mensual de IA del hogar
(`subscriptions.ai_monthly_limit`), llama a Gemini y devuelve `{ recipe: {...} }`.

## Límite de IA
Cada llamada consume 1 crédito del hogar. El límite por defecto es 20/mes
(`subscriptions.ai_monthly_limit`) y se resetea automáticamente cada mes.
Si se supera, la función devuelve HTTP 429.
