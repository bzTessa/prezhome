// ============================================================================
// PrezHome · Edge Function: product-image
// ============================================================================
// Foto genérica de un producto de la compra ("cebolla", "leche"...), al estilo
// de las fotos de supermercado online: el producto solo, sin marca, sobre
// blanco. Se genera con Nano Banana (modelos de imagen de Gemini) UNA vez por
// producto y se guarda en el bucket público recipe-images
// (generic/<producto>.jpg), compartida por todos los hogares; las siguientes
// veces solo se devuelve la URL.
//   - Recibe { "key": <producto en minúsculas, sin acentos>, "again"?: true }.
//   - Los productos de keywords.json (la lista de la app) se generan gratis la
//     primera vez: es un coste único y compartido.
//   - Otro producto, o "again" (otra versión que sustituye la guardada), gasta
//     una foto del cupo de IA del hogar (meal_photo) y se devuelve si falla.
//   - Si no hay clave o modelo de imagen, la app sigue con el icono.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { aiLimitMessage, serveAi } from "../_shared/ai_limit.ts";
import { geminiImage } from "../_shared/gemini_image.ts";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import keywords from "./keywords.json" with { type: "json" };

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BUCKET = "recipe-images";
const allowed = new Set<string>(keywords as string[]);

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function prompt(key: string): string {
  return `Fotografía de catálogo de supermercado online de: ${key}.
El producto genérico tal como se compra en un supermercado de España, sin marca
ni texto ni etiquetas legibles. Si se vende envasado (leche, yogur, pasta...),
un envase sencillo y neutro. Un solo producto (o una pequeña ración), centrado,
ocupando casi todo el encuadre, sobre fondo blanco puro, luz suave de estudio,
sin manos, sin platos cocinados, sin decoración. Formato cuadrado.`;
}

async function generate(apiKey: string, key: string): Promise<Uint8Array | null> {
  const raw = await geminiImage(apiKey, prompt(key));
  if (!raw) return null;
  // En JPEG pesa ~10 veces menos que el PNG que devuelve Gemini.
  return await (await Image.decode(raw)).encodeJPEG(80);
}

serveAi("meal_photo", async (req, useCredit) => {
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

    const path = `generic/${key.replaceAll(" ", "-")}.jpg`;
    const url = admin.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
    if (!again) {
      const head = await fetch(url, { method: "HEAD" });
      if (head.ok) return json({ url });
    }
    if (!geminiKey) return json({ url: null });

    if (again || !allowed.has(key)) {
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
    }

    const bytes = await generate(geminiKey, key);
    if (!bytes) return json({ error: "No se pudo crear la foto" }, 502);
    const { error } = await admin.storage.from(BUCKET).upload(path, bytes, {
      contentType: "image/jpeg",
      upsert: true,
    });
    if (error) {
      console.error("upload:", error.message);
      return json({ error: "No se pudo guardar la foto" }, 500);
    }
    // Versión en la URL: si se generó otra, la app no reutiliza la caché vieja.
    return json({ url: again ? `${url}?v=${Date.now()}` : url });
  } catch (e) {
    console.error("product-image:", e);
    return json({ error: "No se pudo crear la foto" }, 500);
  }
});
