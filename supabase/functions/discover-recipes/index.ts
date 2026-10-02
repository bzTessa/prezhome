// ============================================================================
// PrezHome · Edge Function: discover-recipes
// ============================================================================
// Genera IDEAS de recetas (estilo "mise") según los parámetros del usuario:
// supermercado, objetivo, dieta, electrodomésticos y presupuesto.
// Devuelve varias recetas completas (macros, ingredientes, pasos) en JSON.
//
// Seguridad igual que las otras funciones: JWT, home_id, límite de IA.
// Despliegue: supabase functions deploy discover-recipes
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
    models.sort((a, b) => {
      const fa = a.includes("flash") ? 0 : 1;
      const fb = b.includes("flash") ? 0 : 1;
      if (fa !== fb) return fa - fb;
      return b.localeCompare(a);
    });
    return models;
  } catch (_e) {
    return [];
  }
}

function buildPrompt(p: Record<string, unknown>): string {
  const supermarket = (p.supermarket ?? "").toString().trim();
  const goal = (p.goal ?? "mantener").toString();
  const diet = (p.diet ?? "sin restricción").toString();
  const appliances = Array.isArray(p.appliances)
    ? (p.appliances as string[]).join(", ")
    : "";
  const budget = (p.weekly_budget ?? "").toString();
  const count = Number(p.count ?? 5);

  return `Eres un chef que propone ideas de comidas prácticas. Genera ${count}
ideas de recetas distintas y variadas con estos criterios:
- Supermercado: ${supermarket || "cualquiera"}
- Objetivo nutricional: ${goal}
- Dieta / restricción: ${diet}
- Electrodomésticos disponibles: ${appliances || "cualquiera"}
- Presupuesto semanal aproximado: ${budget || "sin límite"} EUR

Responde SOLO con un JSON válido (sin markdown) con esta forma:
{
  "recipes": [
    {
      "title": string,
      "description": string,
      "meal_types": string[],   // de: "breakfast","lunch","dinner","snack","dessert"
      "appliance": "none"|"oven"|"stovetop"|"pot"|"airfryer"|"microwave",
      "servings": number,
      "prep_minutes": number,
      "cook_minutes": number,
      "freezable": boolean,
      "grams_per_serving": number,
      "calories_per_serving": number,
      "protein_grams": number,
      "carbs_grams": number,
      "fat_grams": number,
      "ingredients": [ { "name": string, "quantity": number o null, "unit": string } ],
      "instructions": string,
      "components": [ { "name": string, "proportion": number } ]
    }
  ]
}

Macros y calorías POR RACIÓN.

MEDIDAS DE LOS INGREDIENTES (muy importante): piensa como quien cocina en casa,
no como un laboratorio. Usa SIEMPRE que puedas MEDIDAS CASERAS Y FÁCILES de
cocina en "unit": taza, cucharada, cucharadita, puñado, unidad, loncha, rodaja,
diente, vaso, lata, bote, pizca, chorro, rebanada, "al gusto"... Esa debe ser la
unidad POR DEFECTO. Usa gramos o ml SOLO cuando sea lo natural de ese alimento
(por ejemplo "200 g de pollo", "150 g de arroz", "100 ml de leche") o cuando no
exista una medida casera clara. Ejemplos: "1 taza de arroz" (quantity 1, unit
"taza"), "2 cucharadas de aceite" (quantity 2, unit "cucharadas"), "1 cebolla"
(quantity 1, unit "unidad" o "" si el nombre ya es contable), "un puñado de
espinacas" (quantity 1, unit "puñado"), "sal al gusto" (quantity null, unit
"al gusto"). Para ingredientes "al gusto" o "a ojo", "quantity" puede ir a null y
la expresión va en "unit". Números REDONDOS y realistas.

En "instructions" es OBLIGATORIO un paso por línea
separado por salto de línea real (\\n), cada uno con su número; NO juntes todo en
un párrafo. En "components" desglosa SIEMPRE el plato en partes con su % del peso
(suman 100); solo [] si es un único alimento homogéneo. Todo en español. Recetas
realistas y variadas, adecuadas al objetivo y la dieta indicados.`;
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

    const { data: profile, error: profErr } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (profErr || !profile?.home_id) {
      return json({ error: "El usuario no pertenece a ningún hogar" }, 400);
    }
    const homeId = profile.home_id as string;

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

    const body = await req.json().catch(() => ({}));

    const models = await pickModels(geminiKey);
    if (models.length === 0) {
      return json({ error: "No hay modelos de Gemini disponibles." }, 502);
    }

    const requestBody = JSON.stringify({
      contents: [{ parts: [{ text: buildPrompt(body) }] }],
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
      if (res.status === 401 || res.status === 403) break;
    }

    if (geminiData === undefined) {
      return json({ error: `Error de la IA -> ${lastError.substring(0, 300)}` }, 502);
    }

    const text: string | undefined =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return json({ error: "La IA no devolvió ideas" }, 502);

    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch (_e) {
      return json({ error: "La IA devolvió un formato inesperado" }, 502);
    }

    return json(parsed);
  } catch (e) {
    console.error(e);
    return json({ error: "Error inesperado en el servidor" }, 500);
  }
});
