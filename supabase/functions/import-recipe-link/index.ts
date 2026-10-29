// ============================================================================
// PrezHome · Edge Function: import-recipe-link
// ============================================================================
// Importa una receta a partir de un ENLACE de TikTok / Instagram (o cualquier
// web de recetas). La idea (estilo app "mise"): leemos el TEXTO público del
// post —el caption/descripción y el título—, que es donde casi siempre está
// escrita la receta, y se lo pasamos a Gemini con el MISMO esquema que
// generate-recipe. Solo en YouTube, si el texto no trae la receta, Gemini ve
// el vídeo.
//
// Flujo:
//   1. Seguridad igual que las demás funciones: valida JWT, obtiene home_id y
//      consume el límite mensual de IA (consume_ai_credit, server-side).
//   2. Recibe { "url": <enlace> } y/o { "text": <texto pegado> }. Si llega
//      texto (p. ej. la descripción de un post de Instagram copiada a mano)
//      se usa tal cual; si no, se valida que la URL sea http(s) pública.
//   3. Extrae el texto público del enlace (siguiendo antes los enlaces cortos
//      tipo vm.tiktok.com / youtu.be):
//        a) Descripción COMPLETA incrustada en la página (TikTok: "desc";
//           YouTube: "shortDescription"). Los metadatos OG vienen recortados
//           y por eso antes se perdían los ingredientes.
//        b) YouTube Data API (si existe el secreto YOUTUBE_API_KEY): título,
//           descripción y comentarios del propio autor (el fijado suele ser la
//           receta). YouTube bloquea a menudo la página a servidores, así que
//           es la vía fiable.
//        c) oEmbed (título/autor) y metadatos Open Graph como respaldo.
//      Todo best-effort: si una vía falla, se intenta la siguiente.
//   4. Si no se consigue texto útil, devuelve 422 con need_text para que la
//      app pida pegar el texto. Instagram casi nunca deja leer un post sin
//      iniciar sesión, así que ahí es lo habitual. No se gasta crédito de IA.
//   5. Pasa el texto a Gemini (mismo esquema que generate-recipe). Gemini dice
//      si el texto trae de verdad los ingredientes (source_has_recipe). Si no:
//        - YouTube: se repite viendo el VÍDEO (Gemini acepta enlaces públicos
//          de YouTube).
//        - Resto: 422 need_text, en vez de inventar una receta genérica.
//      TikTok no permite a Gemini ver el vídeo: ahí solo vale la descripción.
//
// Despliegue AUTOMÁTICO por CI (deploy.yml) al mergear a main, igual que el
// resto de funciones. Reusa el secreto GEMINI_API_KEY ya configurado;
// YOUTUBE_API_KEY es opcional.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { aiLimitMessage, serveAi } from "../_shared/ai_limit.ts";
import { isPublicUrl } from "./url_guard.ts";
import { tiktokDescription, youtubeDescription, youtubeId } from "./extract.ts";

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

// Intenta el endpoint oEmbed de TikTok/YouTube para sacar título y autor.
async function fetchOEmbed(url: string): Promise<string | null> {
  try {
    const host = new URL(url).host;
    let endpoint: string | null = null;
    if (host.includes("tiktok.com")) {
      endpoint = `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`;
    } else if (host.includes("youtube.com") || host.includes("youtu.be")) {
      endpoint = `https://www.youtube.com/oembed?format=json&url=${encodeURIComponent(url)}`;
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

// Descarga la página siguiendo redirecciones. Devuelve la URL final (los
// enlaces cortos de TikTok/YouTube apuntan al vídeo real) y el HTML si hubo 200.
async function fetchPage(
  url: string,
): Promise<{ url: string; html: string | null }> {
  try {
    // Redirecciones a mano para comprobar cada salto con isPublicUrl.
    let res: Response | null = null;
    for (let hop = 0; hop < 5; hop++) {
      if (!isPublicUrl(url)) return { url, html: null };
      res = await fetch(url, {
        // SOCS: acepta el aviso de cookies de Google en servidores europeos.
        headers: {
          "User-Agent": BROWSER_UA,
          "Accept-Language": "es,en",
          "Cookie": "SOCS=CAI",
        },
        redirect: "manual",
        signal: AbortSignal.timeout(8000),
      });
      const next = res.headers.get("location");
      if (res.status < 300 || res.status >= 400 || !next) break;
      await res.body?.cancel();
      url = new URL(next, url).toString();
      res = null;
    }
    if (!res?.ok) {
      await res?.body?.cancel();
      return { url, html: null };
    }
    return { url, html: await res.text() };
  } catch (_e) {
    return { url, html: null };
  }
}

// YouTube Data API: título, descripción y comentarios del autor del vídeo.
// shortcut: solo los 20 comentarios más relevantes; el fijado suele estar ahí.
async function fetchYoutubeApi(id: string): Promise<string | null> {
  const key = Deno.env.get("YOUTUBE_API_KEY");
  if (!key) return null;
  const api = "https://www.googleapis.com/youtube/v3";
  try {
    const v = await fetch(
      `${api}/videos?part=snippet&id=${id}&key=${key}`,
      { signal: AbortSignal.timeout(8000) },
    ).then((r) => r.json());
    const s = v?.items?.[0]?.snippet;
    if (!s) return null;
    const parts: string[] = [s.title, s.description].filter(Boolean);
    const c = await fetch(
      `${api}/commentThreads?part=snippet&videoId=${id}&order=relevance` +
        `&maxResults=20&textFormat=plainText&key=${key}`,
      { signal: AbortSignal.timeout(8000) },
    ).then((r) => r.json()).catch(() => null);
    for (const t of c?.items ?? []) {
      const top = t?.snippet?.topLevelComment?.snippet;
      if (top?.authorChannelId?.value === s.channelId && top?.textOriginal) {
        parts.push(`Comentario del autor: ${top.textOriginal}`);
      }
    }
    return parts.join("\n\n");
  } catch (_e) {
    return null;
  }
}

// Texto útil de la página: la descripción completa incrustada (TikTok/YouTube)
// o, si no hay, los metadatos OG/description/title.
function pageText(html: string, url: string): string | null {
  try {
    const parts: string[] = [];
    const ogTitle = metaContent(html, ["og:title", "twitter:title"]);
    // "desc" es una clave genérica: solo se mira en TikTok.
    const full = youtubeDescription(html) ??
      (/(^|\.)tiktok\.com$/i.test(new URL(url).hostname)
        ? tiktokDescription(html)
        : null);
    if (full) return [ogTitle, full].filter(Boolean).join(". ");
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

function buildPrompt(sourceText: string, url: string, video = false): string {
  const fuente = video ? "del VÍDEO adjunto y del texto" : "del texto";
  return `Eres un asistente de cocina. A partir del TEXTO de la descripción de
un vídeo/post de redes sociales (TikTok/Instagram/YouTube) de una receta, deduce y
estructura la receta completa. El texto puede venir con emojis, hashtags o
abreviado.${video
    ? "\nAdemás tienes el VÍDEO: saca ingredientes, cantidades y pasos de lo que se\nve y se dice en él (y de los textos que aparecen en pantalla)."
    : ""}

REGLAS DE FIDELIDAD:
- Los ingredientes y cantidades que vengan ${fuente} se copian TAL CUAL
  (solo pásalos a las unidades de abajo). No añadas ingredientes que no salgan.
- Solo puedes estimar cantidades que falten, macros y tiempos.
- "source_has_recipe": true SOLO si ${fuente} trae la lista de ingredientes de
  la receta. Si solo trae el nombre del plato, una descripción genérica o nada
  de cocina, pon false y NO inventes la receta (deja "ingredients": []), pero
  rellena "title" con el plato si se sabe.

Enlace original: ${url || "(texto pegado por el usuario)"}

Texto del post:
"""
${sourceText}
"""

Responde SOLO con un objeto JSON válido (sin markdown) con exactamente esta
forma:
{
  "source_has_recipe": boolean,
  "title": string,
  "photo_query_en": string,  // nombre corto del plato EN INGLÉS para buscar una foto (p. ej. "spanish lentil stew with chorizo")
  "description": string,
  "servings": number,
  "meal_types": string[],  // de: "breakfast","lunch","dinner","snack","dessert","drink"
  "appliance": "none" | "oven" | "stovetop" | "pot" | "airfryer" | "microwave" | "blender",
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

function needTextMessage(url: string): string {
  const insta = /(^|\.)instagram\.com$/i.test(new URL(url).hostname);
  return insta
    ? "Instagram no deja leer sus publicaciones desde fuera de la app. Abre " +
      "el post, copia la descripción con la receta y pégala aquí."
    : "No pude leer la receta de ese enlace (puede ser privado o no tener la " +
      "receta escrita). Copia el texto de la receta y pégalo aquí.";
}

// deno-lint-ignore no-explicit-any
type GeminiResult = { recipe: Record<string, any> } | { error: string };

// La IA no encontró ingredientes de verdad en la fuente.
function hasNoRecipe(r: GeminiResult): boolean {
  if ("error" in r) return false;
  const ings = r.recipe.ingredients;
  return r.recipe.source_has_recipe === false || !Array.isArray(ings) ||
    ings.length === 0;
}

// Llama a Gemini probando modelos en orden y devuelve la receta parseada.
async function askGemini(
  models: string[],
  key: string,
  parts: unknown[],
  extraConfig: Record<string, unknown> = {},
): Promise<GeminiResult> {
  const requestBody = JSON.stringify({
    contents: [{ parts }],
    generationConfig: { responseMimeType: "application/json", ...extraConfig },
  });
  let lastError = "";
  for (const model of models) {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/${model}:generateContent?key=${key}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: requestBody,
      },
    );
    if (!res.ok) {
      lastError = `${model}: HTTP ${res.status} — ${await res.text()}`;
      console.error("Gemini error:", lastError);
      if (res.status === 401 || res.status === 403) break;
      continue;
    }
    const data = await res.json();
    const text: string | undefined =
      data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return { error: "No se recibió ninguna receta" };
    try {
      const recipe = JSON.parse(text);
      if (recipe && typeof recipe === "object") return { recipe };
    } catch (_e) { /* cae al error de formato */ }
    return { error: "Respuesta con un formato inesperado" };
  }
  return { error: `Error del servicio → ${lastError.substring(0, 300)}` };
}

serveAi("import_link", async (req, useCredit) => {
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

    // 2. Validar la entrada: texto pegado y/o enlace.
    const body = await req.json().catch(() => ({}));
    const url = (body?.url ?? "").toString().trim();
    const pasted = (body?.text ?? "").toString().trim().substring(0, 8000);
    if (url) {
      let parsed: URL;
      try {
        parsed = new URL(url);
      } catch (_e) {
        return json({ error: "El enlace no es válido" }, 400);
      }
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
        return json({ error: "El enlace debe empezar por http(s)" }, 400);
      }
      if (!isPublicUrl(url)) {
        return json({ error: "El enlace no es válido" }, 400);
      }
    } else if (!pasted) {
      return json({ error: "Pega un enlace o el texto de la receta" }, 400);
    }

    // 3. Texto de la receta: el pegado o, si no, el que se pueda leer del
    // enlace (descripción completa, YouTube API, oEmbed, OG; best-effort).
    // Antes de gastar crédito.
    let sourceText = pasted;
    let ytId: string | null = null;
    if (!sourceText) {
      const page = await fetchPage(url);
      ytId = youtubeId(page.url);
      const fromApi = ytId ? await fetchYoutubeApi(ytId) : null;
      const fromPage = page.html ? pageText(page.html, page.url) : null;
      // La API y la descripción completa ya traen el título: oEmbed solo suma
      // cuando no hay nada mejor.
      const oembed = fromApi || fromPage ? null : await fetchOEmbed(page.url);
      sourceText = [fromApi ?? fromPage, oembed]
        .filter((s): s is string => !!s && s.length > 0)
        .join(". ")
        .trim()
        .substring(0, 12000);
    }

    // En YouTube, aunque no haya texto, Gemini puede ver el vídeo.
    if (sourceText.length < 15 && !ytId) {
      if (pasted) {
        return json({ error: "Ese texto es muy corto para ser una receta" }, 400);
      }
      return json({ need_text: true, error: needTextMessage(url) }, 422);
    }

    // 4. Consumir crédito de IA (igual que generate-recipe)
    const credit = await useCredit(admin, homeId);
    if (credit === "error") {
      return json({ error: "No se pudo verificar el límite de uso" }, 500);
    }
    if (credit === "limit") return json({ error: aiLimitMessage() }, 429);

    // 5. Estructurar con Gemini
    const models = await pickModels(geminiKey);
    if (models.length === 0) {
      return json({ error: "No hay modelos de Gemini disponibles." }, 502);
    }

    let result: GeminiResult | null = sourceText.length >= 15
      ? await askGemini(models, geminiKey, [
        { text: buildPrompt(sourceText, url) },
      ])
      : null;
    // YouTube sin receta escrita: que Gemini vea el vídeo.
    if (ytId && (!result || hasNoRecipe(result))) {
      const video = await askGemini(models, geminiKey, [
        { file_data: { file_uri: `https://www.youtube.com/watch?v=${ytId}` } },
        { text: buildPrompt(sourceText || "(sin descripción)", url, true) },
      ], { mediaResolution: "MEDIA_RESOLUTION_LOW" });
      // Si ver el vídeo falla, nos quedamos con lo que dijo el texto.
      if (!("error" in video) || !result) result = video;
    }
    if (!result) return json({ error: "No se recibió ninguna receta" }, 502);
    if ("error" in result) return json({ error: result.error }, 502);

    // Sin ingredientes reales: mejor pedir el texto que inventar la receta.
    if (hasNoRecipe(result)) {
      const plato = typeof result.recipe.title === "string"
        ? result.recipe.title.trim()
        : "";
      return json(
        {
          need_text: true,
          error: (plato ? `El vídeo de «${plato}» no` : "Ese enlace no") +
            " trae los ingredientes escritos en la descripción (solo salen " +
            "en el vídeo). Si están en un comentario o en la web del autor, " +
            "cópialos y pégalos aquí.",
        },
        422,
      );
    }

    return json({ recipe: result.recipe });
  } catch (e) {
    console.error(e);
    return json({ error: "Error inesperado en el servidor" }, 500);
  }
});
