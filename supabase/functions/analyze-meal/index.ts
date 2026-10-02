// ============================================================================
// PrezHome · Edge Function: analyze-meal
// ============================================================================
// Lee la foto de un plato con Gemini (visión) e identifica los alimentos,
// estimando por cada uno sus calorías y macros (proteína, carbohidratos,
// grasa). La estimación por foto es APROXIMADA: la usuaria debe revisarla y
// corregirla antes de registrarla en su diario personal.
//
// Seguridad: valida JWT, obtiene home_id con service_role, controla el límite
// mensual de IA (consume_ai_credit). El crédito de IA es por hogar aunque el
// diario sea personal. La API key vive como secreto del servidor.
//
// Despliegue (manual, esta función NO se despliega sola):
//   supabase functions deploy analyze-meal
// (usa el mismo secreto GEMINI_API_KEY ya configurado)
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

// Descubre los modelos de Gemini con visión disponibles para la key, ordenados
// (flash primero). Devuelve una lista para poder reintentar si alguno da 404.
async function pickModels(apiKey: string): Promise<string[]> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`,
    );
    if (!res.ok) return [];
    const data = await res.json();
    const models: string[] = (data?.models ?? [])
      .filter((m: any) =>
        Array.isArray(m?.supportedGenerationMethods) &&
        m.supportedGenerationMethods.includes("generateContent")
      )
      .map((m: any) => m.name as string)
      .filter((n: string) => !n.includes("embedding") && !n.includes("aqa"));
    // Prioriza flash; luego los de version mas alta (heuristica por nombre).
    models.sort((a, b) => {
      const fa = a.includes("flash") ? 0 : 1;
      const fb = b.includes("flash") ? 0 : 1;
      if (fa !== fb) return fa - fb;
      return b.localeCompare(a); // nombres "mayores" primero (3.8 antes que 2.5)
    });
    return models;
  } catch (_e) {
    return [];
  }
}

function buildPrompt(): string {
  return `Eres un asistente de nutrición que mira la foto de un plato de comida.
Identifica los ALIMENTOS que ves en la imagen y estima, para cada uno, su
cantidad y sus valores nutricionales.

IMPORTANTE: la estimación a partir de una foto es APROXIMADA. No tienes forma de
pesar los alimentos con exactitud, así que da tu mejor estimación razonable. La
persona revisará y corregirá estos datos antes de guardarlos.

Devuelve SOLO un objeto JSON válido (sin markdown, sin texto alrededor) con esta
forma exacta:
{
  "items": [
    {
      "name": string,            // nombre del alimento en español
      "estimated_grams": number, // cantidad aproximada en gramos (opcional, 0 si no puedes estimarla)
      "calories": number,        // calorías aproximadas de esa cantidad (kcal)
      "protein": number,         // proteína aproximada en gramos
      "carbs": number,           // carbohidratos aproximados en gramos
      "fat": number              // grasa aproximada en gramos
    }
  ],
  "total_calories": number,      // suma aproximada de las calorías de todos los items
  "note": string                // nota breve en español (p. ej. aviso de que es una estimación)
}

Reglas:
- Usa 0 en cualquier valor numérico que no puedas estimar.
- Si no reconoces ninguna comida en la imagen, devuelve "items" como lista vacía ([]) y "total_calories" en 0.
- No inventes alimentos que no se vean en el plato.`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  try {
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!geminiKey || !supabaseUrl || !serviceKey) {
      return json({ error: "Configuración del servidor incompleta" }, 500);
    }

    const jwt = (req.headers.get("Authorization") ?? "")
      .replace("Bearer ", "")
      .trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) return json({ error: "Sesión inválida" }, 401);
    const userId = userData.user.id;

    const { data: profile, error: profErr } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userId)
      .maybeSingle();
    if (profErr) {
      return json({ error: `No se pudo leer el perfil: ${profErr.message}` }, 500);
    }
    if (!profile?.home_id) {
      return json({ error: "El usuario no pertenece a ningún hogar" }, 400);
    }
    const homeId = profile.home_id as string;

    const body = await req.json().catch(() => ({}));
    const imageBase64 = (body?.image_base64 ?? "").toString();
    const mimeType = (body?.mime_type ?? "image/jpeg").toString();
    if (!imageBase64) {
      return json({ error: "Falta la imagen del plato" }, 400);
    }

    // Límite mensual de IA (por hogar, aunque el diario sea personal)
    const { data: allowed, error: creditErr } = await admin.rpc(
      "consume_ai_credit",
      { target_home_id: homeId },
    );
    if (creditErr) return json({ error: "No se pudo verificar el límite de IA" }, 500);
    if (allowed !== true) {
      return json(
        { error: "Has alcanzado tu límite mensual de IA. Inténtalo el mes que viene." },
        429,
      );
    }

    const models = await pickModels(geminiKey);
    if (models.length === 0) {
      return json(
        { error: "No hay modelos de Gemini disponibles para tu clave." },
        502,
      );
    }

    const requestBody = JSON.stringify({
      contents: [
        {
          parts: [
            { text: buildPrompt() },
            { inline_data: { mime_type: mimeType, data: imageBase64 } },
          ],
        },
      ],
      generationConfig: { responseMimeType: "application/json" },
    });

    let geminiData: any;
    let lastError = "";
    for (const model of models) {
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
      // 401/403 = problema de clave, no tiene sentido reintentar
      if (res.status === 401 || res.status === 403) break;
      // 404 (modelo retirado) u otros: probamos el siguiente modelo
    }

    if (geminiData === undefined) {
      return json(
        { error: `Error de la IA -> ${lastError.substring(0, 300)}` },
        502,
      );
    }

    const text: string | undefined =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return json({ error: "La IA no devolvió datos del plato" }, 502);

    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch (_e) {
      return json({ error: "La IA devolvió un formato inesperado" }, 502);
    }

    return json({ meal: parsed });
  } catch (e) {
    console.error(e);
    return json({ error: "Error inesperado en el servidor" }, 500);
  }
});
