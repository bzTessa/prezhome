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

const GEMINI_MODEL = "gemini-2.0-flash";

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
  return `Eres un asistente de cocina. Genera los datos de una receta a partir de
esta petición del usuario: "${query}".

Responde SOLO con un objeto JSON válido (sin texto adicional, sin markdown) con
exactamente esta forma:
{
  "title": string,
  "description": string,
  "servings": number,
  "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
  "appliance": "none" | "oven" | "stovetop" | "pot" | "airfryer" | "microwave",
  "prep_minutes": number,
  "cook_minutes": number,
  "freezable": boolean,
  "calories_per_serving": number,
  "protein_grams": number,
  "carbs_grams": number,
  "fat_grams": number,
  "ingredients": [ { "name": string, "quantity": number, "unit": string } ]
}

Los macros y calorías son POR RACIÓN. Usa gramos/ml/unidades en "unit".
Escribe el contenido en español.`;
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

    // 2. Obtener el home_id del usuario
    const { data: profile, error: profErr } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userId)
      .single();
    if (profErr || !profile?.home_id) {
      return json({ error: "El usuario no pertenece a ningún hogar" }, 400);
    }
    const homeId = profile.home_id as string;

    // 3. Leer y validar la petición
    const body = await req.json().catch(() => ({}));
    const query = (body?.query ?? "").toString().trim();
    if (!query) {
      return json({ error: "Falta el nombre o descripción de la receta" }, 400);
    }
    if (query.length > 500) {
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

    // 5. Llamar a Gemini pidiendo JSON estructurado
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: buildPrompt(query) }] }],
          generationConfig: { responseMimeType: "application/json" },
        }),
      },
    );

    if (!geminiRes.ok) {
      const detail = await geminiRes.text();
      console.error("Gemini error:", detail);
      return json({ error: "El servicio de IA no está disponible ahora mismo" }, 502);
    }

    const geminiData = await geminiRes.json();
    const text: string | undefined =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return json({ error: "La IA no devolvió una receta válida" }, 502);
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
