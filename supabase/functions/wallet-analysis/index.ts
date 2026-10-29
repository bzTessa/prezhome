// ============================================================================
// PrezWallet · Edge Function: wallet-analysis
// ============================================================================
// Analiza la cartera con Gemini y le pone una nota de 0 a 100 (diversificación,
// concentración, costes y encaje con el perfil de riesgo). Es educativo: no
// recomienda productos ni comprar o vender valores concretos.
//
// Entrada: { portfolio: {...} } con el resumen que calcula la app (posiciones
// con su peso, reparto, rentabilidad, comisiones, perfil). Salida: { report }
// y se guarda en wallet_ai_reports.
//
// Cupo: plan_quotas.wallet_analysis según el plan del hogar (free si no tiene
// hogar), contando los informes del mes en wallet_ai_reports.
// Despliegue AUTOMÁTICO por CI (deploy.yml) al mergear a main.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { aiLimitMessage } from "../_shared/ai_limit.ts";

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

const MAX_INPUT = 20000;

// Modelos de Gemini disponibles para la key, flash primero.
async function pickModels(apiKey: string): Promise<string[]> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`,
    );
    if (!res.ok) return [];
    const data = await res.json();
    const models: string[] = (data?.models ?? [])
      .filter((m: any) =>
        m?.supportedGenerationMethods?.includes?.("generateContent")
      )
      .map((m: any) => m.name as string)
      .filter((n: string) => !n.includes("embedding") && !n.includes("aqa"));
    models.sort((a, b) => {
      const fa = a.includes("flash") ? 0 : 1;
      const fb = b.includes("flash") ? 0 : 1;
      return fa !== fb ? fa - fb : b.localeCompare(a);
    });
    return models;
  } catch (_e) {
    return [];
  }
}

function buildPrompt(portfolio: string): string {
  return `Eres un educador financiero que revisa la cartera de inversión de una
persona en España. Escribe en español, claro y cercano, sin jerga.

Datos de la cartera (JSON, importes en euros, pesos de 0 a 1):
${portfolio}

Pon una nota de 0 a 100 a lo bien construida que está la cartera, valorando:
diversificación (número de valores, regiones, sectores), concentración en un
solo valor, peso de cripto o activos muy volátiles, costes (comisiones frente a
lo invertido) y encaje con su perfil de riesgo y su edad si vienen.

NO recomiendes productos, fondos, ETF ni acciones concretas, ni comprar o
vender ningún valor concreto: habla de ideas generales (p. ej. "repartir entre
más regiones"). No es asesoramiento financiero.

Devuelve SOLO un JSON válido (sin markdown) con esta forma exacta:
{
  "score": number,          // 0 a 100
  "summary": string,        // 2-3 frases
  "strengths": [string],    // 1 a 3 puntos fuertes
  "risks": [string],        // 1 a 3 riesgos o puntos débiles
  "ideas": [string]         // 1 a 3 ideas generales para mejorar
}`;
}

const strings = (v: unknown) =>
  Array.isArray(v) ? v.filter((s) => typeof s === "string").slice(0, 3) : [];

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

    const body = await req.json().catch(() => ({}));
    const portfolio = JSON.stringify(body?.portfolio ?? null);
    if (!body?.portfolio || typeof body.portfolio !== "object") {
      return json({ error: "Falta la cartera" }, 400);
    }
    if (portfolio.length > MAX_INPUT) {
      return json({ error: "Cartera demasiado grande" }, 413);
    }

    // Plan del hogar si lo hay; sin hogar, gratis.
    const { data: profile } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", userId)
      .maybeSingle();
    let plan = "free";
    if (profile?.home_id) {
      const { data: sub } = await admin
        .from("subscriptions")
        .select("plan")
        .eq("home_id", profile.home_id)
        .maybeSingle();
      plan = sub?.plan ?? "free";
    }
    const { data: quota } = await admin
      .from("plan_quotas")
      .select("monthly_limit")
      .eq("plan", plan)
      .eq("feature", "wallet_analysis")
      .maybeSingle();
    const now = new Date();
    const monthStart = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
    ).toISOString();
    const { count, error: countErr } = await admin
      .from("wallet_ai_reports")
      .select("id", { count: "exact", head: true })
      .eq("owner_id", userId)
      .gte("created_at", monthStart);
    if (countErr) {
      return json({ error: "No se pudo verificar el límite de uso" }, 500);
    }
    // shortcut: dos peticiones a la vez podrían pasarse en uno; usar una RPC
    // atómica como consume_ai_credit si se abusa.
    if ((count ?? 0) >= (quota?.monthly_limit ?? 0)) {
      return json({ error: aiLimitMessage(now) }, 429);
    }

    const models = await pickModels(geminiKey);
    if (models.length === 0) {
      return json({ error: "No hay modelos de Gemini disponibles." }, 502);
    }
    const requestBody = JSON.stringify({
      contents: [{ parts: [{ text: buildPrompt(portfolio) }] }],
      generationConfig: { responseMimeType: "application/json" },
    });
    let geminiData: any;
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
      console.error("Gemini error:", model, res.status, await res.text());
      if (res.status === 401 || res.status === 403) break;
    }
    const text: string | undefined =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return json({ error: "La IA no respondió" }, 502);

    let parsed: any;
    try {
      parsed = JSON.parse(text);
    } catch (_e) {
      return json({ error: "Respuesta con un formato inesperado" }, 502);
    }
    const score = Math.round(Number(parsed?.score));
    if (!Number.isFinite(score)) {
      return json({ error: "Respuesta con un formato inesperado" }, 502);
    }
    const report = {
      summary: String(parsed?.summary ?? ""),
      strengths: strings(parsed?.strengths),
      risks: strings(parsed?.risks),
      ideas: strings(parsed?.ideas),
    };
    const { data: saved, error: saveErr } = await admin
      .from("wallet_ai_reports")
      .insert({
        owner_id: userId,
        score: Math.min(100, Math.max(0, score)),
        report,
      })
      .select()
      .single();
    if (saveErr) return json({ error: saveErr.message }, 500);
    return json({ report: saved });
  } catch (e) {
    console.error(e);
    return json({ error: "Error inesperado en el servidor" }, 500);
  }
});
