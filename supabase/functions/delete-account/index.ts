// ============================================================================
// PrezHome · Edge Function: delete-account
// ============================================================================
// Borra la cuenta de quien llama (lo exigen Play Store y App Store):
//   1. Sale de su hogar con leave_home() (si era la única administradora, pasa
//      a serlo el miembro más antiguo).
//   2. Si el hogar se queda sin nadie, se borra con todos sus datos (cascada).
//   3. Borra el usuario de Auth; su perfil y lo personal caen en cascada y lo
//      compartido (tareas, recetas…) queda con created_by = null.
//
// shortcut: las fotos del hogar en Storage no se borran al quedar vacío; si
// hace falta, limpiarlas aquí por carpeta del hogar.
//
// Seguridad: valida el JWT y solo borra al propio usuario.
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceKey) {
      return json({ error: "Configuración del servidor incompleta" }, 500);
    }

    const auth = req.headers.get("Authorization") ?? "";
    const jwt = auth.replace("Bearer ", "").trim();
    if (!jwt) return json({ error: "No autenticado" }, 401);
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    const user = userData?.user;
    if (userErr || !user) return json({ error: "Sesión inválida" }, 401);

    const { data: profile } = await admin
      .from("profiles")
      .select("home_id")
      .eq("id", user.id)
      .maybeSingle();
    const homeId = profile?.home_id as string | null | undefined;

    if (homeId) {
      // Como la persona, para que leave_home() use su auth.uid().
      const asUser = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: auth } },
      });
      const { error: leaveErr } = await asUser.rpc("leave_home");
      if (leaveErr) {
        console.error("leave_home:", leaveErr.message);
        return json({ error: "No se pudo salir del hogar" }, 500);
      }
      const { count, error: countErr } = await admin
        .from("home_members")
        .select("user_id", { count: "exact", head: true })
        .eq("home_id", homeId);
      if (!countErr && count === 0) {
        const { error } = await admin.from("homes").delete().eq("id", homeId);
        if (error) console.error("borrar hogar:", error.message);
      }
    }

    const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
    if (delErr) {
      console.error("deleteUser:", delErr.message);
      return json({ error: "No se pudo borrar la cuenta" }, 500);
    }
    return json({ ok: true });
  } catch (e) {
    console.error("delete-account:", e);
    return json({ error: "No se pudo borrar la cuenta" }, 500);
  }
});
