// ============================================================================
// PrezHome · Edge Function: generate-recipe
// ============================================================================
// Rellena una receta con IA (Google Gemini) de forma SEGURA:
//   - La GEMINI_API_KEY vive como secreto del servidor (nunca en el cliente).
//   - Valida la sesión del usuario (JWT) y obtiene su home_id.
//   - Comprueba y consume el límite mensual de IA vía RPC consume_ai_credit
//     (usando la service_role key, para que el cliente no pueda saltárselo).
//   - Llama a Gemini pidiendo JSON estructurado y lo devuelve al cliente.
//
// Despliegue (lo hace la usuaria):
//   supabase secrets set GEMINI_API_KEY=AIza...
//   supabase functions deploy generate-recipe
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Prompt que fuerza a Gemini a devolver el esquema exacto que usa la app.
function buildPrompt(query: string): string {
  return `Eres un asistente de cocina experto. El usuario te da el NOMBRE de una
receta o bien PEGA una receta completa (con ingredientes, cantidades, pasos...).
En ambos casos, extrae/deduce y estructura los datos.

Si el texto ya trae ingredientes y cantidades, respétalos tal cual. Si faltan
macros o calorías, ESTÍMALOS de forma razonable. Si es solo un nombre, genera una
receta estándar.

Petición del usuario:
"""
${query}
"""

Responde SOLO con un objeto JSON válido (sin texto adicional, sin markdown) con
exactamente esta forma:
{
  "title": string,
  "description": string,
  "servings": number,
  "meal_types": string[],  // uno o varios de: "breakfast","lunch","dinner","snack","dessert"
  "appliance": "none" | "oven" | "stovetop" | "pot" | "airfryer" | "microwave",
  "prep_minutes": number,
  "cook_minutes": number,
  "freezable": boolean,
  "calories_per_serving": number,
  "grams_per_serving": number,  // peso aproximado en gramos de UNA ración ya preparada
  "protein_grams": number,
  "carbs_grams": number,
  "fat_grams": number,
  "ingredients": [ { "name": string, "quantity": number, "unit": string } ],
  "instructions": string  // pasos de preparación numerados, separados por saltos de línea
}

En "meal_types" incluye TODAS las comidas para las que sirva la receta (por
ejemplo ["lunch","dinner"] si vale para comida y cena; usa "dessert" para postres).
Los macros y calorías son POR RACIÓN. Estima "grams_per_serving" (el peso en
gramos de una ración del plato ya preparado). Usa gramos/ml/unidades en "unit".
En "instructions" escribe los pasos claros y numerados (1., 2., 3., ...).
Escribe todo el contenido en español.`;
}

// Consulta a Google qué modelos hay disponibles para esta key y devuelve los que
// soportan generateContent, ordenados con los "flash" primero (más rápidos/baratos).
async function pickModels(apiKey: string): Promise<string[]> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`,
    );
    if (!res.ok) {
      console.error("ListModels error:", res.status, await res.text());
      return [];
    }
    const data = await res.json();
    const models: string[] = (data?.models ?? [])
      .filter((m: any) =>
        Array.isArray(m?.supportedGenerationMethods) &&
        m.supportedGenerationMethods.includes("generateContent")
      )
      .map((m: any) => m.name as string);

    // Priorizar flash > resto; evitar modelos de solo-imagen/embedding.
    const usable = models.filter(
      (n) => !n.includes("embedding") && !n.includes("aqa"),
    );
    usable.sort((a, b) => {
      const score = (n: string) =>
        n.includes("flash") ? 0 : n.includes("pro") ? 1 : 2;
      return score(a) - score(b);
    });
    return usable;
  } catch (e) {
    console.error("ListModels exception:", e);
    return [];
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  try {
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!geminiKey || !supabaseUrl || !serviceKey) {
      return json({ error: "Configuración del servidor incompleta" }, 500);
    }

    // 1. Validar sesión del usuario a partir del JWT enviado por la app
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) {
      return json({ error: "Sesión inválida" }, 401);
    }
    const userId = userData.user.id;

    // 2. Obtener el home_id del usuario (maybeSingle para no lanzar si no hay fila)
    const { data: profile, error: profErr } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userId)
      .maybeSingle();
    if (profErr) {
      return json(
        { error: `No se pudo leer el perfil: ${profErr.message}` },
        500,
      );
    }
    if (!profile) {
      return json(
        { error: `No existe perfil para el usuario ${userId}` },
        400,
      );
    }
    if (!profile.home_id) {
      return json(
        { error: "El usuario no pertenece a ningún hogar" },
        400,
      );
    }
    const homeId = profile.home_id as string;

    // 3. Leer y validar la petición
    const body = await req.json().catch(() => ({}));
    const query = (body?.query ?? "").toString().trim();
    if (!query) {
      return json({ error: "Falta el nombre o descripción de la receta" }, 400);
    }
    if (query.length > 8000) {
      return json({ error: "La petición es demasiado larga" }, 400);
    }

    // 4. Comprobar y consumir el límite mensual de IA (server-side)
    const { data: allowed, error: creditErr } = await admin.rpc(
      "consume_ai_credit",
      { target_home_id: homeId },
    );
    if (creditErr) {
      return json({ error: "No se pudo verificar el límite de IA" }, 500);
    }
    if (allowed !== true) {
      return json(
        { error: "Has alcanzado tu límite mensual de IA. Inténtalo el mes que viene." },
        429,
      );
    }

    // 5. Descubrir qué modelos soporta ESTA key (los nombres cambian con el
    // tiempo, así que no los fijamos). Pedimos la lista y filtramos los que
    // soportan generateContent, priorizando modelos "flash".
    const models = await pickModels(geminiKey);
    if (models.length === 0) {
      return json(
        {
          error:
            "Tu clave no tiene modelos de Gemini disponibles para generar contenido. "
            + "Revisa que la API de Gemini esté habilitada en tu proyecto de Google.",
        },
        502,
      );
    }

    const requestBody = JSON.stringify({
      contents: [{ parts: [{ text: buildPrompt(query) }] }],
      generationConfig: { responseMimeType: "application/json" },
    });

    let geminiData: unknown;
    let lastError = "";
    for (const model of models) {
      // model ya viene como "models/xxx"; usamos v1beta
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/${model}:generateContent?key=${geminiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: requestBody,
        },
      );
      if (res.ok) {
        geminiData = await res.json();
        break;
      }
      lastError = `${model}: HTTP ${res.status} — ${await res.text()}`;
      console.error("Gemini error:", lastError);
      if (res.status === 401 || res.status === 403) break;
    }

    if (geminiData === undefined) {
      return json(
        { error: `Error de la IA → ${lastError.substring(0, 400)}` },
        502,
      );
    }

    const text: string | undefined =
      (geminiData as any)?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return json(
        {
          error:
            "La IA no devolvió texto. Puede haber bloqueado la respuesta por seguridad. Prueba con otra receta.",
        },
        502,
      );
    }

    let recipe: unknown;
    try {
      recipe = JSON.parse(text);
    } catch (_e) {
      return json({ error: "La IA devolvió un formato inesperado" }, 502);
    }

    return json({ recipe });
  } catch (e) {
    console.error(e);
    return json({ error: "Error inesperado en el servidor" }, 500);
  }
});
