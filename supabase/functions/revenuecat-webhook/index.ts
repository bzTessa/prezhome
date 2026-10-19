// ============================================================================
// PrezHome · Edge Function: revenuecat-webhook
// ============================================================================
// RevenueCat avisa aquí de compras, renovaciones, caducidades y
// transferencias. El app_user_id es el id de Supabase del usuario (la app
// hace Purchases.logIn con él), y Pro se aplica a su hogar actual en
// subscriptions.plan, que es lo que lee consume_ai_credit para los cupos.
//
// Seguridad: RevenueCat no manda JWT de Supabase, así que se despliega con
// --no-verify-jwt y se comprueba la cabecera Authorization contra el secreto
// REVENUECAT_WEBHOOK_AUTH (el mismo valor que se pone en RevenueCat).
// shortcut: el plan va al hogar donde está quien compra; si cambia de hogar,
// Pro se queda en el antiguo hasta el siguiente evento (renovación).
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { planChanges, type RcEvent } from "./plan.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!secret || !supabaseUrl || !serviceKey) {
    return json({ error: "Configuración del servidor incompleta" }, 500);
  }
  if (req.headers.get("Authorization") !== secret) {
    return json({ error: "No autorizado" }, 401);
  }

  let event: RcEvent;
  try {
    event = (await req.json()).event;
  } catch {
    return json({ error: "Cuerpo inválido" }, 400);
  }
  if (!event?.type) return json({ error: "Falta el evento" }, 400);

  const admin = createClient(supabaseUrl, serviceKey);
  for (const change of planChanges(event)) {
    // Ids anónimos de RevenueCat ($RCAnonymousID:…) no son usuarios nuestros.
    if (change.userId.startsWith("$RCAnonymousID")) continue;
    const { data: profile, error } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", change.userId)
      .maybeSingle();
    // Un error devuelve 500 para que RevenueCat reintente.
    if (error) return json({ error: error.message }, 500);
    if (!profile?.home_id) continue;
    const { error: upErr } = await admin.from("subscriptions").upsert({
      home_id: profile.home_id,
      plan: change.plan,
      renews_at: change.renewsAt,
      updated_at: new Date().toISOString(),
    });
    if (upErr) return json({ error: upErr.message }, 500);
  }
  return json({ ok: true });
});
