// ============================================================================
// PrezHome · Edge Function: import-recipe-link
// ============================================================================
// Importa una receta a partir de un ENLACE de TikTok / Instagram (o cualquier
// web de recetas). La idea (estilo app "mise"): NO transcribimos el vídeo (no
// es viable), sino que leemos el TEXTO público del post —el caption/descripción
// y el título—, que es donde casi siempre está escrita la receta, y se lo
// pasamos a Gemini con el MISMO esquema que generate-recipe para estructurarla.
//
// Flujo:
//   1. Seguridad igual que las demás funciones: valida JWT, obtiene home_id y
//      consume el límite mensual de IA (consume_ai_credit, server-side).
//   2. Recibe { "url": <enlace> }. Valida que sea http(s).
//   3. Extrae el texto público del enlace:
//        a) oEmbed (TikTok e Instagram ofrecen un endpoint oEmbed con el
//           título/autor del post sin autenticación).
//        b) Metadatos Open Graph de la página (og:description, og:title,
//           description) como respaldo general para cualquier web.
//      Todo best-effort: si una vía falla, se intenta la siguiente.
//   4. Si no se consigue texto útil, devuelve 422 con un mensaje claro para que
//      la app sugiera pegar la receta a mano.
//   5. Pasa el texto a Gemini (mismo prompt/esquema que generate-recipe) y
//      devuelve { recipe }.
//
// Despliegue AUTOMÁTICO por CI (deploy.yml) al mergear a main, igual que el
// resto de funciones. Reusa el secreto GEMINI_API_KEY ya configurado.
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

// User-Agent de navegador: algunas webs devuelven los metadatos OG solo a
// clientes que parecen navegadores.
const BROWSER_UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/122.0 Safari/537.36";

// Decodifica entidades HTML básicas que aparecen en los metadatos.
function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x27;/g, "'")
    .replace(/&nbsp;/g, " ");
}

// Extrae el contenido de una meta tag Open Graph / name por su propiedad.
function metaContent(html: string, keys: string[]): string | null {
  for (const key of keys) {
    // property="og:description" content="..."  (en cualquier orden de attrs)
    const re = new RegExp(
      `<meta[^>]+(?:property|name)=["']${key}["'][^>]*content=["']([^"']*)["']`,
      "i",
    );
    const m = html.match(re);
    if (m && m[1]) return decodeEntities(m[1].trim());
    // content="..." antes de la propiedad
    const re2 = new RegExp(
      `<meta[^>]+content=["']([^"']*)["'][^>]*(?:property|name)=["']${key}["']`,
      "i",
    );
    const m2 = html.match(re2);
    if (m2 && m2[1]) return decodeEntities(m2[1].trim());
  }
  return null;
}

// Intenta el endpoint oEmbed de TikTok/Instagram para sacar título y autor.
async function fetchOEmbed(url: string): Promise<string | null> {
  try {
    const host = new URL(url).host;
    let endpoint: string | null = null;
    if (host.includes("tiktok.com")) {
      endpoint = `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`;
    } else if (host.includes("instagram.com")) {
      // oEmbed público (sin token) de Instagram; puede no responder siempre.
      endpoint = `https://api.instagram.com/oembed?url=${encodeURIComponent(url)}`;
    }
    if (!endpoint) return null;
    const res = await fetch(endpoint, { headers: { "User-Agent": BROWSER_UA } });
    if (!res.ok) return null;
    const data = await res.json();
    const parts: string[] = [];
    if (typeof data?.title === "string") parts.push(data.title);
    if (typeof data?.author_name === "string") {
      parts.push(`por ${data.author_name}`);
    }
    const text = parts.join(" ").trim();
    return text.length > 0 ? text : null;
  } catch (_e) {
    return null;
  }
}

// Descarga la página y extrae texto útil de sus metadatos (OG/description/title).
async function fetchPageText(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": BROWSER_UA, "Accept-Language": "es,en" },
      redirect: "follow",
    });
    if (!res.ok) return null;
    const html = await res.text();
    const parts: string[] = [];
    const ogTitle = metaContent(html, ["og:title", "twitter:title"]);
    const ogDesc = metaContent(html, [
      "og:description",
      "twitter:description",
      "description",
    ]);
    if (ogTitle) parts.push(ogTitle);
    if (ogDesc) parts.push(ogDesc);
    // <title> como último recurso.
    if (parts.length === 0) {
      const t = html.match(/<title[^>]*>([^<]+)<\/title>/i);
      if (t && t[1]) parts.push(decodeEntities(t[1].trim()));
    }
    const text = parts.join(". ").trim();
    return text.length > 0 ? text : null;
  } catch (_e) {
    return null;
  }
}

function buildPrompt(sourceText: string, url: string): string {
  return `Eres un asistente de cocina. A partir del TEXTO de la descripción de
un vídeo/post de redes sociales (TikTok/Instagram) de una receta, deduce y
estructura la receta completa. El texto puede estar incompleto, con emojis,
hashtags o abreviado; completa de forma RAZONABLE lo que falte (cantidades,
macros, pasos) manteniéndote fiel a lo que describe.

Enlace original: ${url}

Texto del post:
"""
${sourceText}
"""

Responde SOLO con un objeto JSON válido (sin markdown) con exactamente esta
forma:
{
  "title": string,
  "description": string,
  "servings": number,
  "meal_types": string[],
  "appliance": "none" | "oven" | "stovetop" | "pot" | "airfryer" | "microwave",
  "prep_minutes": number,
  "cook_minutes": number,
  "freezable": boolean,
  "calories_per_serving": number,
  "grams_per_serving": number,
  "protein_grams": number,
  "carbs_grams": number,
  "fat_grams": number,
  "ingredients": [ { "name": string, "quantity": number o null, "unit": string } ],
  "instructions": string,
  "components": [ { "name": string, "proportion": number } ],
  "freezer_days": number
}

MEDIDAS: sólidos en "g", líquidos en "ml", especias/condimentos en
"cucharada"/"cucharadita"/"pizca" o "al gusto" (quantity null), contables en
"unidad". Números redondos tipo supermercado. En "instructions" un paso por
línea separado por salto de línea real (\\n), cada uno con su número. En
"components" desglosa el plato en partes con su % (suman 100), [] solo si es un
único alimento homogéneo. Todo en español.`;
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

    // 1. Sesión del usuario
    const jwt = (req.headers.get("Authorization") ?? "")
      .replace("Bearer ", "")
      .trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) {
      return json({ error: "Sesión inválida" }, 401);
    }

    const { data: profile, error: profErr } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (profErr || !profile?.home_id) {
      return json({ error: "El usuario no pertenece a ningún hogar" }, 400);
    }
    const homeId = profile.home_id as string;

    // 2. Validar la URL
    const body = await req.json().catch(() => ({}));
    const url = (body?.url ?? "").toString().trim();
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch (_e) {
      return json({ error: "El enlace no es válido" }, 400);
    }
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
      return json({ error: "El enlace debe empezar por http(s)" }, 400);
    }

    // 3. Consumir crédito de IA (igual que generate-recipe)
    const { data: allowed, error: creditErr } = await admin.rpc(
      "consume_ai_credit",
      { target_home_id: homeId },
    );
    if (creditErr) {
      return json({ error: "No se pudo verificar el límite de IA" }, 500);
    }
    if (allowed !== true) {
      return json(
        {
          error:
            "Has alcanzado tu límite mensual de IA. Inténtalo el mes que viene.",
        },
        429,
      );
    }

    // 4. Extraer texto del enlace (oEmbed + metadatos OG, best-effort).
    const oembed = await fetchOEmbed(url);
    const page = await fetchPageText(url);
    const sourceText = [oembed, page]
      .filter((s): s is string => !!s && s.length > 0)
      .join(". ")
      .trim();

    if (sourceText.length < 15) {
      // No hay texto útil: muchas publicaciones son privadas o no exponen la
      // receta en la descripción. Avisamos para que la app sugiera pegar el
      // texto a mano en "Rellenar con IA".
      return json(
        {
          error:
            "No pude leer la receta de ese enlace (puede ser privado o no " +
            "tener la receta escrita en la descripción). Prueba a copiar el " +
            "texto de la receta y pegarlo en 'Rellenar con IA'.",
        },
        422,
      );
    }

    // 5. Estructurar con Gemini
    const models = await pickModels(geminiKey);
    if (models.length === 0) {
      return json({ error: "No hay modelos de Gemini disponibles." }, 502);
    }

    const requestBody = JSON.stringify({
      contents: [{ parts: [{ text: buildPrompt(sourceText, url) }] }],
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
      return json(
        { error: `Error de la IA → ${lastError.substring(0, 300)}` },
        502,
      );
    }

    const text: string | undefined =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return json({ error: "La IA no devolvió una receta" }, 502);

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
