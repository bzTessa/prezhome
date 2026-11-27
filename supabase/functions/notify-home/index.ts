// ============================================================================
// PrezHome · Edge Function: notify-home
// ============================================================================
// Avisos push entre la gente de casa (Firebase Cloud Messaging, HTTP v1):
//  - shopping_run: "Ana va al súper, ¿falta algo?" a todos los demás.
//  - task_assigned: "Ana te ha puesto: Sacar la basura" a quien le toca.
// Solo avisa a personas del mismo hogar que quien llama. Los tokens están en
// push_tokens (cada móvil guarda el suyo al entrar).
//
// Secreto: FIREBASE_SERVICE_ACCOUNT = JSON de la cuenta de servicio de
// Firebase (Configuración del proyecto > Cuentas de servicio > Generar clave).
// Sin él responde 503 y la app avisa de que los avisos no están activos.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";
import { clean, fcmMessage, isKind } from "./messages.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

function b64url(data: ArrayBuffer | Uint8Array | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Token OAuth de Google para FCM a partir de la cuenta de servicio. */
async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}`);
  return (await res.json()).access_token as string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!supabaseUrl || !serviceKey) {
    return json({ error: "Configuración del servidor incompleta" }, 500);
  }
  if (!saRaw) return json({ error: "push_not_configured" }, 503);

  const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "")
    .trim();
  if (!jwt) return json({ error: "No autenticado" }, 401);
  const admin = createClient(supabaseUrl, serviceKey);
  const { data: userData } = await admin.auth.getUser(jwt);
  const user = userData?.user;
  if (!user) return json({ error: "Sesión inválida" }, 401);

  const body = await req.json().catch(() => ({}));
  if (!isKind(body?.kind)) return json({ error: "Tipo de aviso no válido" }, 400);

  const { data: me } = await admin
    .from("profiles")
    .select("home_id, full_name")
    .eq("id", user.id)
    .maybeSingle();
  const homeId = me?.home_id as string | undefined;
  if (!homeId) return json({ sent: 0 });

  // A quién: todos los demás del hogar, o solo la persona de la tarea.
  let query = admin.from("profiles").select("id").eq("home_id", homeId)
    .neq("id", user.id);
  if (body.kind === "task_assigned") {
    if (typeof body.to !== "string") return json({ sent: 0 });
    query = query.eq("id", body.to);
  }
  const { data: people } = await query;
  const ids = (people ?? []).map((p) => p.id as string);
  if (ids.length === 0) return json({ sent: 0 });

  const { data: tokens } = await admin
    .from("push_tokens")
    .select("token")
    .in("user_id", ids);
  if (!tokens?.length) return json({ sent: 0 });

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(saRaw);
  } catch {
    return json({ error: "push_not_configured" }, 503);
  }
  const bearer = await accessToken(sa);
  const who = clean(me?.full_name, 40).split(" ")[0] || "Alguien";
  let sent = 0;
  for (const { token } of tokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${bearer}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(
          fcmMessage(token as string, { kind: body.kind, who, task: body.task }),
        ),
      },
    );
    if (res.ok) {
      sent++;
    } else if (res.status === 404 || res.status === 400) {
      // Móvil desinstalado o token caducado: fuera, para no reintentarlo.
      await admin.from("push_tokens").delete().eq("token", token);
    } else {
      console.error("fcm", res.status, await res.text());
    }
  }
  return json({ sent });
});
