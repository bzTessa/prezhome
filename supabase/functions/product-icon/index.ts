// ============================================================================
// PrezHome · Edge Function: product-icon
// ============================================================================
// Icono dibujado de un producto que no tiene icono propio en la app
// ("quinoa", "tortilla de patata"...), con el mismo estilo que Miau. Se dibuja
// con Nano Banana UNA vez por producto y se guarda en el bucket público
// recipe-images (icons/<producto>.png), compartido por todos los hogares: la
// colección crece sola con el uso.
//   - Recibe { "key": <producto en minúsculas, sin acentos>, "again"?: true }.
//   - Si ya existe, solo devuelve la URL (gratis).
//   - Dibujarlo (o "again": otro dibujo que sustituye al guardado) gasta un
//     uso del cupo product_icon del hogar, que no se enseña en "Tu plan" y
//     solo frena abusos; si falla, se devuelve.
//   - Si no hay clave, modelo de imagen o cupo, la app sigue con su icono.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { aiLimitMessage, serveAi } from "../_shared/ai_limit.ts";
import { geminiImage } from "../_shared/gemini_image.ts";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import { clearWhiteBackground } from "./background.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BUCKET = "recipe-images";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Mismo prompt que los iconos encargados a Gemini (iconos-nuevos.md), con fondo
// blanco en vez de transparente: Gemini no da transparencias.
function prompt(key: string): string {
  return `Icono de: ${key} (producto de la compra en España).
Ilustración cozy dibujada a mano, estilo del gato Miau de PrezHome: trazo
marrón carbón grueso y redondeado, colores cálidos y apagados (crema, madera,
salvia, terracota #D85A32, dorado #E8A923, azul escarcha), sombreado suave.
Un solo objeto centrado y entero, ocupando casi todo el encuadre, vista frontal
ligeramente desde arriba, sin texto, sin marcas, sin manos, sin sombra en el
suelo. Fondo blanco puro liso. Formato cuadrado.`;
}

async function draw(apiKey: string, key: string): Promise<Uint8Array | null> {
  const raw = await geminiImage(apiKey, prompt(key));
  if (!raw) return null;
  const img = (await Image.decode(raw)).resize(512, 512);
  clearWhiteBackground(img.bitmap, img.width, img.height);
  return await img.encode();
}

serveAi("product_icon", async (req, useCredit) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  try {
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) return json({ url: null });

    const jwt = (req.headers.get("Authorization") ?? "")
      .replace("Bearer ", "").trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) return json({ error: "Sesión inválida" }, 401);

    const body = await req.json().catch(() => ({}));
    const key = (body?.key ?? "").toString().trim();
    const again = body?.again === true;
    // Nombre corto de producto: también es la ruta del fichero.
    if (!/^[a-z0-9]+( [a-z0-9]+){0,3}$/.test(key) || key.length > 40) {
      return json({ url: null });
    }

    const path = `icons/${key.replaceAll(" ", "-")}.png`;
    const url = admin.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
    if (!again) {
      const head = await fetch(url, { method: "HEAD" });
      if (head.ok) return json({ url });
    }
    if (!geminiKey) return json({ url: null });

    const { data: profile } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (!profile?.home_id) return json({ error: "Sin hogar" }, 400);
    const credit = await useCredit(admin, profile.home_id);
    if (credit === "error") {
      return json({ error: "No se pudo verificar el límite de uso" }, 500);
    }
    if (credit === "limit") return json({ error: aiLimitMessage() }, 429);

    const bytes = await draw(geminiKey, key);
    if (!bytes) return json({ error: "No se pudo crear el dibujo" }, 502);
    const { error } = await admin.storage.from(BUCKET).upload(path, bytes, {
      contentType: "image/png",
      upsert: true,
    });
    if (error) {
      console.error("upload:", error.message);
      return json({ error: "No se pudo guardar el dibujo" }, 500);
    }
    // Versión en la URL: si se dibujó otro, la app no reutiliza la caché vieja.
    return json({ url: again ? `${url}?v=${Date.now()}` : url });
  } catch (e) {
    console.error("product-icon:", e);
    return json({ error: "No se pudo crear el dibujo" }, 500);
  }
});
