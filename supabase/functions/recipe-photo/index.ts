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

// --- Unsplash ---------------------------------------------------------------
// Prueba las búsquedas en orden y devuelve la primera foto que NO esté en
// `exclude` (las que la app ya mostró: así "Otra foto" trae una distinta).
// Cualquier excepción de red, respuesta no OK o ausencia de resultados se
// degrada a { url: null }: NUNCA lanza hacia el flujo principal.
async function searchUnsplash(
  searches: PhotoSearch[],
  key: string,
  exclude: Set<string>,
): Promise<{ url: string | null; [k: string]: unknown }> {
  for (const s of searches) {
    const result = await searchUnsplashOnce(s, key, exclude);
    if (result.url) return result;
  }
  return { url: null };
}

// Una sola búsqueda en Unsplash (10 resultados, para poder saltar los
// excluidos).
async function searchUnsplashOnce(
  search: PhotoSearch,
  key: string,
  exclude: Set<string>,
): Promise<{ url: string | null; [k: string]: unknown }> {
  try {
    const url =
      `https://api.unsplash.com/search/photos?query=${encodeURIComponent(search.query)}` +
      `&lang=${search.lang}&per_page=10&orientation=landscape&content_filter=high`;
    const res = await fetch(url, {
      headers: { Authorization: `Client-ID ${key}` },
    });
    if (!res.ok) {
      console.error("Unsplash error:", res.status, await res.text());
      return { url: null };
    }
    const data = await res.json();
    const results = Array.isArray(data?.results) ? data.results : [];
    const first = results.find((r: Record<string, any>) => {
      const u = r?.urls?.regular ?? r?.urls?.small;
      return typeof u === "string" && !exclude.has(u);
    });
    if (!first) return { url: null };
    const photoUrl: string = first.urls.regular ?? first.urls.small;

    const photographerName = first?.user?.name ?? null;
    const photographerUrl = first?.user?.links?.html ?? null;
    const unsplashUrl = "https://unsplash.com";

    // Requisito de la API de Unsplash: hay que "disparar" el endpoint de
    // descarga (links.download_location) cuando se usa/selecciona una foto.
    // Es BEST-EFFORT y no retiene la respuesta: se acota con un timeout corto
    // (~2.5s) y, si existe `EdgeRuntime.waitUntil`, se lanza en segundo plano.
    // Un fallo o timeout del disparo NUNCA afecta a la foto devuelta.
    const downloadLocation = first?.links?.download_location;
    if (typeof downloadLocation === "string" && downloadLocation.length > 0) {
      const triggerDownload = async () => {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 2500);
        try {
          await fetch(downloadLocation, {
            headers: { Authorization: `Client-ID ${key}` },
            signal: controller.signal,
          });
        } catch (e) {
          console.error("Unsplash download trigger exception:", e);
        } finally {
          clearTimeout(timeout);
        }
      };

      const edgeRuntime = (globalThis as {
        EdgeRuntime?: { waitUntil?: (p: Promise<unknown>) => void };
      }).EdgeRuntime;
      if (edgeRuntime && typeof edgeRuntime.waitUntil === "function") {
        edgeRuntime.waitUntil(triggerDownload());
      } else {
        await triggerDownload();
      }
    }

    return {
      url: photoUrl,
      provider: "unsplash",
      attribution: {
        photographer: photographerName,
        photographerUrl,
        source: "Unsplash",
        sourceUrl: unsplashUrl,
      },
    };
  } catch (e) {
    console.error("Unsplash fetch exception:", e);
    return { url: null };
  }
}

// --- Pexels (respaldo con clave) --------------------------------------------
// Mismo contrato que Unsplash. Pexels interpreta el idioma con `locale`.
async function searchPexels(
  searches: PhotoSearch[],
  key: string,
  exclude: Set<string>,
): Promise<string | null> {
  for (const s of searches) {
    try {
      const locale = s.lang === "es" ? "es-ES" : "en-US";
      const url =
        `https://api.pexels.com/v1/search?query=${encodeURIComponent(s.query)}` +
        `&locale=${locale}&per_page=10&orientation=landscape`;
      const res = await fetch(url, { headers: { Authorization: key } });
      if (!res.ok) {
        console.error("Pexels error:", res.status, await res.text());
        continue;
      }
      const data = await res.json();
      const photos = Array.isArray(data?.photos) ? data.photos : [];
      for (const p of photos) {
        const u = p?.src?.large || p?.src?.medium || p?.src?.original;
        if (typeof u === "string" && !exclude.has(u)) return u;
      }
    } catch (e) {
      console.error("Pexels fetch exception:", e);
    }
  }
  return null;
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
    const params = new URLSearchParams({
      search_terms: q,
      search_simple: "1",
      action: "process",
      json: "1",
      page_size: "10",
      fields: "image_url,image_front_url,image_front_small_url",
    });
    const url = `https://es.openfoodfacts.org/cgi/search.pl?${params.toString()}`;
    const res = await fetch(url, { headers: { "User-Agent": OFF_UA } });
    if (!res.ok) return null;
    const data = await res.json();
    const products = Array.isArray(data?.products) ? data.products : [];
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
    //    - mode: 'dish' (receta, por defecto) o 'ingredient' (despensa).
    //    - exclude: opcional, URLs ya mostradas; se devuelve otra distinta
    //      (botón "Otra foto" de la app).
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
    const searches = buildFoodSearches(query, queryEn, mode);

    // 4. Selección de proveedor. Unsplash es el PRINCIPAL; Pexels el RESPALDO.
    //    Si no hay ninguna clave, degradar: { url: null } (NUNCA 500).
    const unsplashKey = Deno.env.get("UNSPLASH_ACCESS_KEY");
    const pexelsKey = Deno.env.get("PEXELS_API_KEY");

    if (unsplashKey) {
      const result = await searchUnsplash(searches, unsplashKey, exclude);
      if (result.url) return json(result);
    }
    if (pexelsKey) {
      const url = await searchPexels(searches, pexelsKey, exclude);
      if (url) return json({ url, provider: "pexels" });
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
