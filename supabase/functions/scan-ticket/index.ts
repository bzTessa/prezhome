// ============================================================================
// PrezHome · Edge Function: scan-ticket
// ============================================================================
// Lee la foto de un ticket con Gemini (visión) y extrae tienda, fecha y la
// lista de productos con precio y cantidad. Usa la "memoria" de correcciones
// del hogar (product_aliases) para no repetir errores de abreviaturas.
//
// Seguridad: valida JWT, obtiene home_id con service_role, controla el límite
// mensual de IA (consume_ai_credit). La API key vive como secreto del servidor.
//
// Despliegue:
//   supabase functions deploy scan-ticket
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

// Descubre un modelo de Gemini con visión disponible para la key.
async function pickModel(apiKey: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`,
    );
    if (!res.ok) return null;
    const data = await res.json();
    const models: string[] = (data?.models ?? [])
      .filter((m: any) =>
        Array.isArray(m?.supportedGenerationMethods) &&
        m.supportedGenerationMethods.includes("generateContent")
      )
      .map((m: any) => m.name as string)
      .filter((n: string) => !n.includes("embedding") && !n.includes("aqa"));
    models.sort((a, b) => (a.includes("flash") ? 0 : 1) - (b.includes("flash") ? 0 : 1));
    return models[0] ?? null;
  } catch (_e) {
    return null;
  }
}

function buildPrompt(aliases: { raw_name: string; correct_name: string }[]): string {
  const aliasText = aliases.length > 0
    ? "Correcciones aprendidas (si ves el texto de la izquierda, usa el nombre de la derecha):\n" +
      aliases.map((a) => `- "${a.raw_name}" => "${a.correct_name}"`).join("\n")
    : "No hay correcciones previas.";

  return `Eres un asistente que lee tickets de compra de supermercado. Analiza la
imagen del ticket y extrae los datos.

${aliasText}

Devuelve SOLO un objeto JSON válido (sin markdown) con esta forma:
{
  "merchant": string,        // nombre de la tienda
  "purchased_at": string,    // fecha en formato YYYY-MM-DD si aparece, si no ""
  "total_amount": number,    // total del ticket
  "items": [
    {
      "raw_name": string,    // texto EXACTO tal como aparece en el ticket
      "name": string,        // nombre legible y corregido en español
      "category": string,    // categoria: lacteos, verdura, fruta, carne, pescado, panaderia, bebidas, limpieza, higiene, otros
      "quantity": number,
      "unit_price": number,  // precio por unidad si se puede deducir, si no el total de la linea
      "total_price": number  // precio total de esa linea
    }
  ]
}

Corrige las abreviaturas a nombres legibles en "name" (aplica las correcciones
aprendidas si encajan). Mantén el texto original en "raw_name". Si un dato no se
ve, usa "" o 0. No inventes productos que no estén en el ticket.`;
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
      return json({ error: "Falta la imagen del ticket" }, 400);
    }

    // Límite mensual de IA
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

    // Cargar correcciones aprendidas del hogar (memoria)
    const { data: aliasRows } = await admin
      .from("product_aliases")
      .select("raw_name, correct_name")
      .eq("home_id", homeId)
      .limit(200);
    const aliases = (aliasRows ?? []) as {
      raw_name: string;
      correct_name: string;
    }[];

    const model = await pickModel(geminiKey);
    if (!model) {
      return json(
        { error: "No hay modelos de Gemini disponibles para tu clave." },
        502,
      );
    }

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/${model}:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: buildPrompt(aliases) },
                { inline_data: { mime_type: mimeType, data: imageBase64 } },
              ],
            },
          ],
          generationConfig: { responseMimeType: "application/json" },
        }),
      },
    );

    if (!geminiRes.ok) {
      const detail = await geminiRes.text();
      console.error("Gemini error:", detail);
      return json(
        { error: `Error de la IA -> ${detail.substring(0, 300)}` },
        502,
      );
    }

    const geminiData = await geminiRes.json();
    const text: string | undefined =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return json({ error: "La IA no devolvió datos del ticket" }, 502);

    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch (_e) {
      return json({ error: "La IA devolvió un formato inesperado" }, 502);
    }

    return json({ ticket: parsed });
  } catch (e) {
    console.error(e);
    return json({ error: "Error inesperado en el servidor" }, 500);
  }
});
