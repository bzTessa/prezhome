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
//   - Recibe { "query": <título/nombre del plato> }.
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

// --- Unsplash ---------------------------------------------------------------
// Busca una foto en Unsplash y devuelve { url, attribution } o { url: null }.
// Cualquier excepción de red, respuesta no OK o ausencia de resultados se
// degrada a { url: null }: NUNCA lanza hacia el flujo principal.
async function searchUnsplash(query: string, key: string): Promise<unknown> {
  try {
    const url =
      `https://api.unsplash.com/search/photos?query=${encodeURIComponent(query)}` +
      `&per_page=1&orientation=landscape`;
    const res = await fetch(url, {
      headers: { Authorization: `Client-ID ${key}` },
    });
    if (!res.ok) {
      console.error("Unsplash error:", res.status, await res.text());
      return { url: null };
    }
    const data = await res.json();
    const results = Array.isArray(data?.results) ? data.results : [];
    if (results.length === 0) {
      return { url: null };
    }
    const first = results[0];
    const photoUrl = first?.urls?.regular ?? first?.urls?.small ?? null;
    if (!photoUrl) {
      return { url: null };
    }

    const photographerName = first?.user?.name ?? null;
    const photographerUrl = first?.user?.links?.html ?? null;
    const unsplashUrl = "https://unsplash.com";

    // Requisito de la API de Unsplash: hay que "disparar" el endpoint de
    // descarga (links.download_location) cuando se usa/selecciona una foto.
    // Es BEST-EFFORT: si falla, solo lo registramos y seguimos devolviendo la
    // foto con normalidad.
    //
    // IMPORTANTE: NO bloqueamos la respuesta al cliente con este disparo. Antes
    // se hacía `await fetch(...)` en el camino crítico, de modo que un endpoint
    // lento o colgado añadía latencia a CADA búsqueda de foto. Ahora:
    //   1. Acotamos el fetch con un AbortController (~2.5s) para que nunca
    //      quede colgado indefinidamente.
    //   2. Lo lanzamos en modo fire-and-forget. En edge functions de Deno una
    //      promesa sin await puede cortarse al devolver la respuesta, así que
    //      usamos `EdgeRuntime.waitUntil(...)` si existe para que el disparo
    //      termine en segundo plano SIN retener la respuesta. Si no existe,
    //      caemos a un await con el mismo timeout corto (cota aceptable).
    // En cualquier caso, un fallo o timeout del disparo NUNCA afecta a la foto
    // devuelta ni lanza hacia el handler.
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
        // Fire-and-forget sin retener la respuesta del usuario.
        edgeRuntime.waitUntil(triggerDownload());
      } else {
        // Sin EdgeRuntime: await acotado por el timeout corto como cota.
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

    // 3. Leer y validar la petición
    const body = await req.json().catch(() => ({}));
    const query = (body?.query ?? "").toString().trim();
    if (!query) {
      return json({ error: "Falta el nombre del plato" }, 400);
    }

    // 4. Selección de proveedor. Unsplash es el PRINCIPAL; Pexels el RESPALDO.
    //    Si no hay ninguna clave, degradar: { url: null } (NUNCA 500).
    const unsplashKey = Deno.env.get("UNSPLASH_ACCESS_KEY");
    const pexelsKey = Deno.env.get("PEXELS_API_KEY");

    // 4a. Camino PRINCIPAL: Unsplash. searchUnsplash ya degrada a { url: null }
    //     ante cualquier fallo, por lo que nunca rompe el alta de receta.
    if (unsplashKey) {
      return json(await searchUnsplash(query, unsplashKey));
    }

    // 4b. Camino de RESPALDO: Pexels (comportamiento previo, sin cambios).
    if (!pexelsKey) {
      return json({ url: null });
    }

    // Consultar Pexels. Cualquier error de red o respuesta no OK se degrada
    // a { url: null } con status 200 para no romper el alta de receta.
    try {
      const url =
        `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}` +
        `&per_page=1&orientation=landscape`;
      const res = await fetch(url, {
        headers: { Authorization: pexelsKey },
      });
      if (!res.ok) {
        console.error("Pexels error:", res.status, await res.text());
        return json({ url: null });
      }
      const data = await res.json();
      const photos = Array.isArray(data?.photos) ? data.photos : [];
      if (photos.length === 0) {
        return json({ url: null });
      }
      const src = photos[0]?.src ?? {};
      const photoUrl = src.large || src.medium || src.original || null;
      return json({ url: photoUrl });
    } catch (e) {
      console.error("Pexels fetch exception:", e);
      return json({ url: null });
    }
  } catch (e) {
    console.error(e);
    // Último recurso: aun ante un error inesperado, degradar sin romper el alta.
    return json({ url: null });
  }
});
