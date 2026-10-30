// ============================================================================
// PrezWallet · Edge Function: wallet-prices
// ============================================================================
// Trae de Twelve Data el cierre diario de los valores de la cartera del usuario
// (con histórico de hasta 5 años la primera vez), lo pasa a euros y lo guarda
// en wallet_prices. Después pone el último cierre como precio actual de sus
// posiciones. La app la llama al abrir la Cartera; si los precios ya son de
// hoy o de ayer no vuelve a pedirlos.
//
// Tickers: "AAPL", "VWCE:XETR" (símbolo:bolsa) o, para cripto, "BTC" (se pide
// BTC/EUR). Si el valor cotiza en otra divisa se convierte con el cambio
// diario <divisa>/EUR.
//
// También guarda el índice de referencia (BENCHMARK, MSCI World) para que la
// app compare la cartera con él; wallet_prices es común, así que se pide una
// vez al día para todos.
//
// Secreto: TWELVE_DATA_API_KEY. Sin él responde { ok: false, reason:
// "no_key" } y la app sigue con los precios a mano. Nunca 500 por un ticker
// que no exista: va en "missing".
//
// Seguridad: valida el JWT y lee las posiciones con el cliente del usuario
// (RLS). Solo wallet_prices se escribe con la clave de servicio.
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

/** Clave en wallet_prices; la misma regla que priceKey() en la app. */
export function priceKey(ticker: string, kind: string): string {
  const t = ticker.trim().toUpperCase();
  return kind === "crypto" && !t.includes("/") ? `${t}/EUR` : t;
}

/** ETF iShares MSCI World (en USD, se pasa a euros como el resto). */
export const BENCHMARK = "URTH";

type Series = { currency: string; closes: Map<string, number> };

async function fetchSeries(
  key: string,
  apiKey: string,
  startDate: string,
): Promise<Series | null> {
  const [symbol, exchange] = key.split(":");
  const url = new URL("https://api.twelvedata.com/time_series");
  url.searchParams.set("symbol", symbol);
  if (exchange) url.searchParams.set("exchange", exchange);
  url.searchParams.set("interval", "1day");
  url.searchParams.set("start_date", startDate);
  url.searchParams.set("outputsize", "5000");
  url.searchParams.set("apikey", apiKey);
  const res = await fetch(url);
  if (!res.ok) return null;
  const body = await res.json();
  if (body?.status !== "ok" || !Array.isArray(body.values)) return null;
  const closes = new Map<string, number>();
  for (const v of body.values) {
    const close = Number(v.close);
    if (Number.isFinite(close)) closes.set(String(v.datetime).slice(0, 10), close);
  }
  // Los pares de divisas (BTC/EUR, USD/EUR) no traen currency: la cotizada es
  // la segunda.
  const currency = body.meta?.currency ?? symbol.split("/")[1] ?? "EUR";
  return { currency: String(currency).toUpperCase(), closes };
}

/** Pasa cada cierre a euros con el último cambio conocido en esa fecha. */
export function toEur(
  closes: Map<string, number>,
  fx: Map<string, number>,
): Map<string, number> {
  const fxDays = [...fx.keys()].sort();
  const out = new Map<string, number>();
  let i = 0;
  let rate: number | undefined;
  for (const day of [...closes.keys()].sort()) {
    while (i < fxDays.length && fxDays[i] <= day) rate = fx.get(fxDays[i++]);
    // Antes del primer cambio conocido se usa el primero.
    const r = rate ?? fx.get(fxDays[0]);
    if (r !== undefined) out.set(day, closes.get(day)! * r);
  }
  return out;
}

const isoDay = (d: Date) => d.toISOString().slice(0, 10);

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !serviceKey || !anonKey) {
      return json({ error: "Configuración del servidor incompleta" }, 500);
    }
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) {
      return json({ error: "Sesión inválida" }, 401);
    }

    const apiKey = Deno.env.get("TWELVE_DATA_API_KEY");
    if (!apiKey) return json({ ok: false, reason: "no_key" });

    const db = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: holdings, error: hErr } = await db
      .from("wallet_holdings")
      .select("id, ticker, kind")
      .not("ticker", "is", null);
    if (hErr) return json({ error: hErr.message }, 500);

    const keys = new Map<string, string[]>(); // clave -> ids de posiciones
    for (const h of holdings ?? []) {
      if (!h.ticker?.trim()) continue;
      const k = priceKey(h.ticker, h.kind);
      keys.set(k, [...(keys.get(k) ?? []), h.id]);
    }
    if (keys.size > 0 && !keys.has(BENCHMARK)) keys.set(BENCHMARK, []);

    const today = new Date();
    const yesterday = isoDay(new Date(today.getTime() - 864e5));
    const fiveYearsAgo = isoDay(new Date(today.getTime() - 5 * 365 * 864e5));
    const fxCache = new Map<string, Map<string, number>>();
    const missing: string[] = [];
    let updated = 0;

    for (const [key, ids] of keys) {
      const { data: last } = await admin
        .from("wallet_prices")
        .select("day, close_eur")
        .eq("symbol", key)
        .order("day", { ascending: false })
        .limit(1)
        .maybeSingle();

      let latest = last ? Number(last.close_eur) : undefined;
      if (!last || last.day < yesterday) {
        const start = last ? last.day : fiveYearsAgo;
        const series = await fetchSeries(key, apiKey, start);
        if (!series || series.closes.size === 0) {
          if (!last) missing.push(key);
        } else {
          let eur = series.closes;
          if (series.currency !== "EUR") {
            const pair = `${series.currency}/EUR`;
            if (!fxCache.has(pair)) {
              fxCache.set(
                pair,
                (await fetchSeries(pair, apiKey, start))?.closes ?? new Map(),
              );
            }
            eur = toEur(series.closes, fxCache.get(pair)!);
          }
          const rows = [...eur].map(([day, close]) => ({
            symbol: key,
            day,
            close_eur: close,
          }));
          if (rows.length) {
            const { error } = await admin.from("wallet_prices").upsert(rows);
            if (error) return json({ error: error.message }, 500);
            latest = eur.get([...eur.keys()].sort().at(-1)!);
          }
        }
      }

      if (latest !== undefined && ids.length > 0) {
        const { error } = await db
          .from("wallet_holdings")
          .update({ price: latest })
          .in("id", ids);
        if (!error) updated += ids.length;
      }
    }

    return json({ ok: true, updated, missing });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
