// ============================================================================
// PrezWallet · Edge Function: wallet-bank
// ============================================================================
// Bancos conectados con Enable Banking. Cada usuario usa su propia aplicación
// de Enable Banking (modo personal, gratis, solo sus cuentas).
//
// POST { action: "set_key", app_id, pem }  guarda su aplicación (clave en Vault)
// POST { action: "banks", country? }       bancos (todos si no hay país)
// POST { action: "connect", bank, country } -> { url } para entrar en el banco;
//      el banco vuelve a bank-callback, que crea las cuentas.
// POST { action: "sync" } -> { accounts: [{ account_id, balance, rows }] }
//      movimientos nuevos (sin los que ya tienen external_id). La app los
//      categoriza y los guarda igual que al importar un extracto. Cada banco
//      se consulta como mucho cada 6 h: PSD2 limita a 4 consultas al día sin
//      el usuario delante.
//
// Seguridad: valida el JWT; la clave privada solo se lee con la de servicio.
// Despliegue AUTOMÁTICO por CI (deploy.yml) al mergear a main.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { type BankRow, eb, importPem, loadApp, pickBalance, toRow } from
  "../_shared/enable_banking.ts";

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

const SYNC_EVERY_MS = 6 * 3600 * 1000;
const FIRST_DAYS = 90;
const CONSENT_DAYS = 90;
const isoDay = (d: Date) => d.toISOString().slice(0, 10);

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
    const jwt = (req.headers.get("Authorization") ?? "")
      .replace("Bearer ", "").trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) {
      return json({ error: "Sesión inválida" }, 401);
    }
    const uid = userData.user.id;
    const body = await req.json().catch(() => ({}));

    if (body.action === "set_key") {
      const appId = String(body.app_id ?? "").trim();
      const pem = String(body.pem ?? "").trim();
      if (!/^[0-9a-f-]{36}$/i.test(appId)) {
        return json({ error: "El Application ID no es válido" }, 400);
      }
      try {
        await importPem(pem);
      } catch (e) {
        return json({ error: (e as Error).message }, 400);
      }
      const { error } = await admin.rpc("wallet_bank_app_set", {
        p_owner: uid,
        p_app_id: appId,
        p_pem: pem,
      });
      if (error) throw error;
      return json({ ok: true });
    }

    const app = await loadApp(admin, uid);
    if (!app) {
      // La app sincroniza al abrirse: sin bancos no es un error.
      if (body.action === "sync") return json({ accounts: [] });
      return json({ error: "Primero guarda tu clave de Enable Banking" }, 400);
    }

    if (body.action === "banks") {
      // Sin país: todos los bancos de Enable Banking, con su país.
      const country = body.country
        ? `&country=${encodeURIComponent(String(body.country).toUpperCase())}`
        : "";
      const data = await eb(app, `/aspsps?service=AIS${country}`);
      return json({
        banks: (data.aspsps ?? []).map((a: { name: string; country: string }) => ({
          name: a.name,
          country: a.country,
        })),
      });
    }

    if (body.action === "connect") {
      const bank = String(body.bank ?? "");
      const country = String(body.country ?? "ES").toUpperCase();
      if (!bank) return json({ error: "Falta el banco" }, 400);
      const { data: auth, error } = await admin.from("wallet_bank_auth")
        .insert({ owner_id: uid, aspsp_name: bank, aspsp_country: country })
        .select("state").single();
      if (error) throw error;
      const res = await eb(app, "/auth", {
        method: "POST",
        body: {
          access: {
            valid_until: new Date(Date.now() + CONSENT_DAYS * 86400e3)
              .toISOString(),
          },
          aspsp: { name: bank, country },
          state: auth.state,
          redirect_url: `${supabaseUrl}/functions/v1/bank-callback`,
          psu_type: "personal",
        },
      });
      return json({ url: res.url });
    }

    if (body.action === "sync") {
      const { data: links, error } = await admin.from("wallet_bank_links")
        .select("id, last_sync, valid_until").eq("owner_id", uid);
      if (error) throw error;
      const out: { account_id: string; balance: number | null; rows: BankRow[] }[] = [];
      for (const link of links ?? []) {
        const last = link.last_sync ? new Date(link.last_sync) : null;
        if (last && Date.now() - last.getTime() < SYNC_EVERY_MS) continue;
        if (link.valid_until && new Date(link.valid_until) < new Date()) continue;
        const from = new Date(
          last ? last.getTime() - 7 * 86400e3 : Date.now() - FIRST_DAYS * 86400e3,
        );
        const { data: accounts } = await admin.from("wallet_accounts")
          .select("id, bank_uid").eq("bank_link_id", link.id);
        try {
          for (const acc of accounts ?? []) {
            const rows: BankRow[] = [];
            let key: string | null = null;
            do {
              const q = new URLSearchParams({ date_from: isoDay(from) });
              if (key) q.set("continuation_key", key);
              const page = await eb(app, `/accounts/${acc.bank_uid}/transactions?${q}`);
              for (const t of page.transactions ?? []) {
                const r = toRow(t);
                if (r) rows.push(r);
              }
              key = page.continuation_key ?? null;
            } while (key);
            const { data: have } = await admin.from("wallet_transactions")
              .select("external_id").eq("account_id", acc.id)
              .gte("date", isoDay(from)).not("external_id", "is", null);
            const seen = new Set((have ?? []).map((h) => h.external_id));
            const bal = await eb(app, `/accounts/${acc.bank_uid}/balances`);
            out.push({
              account_id: acc.id,
              balance: pickBalance(bal.balances ?? []),
              rows: rows.filter((r) => !seen.has(r.external_id)),
            });
          }
        } catch (e) {
          // Un banco que falla (sesión revocada, banco caído) no para al resto.
          console.error("wallet-bank sync", link.id, e);
          continue;
        }
        await admin.from("wallet_bank_links")
          .update({ last_sync: new Date().toISOString() }).eq("id", link.id);
      }
      return json({ accounts: out });
    }

    return json({ error: "Acción desconocida" }, 400);
  } catch (e) {
    console.error("wallet-bank", e);
    return json({ error: (e as Error).message ?? "Error" }, 502);
  }
});
