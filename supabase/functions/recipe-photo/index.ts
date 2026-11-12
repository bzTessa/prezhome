// ============================================================================
// PrezHome · Edge Function: recipe-photo
// ============================================================================
// Busca una FOTO para una receta en un banco de imágenes de forma SEGURA y
// SIEMPRE DEGRADANDO CON ELEGANCIA:
//   - Proveedor PRINCIPAL: Unsplash. Si existe el secreto UNSPLASH_ACCESS_KEY
//     se usa Unsplash (autenticación por cabecera "Authorization: Client-ID
//     <key>", endpoint search/photos).
//   - Proveedor de RESPALDO: Pexels. Si NO hay UNSPLASH_ACCESS_KEY pero sí hay
//     PEXELS_API_KEY, se usa el camino de Pexels tal cual (sin cambios).
//   - Si NO hay ninguna clave, o el proveedor no responde, o no hay resultados,
//     devuelve { url: null } con status 200. NUNCA devuelve 500 por falta de
//     clave o fallo del proveedor: la receta se guarda sin foto y se ve el
//     placeholder cozy.
//   - Las claves viven como secretos del servidor (nunca en el cliente).
//   - Valida la sesión del usuario (JWT) y obtiene su home_id (mismo patrón de
//     seguridad que generate-recipe).
//   - Recibe { "query": <título/nombre del plato>, "query_en"?: <el mismo en
//     inglés>, "mode"?: "dish"|"ingredient", "exclude"?: [urls ya vistas] }.
//     Cada búsqueda declara su idioma (lang=es / en) y "exclude" permite a la
//     app pedir "otra foto" distinta de las ya mostradas.
//   - Open Food Facts (foto del envase) solo se usa en modo "ingredient": para
//     un plato cocinado daría una foto equivocada.
//   - Esto NO es Gemini: NO consume crédito de IA (no llama a consume_ai_credit).
//
// Unsplash · requisito de "download trigger":
//   Las normas de la API de Unsplash exigen avisar al endpoint
//   links.download_location cuando una foto se "usa"/selecciona. Lo hacemos en
//   modo BEST-EFFORT: si falla, NO rompe la respuesta (la foto se devuelve
//   igual). Mostrar el crédito del fotógrafo en la UI queda como mejora futura
//   documentada; el disparo técnico obligatorio ya está implementado.
//
// Despliegue:
//   El secreto UNSPLASH_ACCESS_KEY (y, si se quiere respaldo, PEXELS_API_KEY)
//   se configura desde el panel web de Supabase (Edge Functions · Secrets).
//   El despliegue de la función lo hace AUTOMÁTICAMENTE CI (GitHub Actions);
//   ya no hace falta ejecutar `supabase functions deploy` a mano.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  conflictingDishTypes,
  keywordsFor,
  pickRelevant,
  plausible,
  relevance,
  unsplashText,
} from "./relevance.ts";
import {
  allowedPhotoUrl,
  chooseDishPhoto,
  type Dish,
  photoQueries,
} from "./vision.ts";

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

// --- Refinado de la query de comida -----------------------------------------
// Antes se mezclaban palabras en español con contexto en inglés
// ("lentejas estofadas chorizo food dish meal") y Unsplash, que por defecto
// interpreta la búsqueda en inglés, ignoraba las palabras clave y devolvía un
// plato genérico. Ahora cada búsqueda declara su IDIOMA:
//   1. Si la app manda `query_en` (nombre del plato en inglés que da la IA al
//      generar/importar la receta), se prueba primero en inglés: es lo que
//      mejor acierta en los bancos de imágenes.
//   2. Después, el título en español con `lang=es` (Unsplash traduce la
//      búsqueda), primero el núcleo de ingredientes y luego el título entero.
// Devuelve la lista de búsquedas a probar en orden (de más a menos específica).
interface PhotoSearch {
  query: string;
  lang: "es" | "en";
}

// Palabras de "relleno" culinario y conectores que no aportan a la búsqueda
// visual (en español). Se eliminan para quedarnos con los ingredientes.
const STOP_WORDS = new Set([
  "al", "a", "la", "el", "los", "las", "con", "de", "del", "y", "o", "en",
  "estilo", "casero", "casera", "rápido", "rapido", "rápida", "rapida",
  "fácil", "facil", "rico", "rica", "sabroso", "sabrosa",
  "horno", "plancha", "sartén", "sarten", "vapor", "olla", "cazuela",
  "salteado", "salteada", "salteados", "salteadas", "asado", "asada",
  "asados", "asadas", "cocido", "cocida", "cocidos", "cocidas",
  "guisado", "guisada", "frito", "frita", "fritos", "fritas",
  "gratinado", "gratinada", "relleno", "rellena", "crujiente",
  // Marcas blancas habituales: no describen el plato.
  "hacendado", "carrefour", "dia", "eroski", "auchan", "alcampo",
]);

function words(raw: string): string[] {
  return raw
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .split(/\s+/)
    .filter((w) => w.length > 0);
}

function buildFoodSearches(
  raw: string,
  queryEn: string,
  mode = "dish",
): PhotoSearch[] {
  const original = raw.trim();
  const en = queryEn.trim();
  const searches: PhotoSearch[] = [];

  // Modo INGREDIENTE (despensa): el alimento tal cual se compra, no un plato.
  if (mode === "ingredient") {
    const base = words(original).join(" ") || original;
    if (en) searches.push({ query: `${en} raw ingredient`, lang: "en" });
    if (base) {
      searches.push({ query: base, lang: "es" });
      searches.push({ query: `${base} ingrediente fresco`, lang: "es" });
    }
    return dedupe(searches);
  }

  if (en) {
    searches.push({ query: en, lang: "en" });
    searches.push({ query: `${en} dish`, lang: "en" });
  }
  const keyWords = words(original).filter((w) => !STOP_WORDS.has(w));
  // Los 3 primeros términos significativos suelen ser los ingredientes clave.
  const core = keyWords.slice(0, 3).join(" ");
  if (core) searches.push({ query: `${core} plato`, lang: "es" });
  if (original) searches.push({ query: original, lang: "es" });
  if (keyWords.length > 0) {
    searches.push({ query: `${keyWords[0]} comida`, lang: "es" });
  }
  return dedupe(searches);
}

function dedupe(searches: PhotoSearch[]): PhotoSearch[] {
  const seen = new Set<string>();
  return searches.filter((s) => {
    const k = `${s.lang}:${s.query}`;
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });
}

// --- Candidatas -------------------------------------------------------------
// Antes nos quedábamos con la primera foto cuyo texto mencionaba el plato; ahora
// juntamos varias candidatas de las primeras búsquedas y elegimos entre todas:
// con Gemini (mira las fotos) o, si no hay, por el texto (relevance.ts).
interface Candidate {
  url: string; // foto que se guarda en la receta
  thumb: string; // versión pequeña para que Gemini la mire
  text: string; // alt, descripción y etiquetas del banco
  provider: "unsplash" | "pexels";
  // deno-lint-ignore no-explicit-any
  raw: Record<string, any>;
}

// Cuántas candidatas mira Gemini y cuántas búsquedas hacemos como mucho (la
// cuota de Unsplash es por petición).
const MAX_CANDIDATES = 8;
const MAX_SEARCHES = 3;

async function unsplashCandidates(
  search: PhotoSearch,
  key: string,
): Promise<Candidate[]> {
  try {
    const url =
      `https://api.unsplash.com/search/photos?query=${encodeURIComponent(search.query)}` +
      `&lang=${search.lang}&per_page=10&orientation=landscape&content_filter=high`;
    const res = await fetch(url, {
      headers: { Authorization: `Client-ID ${key}` },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) {
      console.error("Unsplash error:", res.status, await res.text());
      return [];
    }
    const data = await res.json();
    const results = Array.isArray(data?.results) ? data.results : [];
    // deno-lint-ignore no-explicit-any
    return results.flatMap((r: Record<string, any>) => {
      const u = r?.urls?.regular ?? r?.urls?.small;
      if (typeof u !== "string") return [];
      return [{
        url: u,
        thumb: r?.urls?.small ?? u,
        text: unsplashText(r),
        provider: "unsplash" as const,
        raw: r,
      }];
    });
  } catch (e) {
    console.error("Unsplash fetch exception:", e);
    return [];
  }
}

async function pexelsCandidates(
  search: PhotoSearch,
  key: string,
): Promise<Candidate[]> {
  try {
    const locale = search.lang === "es" ? "es-ES" : "en-US";
    const url =
      `https://api.pexels.com/v1/search?query=${encodeURIComponent(search.query)}` +
      `&locale=${locale}&per_page=10&orientation=landscape`;
    const res = await fetch(url, {
      headers: { Authorization: key },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) {
      console.error("Pexels error:", res.status, await res.text());
      return [];
    }
    const data = await res.json();
    const photos = Array.isArray(data?.photos) ? data.photos : [];
    // deno-lint-ignore no-explicit-any
    return photos.flatMap((p: Record<string, any>) => {
      const u = p?.src?.large || p?.src?.medium || p?.src?.original;
      if (typeof u !== "string") return [];
      return [{
        url: u,
        thumb: p?.src?.medium ?? u,
        text: `${p?.alt ?? ""}`,
        provider: "pexels" as const,
        raw: p,
      }];
    });
  } catch (e) {
    console.error("Pexels fetch exception:", e);
    return [];
  }
}

// Junta candidatas de las primeras búsquedas, sin repetidas ni excluidas.
// Con Gemini, las que el texto ya descarta (otro tipo de plato, nada de comida
// de la receta) no se le enseñan; las demás van ordenadas por relevancia.
async function gather(
  searches: PhotoSearch[],
  fetchOne: (s: PhotoSearch) => Promise<Candidate[]>,
  exclude: Set<string>,
  keywords: string[][],
): Promise<Candidate[]> {
  const seen = new Set<string>(exclude);
  const out: Candidate[] = [];
  for (const s of searches.slice(0, MAX_SEARCHES)) {
    for (const c of await fetchOne(s)) {
      if (seen.has(c.url)) continue;
      seen.add(c.url);
      out.push(c);
    }
    if (out.filter((c) => plausible(c.text, keywords)).length >= MAX_CANDIDATES) {
      break;
    }
  }
  return out;
}

// Elige la foto: Gemini mira las plausibles (o, si el texto no da ninguna,
// las primeras: a veces el alt es pobre). Sin Gemini, filtro por texto.
async function choose(
  candidates: Candidate[],
  keywords: string[][],
  dish: Dish,
  geminiKey: string | undefined,
): Promise<{ pick: Candidate | null; verified: boolean }> {
  if (candidates.length === 0) return { pick: null, verified: false };
  if (geminiKey) {
    const ranked = candidates
      .map((c, i) => ({ c, i, ok: plausible(c.text, keywords), s: relevance(c.text, keywords) }))
      .sort((a, b) => Number(b.ok) - Number(a.ok) || b.s - a.s || a.i - b.i)
      .filter((x) => !conflictingDishTypes(x.c.text, keywords).length)
      .slice(0, MAX_CANDIDATES)
      .map((x) => x.c);
    if (ranked.length === 0) return { pick: null, verified: true };
    const best = await chooseDishPhoto(geminiKey, dish, ranked.map((c) => c.thumb));
    if (best !== null) {
      return { pick: best >= 0 ? ranked[best] : null, verified: true };
    }
    // Gemini no ha respondido: seguimos con el filtro por texto.
  }
  return {
    pick: pickRelevant(candidates, (c) => c.text, keywords),
    verified: false,
  };
}

// Requisito de la API de Unsplash: hay que "disparar" el endpoint de descarga
// (links.download_location) cuando se usa una foto. Best-effort y en segundo
// plano si se puede: un fallo NUNCA afecta a la foto devuelta.
async function triggerUnsplashDownload(
  // deno-lint-ignore no-explicit-any
  raw: Record<string, any>,
  key: string,
): Promise<void> {
  const downloadLocation = raw?.links?.download_location;
  if (typeof downloadLocation !== "string" || downloadLocation.length === 0) {
    return;
  }
  const trigger = async () => {
    try {
      await fetch(downloadLocation, {
        headers: { Authorization: `Client-ID ${key}` },
        signal: AbortSignal.timeout(2500),
      });
    } catch (e) {
      console.error("Unsplash download trigger exception:", e);
    }
  };
  const edgeRuntime = (globalThis as {
    EdgeRuntime?: { waitUntil?: (p: Promise<unknown>) => void };
  }).EdgeRuntime;
  if (edgeRuntime && typeof edgeRuntime.waitUntil === "function") {
    edgeRuntime.waitUntil(trigger());
  } else {
    await trigger();
  }
}

function unsplashResult(c: Candidate, verified: boolean) {
  return {
    url: c.url,
    provider: "unsplash",
    verified,
    attribution: {
      photographer: c.raw?.user?.name ?? null,
      photographerUrl: c.raw?.user?.links?.html ?? null,
      source: "Unsplash",
      sourceUrl: "https://unsplash.com",
    },
  };
}

// --- Open Food Facts (RESPALDO keyless) -------------------------------------
// User-Agent recomendado por OFF (misma identidad que la función food-facts).
const OFF_UA = "PrezHome/1.0 (hogar app; openfoodfacts)";

// Extrae la mejor URL de foto de un producto OFF: frontal pequeña -> frontal
// grande -> image_url. Devuelve null si no hay cadena http(s) utilizable.
function productImageUrl(p: Record<string, unknown>): string | null {
  const candidates = [
    p["image_front_small_url"],
    p["image_front_url"],
    p["image_url"],
  ];
  for (const c of candidates) {
    if (typeof c === "string" && c.trim().startsWith("http")) return c.trim();
  }
  return null;
}

// Busca en OFF por TEXTO (misma lógica que food-facts) una foto REAL del
// producto para usarla como RESPALDO cuando Unsplash/Pexels no dan resultado.
// NO requiere clave. Degrada SIEMPRE a null ante fallo de red, respuesta no OK
// o ausencia de resultados: NUNCA lanza hacia el handler.
async function searchOFFPhoto(query: string): Promise<string | null> {
  const q = query.trim();
  if (!q) return null;
  try {
    // search-a-licious: la antigua cgi/search.pl da 503 sin cuenta.
    const params = new URLSearchParams({
      q: q.replace(/[^\p{L}\p{N}]+/gu, " ").trim(),
      langs: "es",
      page_size: "10",
      fields: "image_url,image_front_url,image_front_small_url",
    });
    const url = `https://search.openfoodfacts.org/search?${params.toString()}`;
    const res = await fetch(url, { headers: { "User-Agent": OFF_UA } });
    if (!res.ok) return null;
    const data = await res.json();
    const products = Array.isArray(data?.hits) ? data.hits : [];
    for (const p of products) {
      const img = productImageUrl(p ?? {});
      if (img) return img;
    }
    return null;
  } catch (e) {
    console.error("OFF fallback fetch exception:", e);
    return null;
  }
}

// Versión pequeña de una foto ya guardada, para que Gemini la mire rápido.
function thumbOf(url: string): string {
  try {
    const u = new URL(url);
    if (u.hostname === "images.unsplash.com") {
      u.searchParams.set("w", "400");
      return u.toString();
    }
    if (u.hostname === "images.pexels.com") {
      u.searchParams.set("h", "350");
      u.searchParams.set("w", "525");
      return u.toString();
    }
  } catch (_) { /* URL rara: se usa tal cual */ }
  return url;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
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

    // 3. Leer y validar la petición.
    //    - query: título del plato (o nombre del alimento) en español.
    //    - query_en: opcional, el mismo nombre en inglés (lo da la IA al
    //      generar/importar recetas). Mejora mucho el acierto.
    //    - description / ingredients: opcionales; Gemini los usa para saber
    //      qué plato es al buscar y al mirar las fotos.
    //    - mode: 'dish' (receta, por defecto) o 'ingredient' (despensa).
    //    - exclude: opcional, URLs ya mostradas; se devuelve otra distinta
    //      (botón "Otra foto" de la app).
    //    - verify_url: opcional; no busca, solo dice si esa foto es del plato
    //      ({ ok: true|false|null }). La app lo usa para revisar las fotos
    //      automáticas que ya tienen las recetas.
    const body = await req.json().catch(() => ({}));
    const query = (body?.query ?? "").toString().trim();
    const queryEn = (body?.query_en ?? "").toString().trim();
    const mode = (body?.mode ?? "dish").toString().trim();
    const exclude = new Set<string>(
      Array.isArray(body?.exclude)
        ? body.exclude.filter((u: unknown) => typeof u === "string")
        : [],
    );
    if (!query) {
      return json({ error: "Falta el nombre del plato" }, 400);
    }
    const dish: Dish = {
      title: query,
      description: (body?.description ?? "").toString().trim().slice(0, 500),
      ingredients: Array.isArray(body?.ingredients)
        ? body.ingredients
          .map((i: unknown) => String(i ?? "").trim())
          .filter(Boolean)
          .slice(0, 15)
        : [],
    };
    const geminiKey = Deno.env.get("GEMINI_API_KEY") || undefined;

    // Solo revisar una foto que ya tiene la receta.
    const verifyUrl = (body?.verify_url ?? "").toString().trim();
    if (verifyUrl) {
      if (!geminiKey || !allowedPhotoUrl(verifyUrl)) return json({ ok: null });
      const best = await chooseDishPhoto(geminiKey, dish, [
        thumbOf(verifyUrl),
      ]);
      return json({ ok: best === null ? null : best === 0 });
    }

    // Palabras que la descripción de la foto debe mencionar; si ninguna foto
    // las menciona, mejor sin foto (ilustración) que una al azar.
    // Un alimento suelto (despensa) vale con que la foto nombre cualquiera de
    // sus palabras: todas van en un solo grupo.
    const groups = keywordsFor(query, queryEn);
    const keywords = mode === "ingredient" ? [groups.flat()] : groups;

    // Para un plato, Gemini escribe primero búsquedas en inglés que describen
    // cómo se ve, sin marcas ("Happy Hippo" -> "chocolate cheesecake").
    let searches = buildFoodSearches(query, queryEn, mode);
    if (mode !== "ingredient" && geminiKey) {
      const ai = await photoQueries(geminiKey, dish);
      if (ai) {
        searches = dedupe([
          ...ai.map((q) => ({ query: q, lang: "en" as const })),
          ...searches,
        ]);
      }
    }
    // Despensa: un alimento suelto, la foto no necesita que la mire Gemini.
    const judge = mode === "ingredient" ? undefined : geminiKey;

    // 4. Selección de proveedor. Unsplash es el PRINCIPAL; Pexels el RESPALDO.
    //    Si no hay ninguna clave, degradar: { url: null } (NUNCA 500).
    const unsplashKey = Deno.env.get("UNSPLASH_ACCESS_KEY");
    const pexelsKey = Deno.env.get("PEXELS_API_KEY");

    if (unsplashKey) {
      const candidates = await gather(
        searches,
        (s) => unsplashCandidates(s, unsplashKey),
        exclude,
        keywords,
      );
      const { pick, verified } = await choose(candidates, keywords, dish, judge);
      if (pick) {
        await triggerUnsplashDownload(pick.raw, unsplashKey);
        return json(unsplashResult(pick, verified));
      }
    }
    if (pexelsKey) {
      const candidates = await gather(
        searches,
        (s) => pexelsCandidates(s, pexelsKey),
        exclude,
        keywords,
      );
      const { pick, verified } = await choose(candidates, keywords, dish, judge);
      if (pick) return json({ url: pick.url, provider: "pexels", verified });
    }

    // 5. Open Food Facts SOLO para alimentos sueltos (despensa): da la foto
    //    del ENVASE del producto, que para un plato cocinado es una foto
    //    equivocada (una bolsa de lentejas para un guiso). Para platos es
    //    mejor no devolver foto y que la app pinte su ilustración.
    if (mode === "ingredient") {
      const offUrl = await searchOFFPhoto(query);
      if (offUrl && !exclude.has(offUrl)) {
        return json({ url: offUrl, provider: "openfoodfacts" });
      }
    }
    return json({ url: null });
  } catch (e) {
    console.error(e);
    // Último recurso: aun ante un error inesperado, degradar sin romper el alta.
    return json({ url: null });
  }
});
