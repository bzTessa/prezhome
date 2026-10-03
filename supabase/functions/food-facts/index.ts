// ============================================================================
// PrezHome · Edge Function: food-facts
// ============================================================================
// Consulta Open Food Facts (OFF) para obtener, dado el NOMBRE de un ingrediente
// (opcionalmente filtrando por supermercado/marca), datos REALES y prácticos:
//   - product_quantity: el FORMATO DE VENTA típico (p. ej. garbanzos de bote
//     ~400-570 g, lata de atún ~80 g), para que las cantidades de las recetas
//     sean normales en vez de "1060 g".
//   - nutrición por 100 g (kcal y macros) para poder calcular las calorías de
//     la receta sumando ingredientes en vez de estimarlas a ojo.
//
// OFF es colaborativo y gratuito (sin clave). La búsqueda por TEXTO va por el
// endpoint v1 cgi/search.pl (la v2 no soporta full-text). Degradamos SIEMPRE:
// si no hay match o falla la red, devolvemos { found: false } (status 200) y la
// app usa su comportamiento previo (estimación IA). NUNCA 500 por esto.
//
// Seguridad: valida el JWT (como el resto de funciones). NO consume crédito de
// IA (no llama a Gemini). NO filtra por home porque OFF es un dato público
// genérico; solo exigimos sesión válida para no exponer la función abierta.
//
// Despliegue AUTOMÁTICO por CI (deploy.yml) al mergear a main.
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

// User-Agent recomendado por OFF (identifica la app; es buena práctica).
const OFF_UA = "PrezHome/1.0 (hogar app; openfoodfacts)";

interface FoodFacts {
  found: boolean;
  productName?: string;
  brand?: string;
  // Formato de venta en gramos/ml si OFF lo da (product_quantity).
  packageQuantity?: number | null;
  packageUnit?: string | null; // 'g' | 'ml' (según product_quantity_unit)
  // Nutrición por 100 g (o 100 ml) del producto.
  kcal100?: number | null;
  protein100?: number | null;
  carbs100?: number | null;
  fat100?: number | null;
}

// Mapea una clave de súper de PrezHome a su marca/term de búsqueda en OFF.
// Para Mercadona la marca de distribuidor es "Hacendado"; para el resto usamos
// el propio nombre de la cadena como marca.
function brandTermFor(supermarket: string): string | null {
  const s = supermarket.trim().toLowerCase();
  if (!s) return null;
  const map: Record<string, string> = {
    mercadona: "Hacendado",
    lidl: "Lidl",
    carrefour: "Carrefour",
    dia: "Dia",
    alcampo: "Auchan",
    eroski: "Eroski",
    aldi: "Aldi",
    consum: "Consum",
  };
  return map[s] ?? supermarket;
}

function num(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  const n = typeof v === "number" ? v : parseFloat(String(v));
  return Number.isFinite(n) ? n : null;
}

// Busca en OFF por texto (y opcionalmente marca). Devuelve el primer producto
// con datos nutricionales utilizables, o null.
async function searchOFF(
  query: string,
  brand: string | null,
): Promise<FoodFacts | null> {
  try {
    const params = new URLSearchParams({
      search_terms: query,
      search_simple: "1",
      action: "process",
      json: "1",
      page_size: "15",
      fields:
        "product_name,brands,quantity,product_quantity,product_quantity_unit,nutriments",
    });
    if (brand) {
      params.set("tagtype_0", "brands");
      params.set("tag_contains_0", "contains");
      params.set("tag_0", brand);
    }
    const url = `https://es.openfoodfacts.org/cgi/search.pl?${params.toString()}`;
    const res = await fetch(url, { headers: { "User-Agent": OFF_UA } });
    if (!res.ok) return null;
    const data = await res.json();
    const products = Array.isArray(data?.products) ? data.products : [];
    if (products.length === 0) return null;

    // Elegimos el primer producto que tenga calorías por 100 g (dato clave).
    for (const p of products) {
      const n = p?.nutriments ?? {};
      const kcal = num(n["energy-kcal_100g"]) ?? num(n["energy-kcal"]);
      if (kcal === null) continue;
      return {
        found: true,
        productName: typeof p.product_name === "string" ? p.product_name : "",
        brand: typeof p.brands === "string" ? p.brands : "",
        packageQuantity: num(p.product_quantity),
        packageUnit: typeof p.product_quantity_unit === "string"
          ? p.product_quantity_unit
          : null,
        kcal100: kcal,
        protein100: num(n["proteins_100g"]),
        carbs100: num(n["carbohydrates_100g"]),
        fat100: num(n["fat_100g"]),
      };
    }
    return null;
  } catch (_e) {
    return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      return json({ error: "Configuración del servidor incompleta" }, 500);
    }

    // Sesión válida (no filtramos por hogar: OFF es dato público genérico).
    const jwt = (req.headers.get("Authorization") ?? "")
      .replace("Bearer ", "")
      .trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) {
      return json({ error: "Sesión inválida" }, 401);
    }

    const body = await req.json().catch(() => ({}));
    const name = (body?.name ?? "").toString().trim();
    const supermarket = (body?.supermarket ?? "").toString().trim();
    if (!name) return json({ error: "Falta el nombre del alimento" }, 400);

    // 1) Si hay súper, probamos primero con su marca (producto real del súper).
    // 2) Si no hay match con marca, probamos sin marca (producto genérico OFF).
    let result: FoodFacts | null = null;
    const brand = brandTermFor(supermarket);
    if (brand) {
      result = await searchOFF(name, brand);
    }
    result ??= await searchOFF(name, null);

    if (result === null) {
      return json({ found: false });
    }
    return json(result);
  } catch (e) {
    console.error(e);
    return json({ found: false });
  }
});
