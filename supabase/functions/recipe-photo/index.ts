// ============================================================================
// PrezHome · Edge Function: recipe-photo
// ============================================================================
// Busca una FOTO para una receta en un banco de imágenes (Pexels) de forma
// SEGURA y SIEMPRE DEGRADANDO CON ELEGANCIA:
//   - La PEXELS_API_KEY vive como secreto del servidor (nunca en el cliente).
//   - Valida la sesión del usuario (JWT) y obtiene su home_id (mismo patrón de
//     seguridad que generate-recipe).
//   - Recibe { "query": <título/nombre del plato> } y consulta Pexels.
//   - Si NO hay PEXELS_API_KEY, o Pexels no responde, o no hay resultados,
//     devuelve { url: null } con status 200. NUNCA devuelve 500 por falta de
//     clave o fallo de Pexels: la receta se guarda sin foto y se ve el
//     placeholder cozy.
//   - Esto NO es Gemini: NO consume crédito de IA (no llama a consume_ai_credit).
//
// Despliegue (lo hace la usuaria):
//   supabase secrets set PEXELS_API_KEY=...
//   supabase functions deploy recipe-photo
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

    // 4. Leer la clave de Pexels. Si NO hay clave, degradar: { url: null }.
    //    NUNCA 500 por falta de clave (la foto es opcional).
    const pexelsKey = Deno.env.get("PEXELS_API_KEY");
    if (!pexelsKey) {
      return json({ url: null });
    }

    // 5. Consultar Pexels. Cualquier error de red o respuesta no OK se degrada
    //    a { url: null } con status 200 para no romper el alta de receta.
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
