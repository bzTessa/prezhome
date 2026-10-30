// ============================================================================
// PrezWallet · Edge Function: bank-callback
// ============================================================================
// Vuelta del banco tras autorizar en Enable Banking (?code=…&state=…). Busca
// de quién es el state, abre la sesión, crea una cuenta de PrezWallet por cada
// cuenta del banco y devuelve al usuario a la app (com.prez.prezwallet://banco).
//
// Sin JWT (el navegador del banco no lo tiene): el state, de un solo uso y de
// menos de 1 h, es lo que identifica al usuario. Se despliega con
// --no-verify-jwt.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { eb, loadApp } from "../_shared/enable_banking.ts";

const back = (q: string) =>
  new Response(null, {
    status: 302,
    headers: { Location: `com.prez.prezwallet://banco?${q}` },
  });

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  if (!state || !/^[0-9a-f-]{36}$/i.test(state)) return back("error=state");

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  // De un solo uso: se borra al leerlo.
  const { data: auth } = await admin.from("wallet_bank_auth")
    .delete().eq("state", state).select().maybeSingle();
  if (!auth || Date.now() - new Date(auth.created_at).getTime() > 3600e3) {
    return back("error=state");
  }
  if (!code) return back("error=cancelled");

  try {
    const app = await loadApp(admin, auth.owner_id);
    if (!app) return back("error=key");
    const session = await eb(app, "/sessions", { method: "POST", body: { code } });
    const { data: link, error } = await admin.from("wallet_bank_links").insert({
      owner_id: auth.owner_id,
      session_id: session.session_id,
      aspsp_name: auth.aspsp_name,
      aspsp_country: auth.aspsp_country,
      valid_until: session.access?.valid_until ?? null,
    }).select("id").single();
    if (error) throw error;
    for (const a of session.accounts ?? []) {
      const iban: string | undefined = a.account_id?.iban;
      const name = a.name ?? a.product ??
        `${auth.aspsp_name}${iban ? ` ··${iban.slice(-4)}` : ""}`;
      const ref = a.identification_hash ?? iban ?? a.uid;
      // Si ya estaba conectada (reconectar al caducar) solo se reengancha.
      const { data: had } = await admin.from("wallet_accounts").select("id")
        .eq("owner_id", auth.owner_id).eq("bank_ref", ref).maybeSingle();
      const { error: accErr } = had
        ? await admin.from("wallet_accounts")
          .update({ bank_uid: a.uid, bank_link_id: link.id, archived: false })
          .eq("id", had.id)
        : await admin.from("wallet_accounts").insert({
          owner_id: auth.owner_id,
          name,
          type: "bank",
          currency: a.currency ?? "EUR",
          bank_uid: a.uid,
          bank_ref: ref,
          bank_link_id: link.id,
        });
      if (accErr) throw accErr;
    }
    return back("ok=1");
  } catch (e) {
    console.error("bank-callback", e);
    return back("error=bank");
  }
});
