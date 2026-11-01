// Cliente mínimo de la API de Enable Banking (https://enablebanking.com/docs).
// Cada llamada va firmada con un JWT RS256 hecho con la clave privada de la
// aplicación del usuario (kid = Application ID).

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export const EB_API = "https://api.enablebanking.com";

export type EbApp = { appId: string; key: CryptoKey };

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_")
    .replace(/=+$/, "");

/** Importa la clave .pem (PKCS#8, la que da Enable Banking). Lanza si no vale. */
export async function importPem(pem: string): Promise<CryptoKey> {
  if (!pem.includes("BEGIN PRIVATE KEY")) {
    throw new Error("La clave debe ser el .pem que descargaste de Enable Banking");
  }
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function jwt(app: EbApp): Promise<string> {
  const enc = new TextEncoder();
  const iat = Math.floor(Date.now() / 1000);
  const head = b64url(enc.encode(JSON.stringify(
    { typ: "JWT", alg: "RS256", kid: app.appId },
  )));
  const body = b64url(enc.encode(JSON.stringify({
    iss: "enablebanking.com",
    aud: "api.enablebanking.com",
    iat,
    exp: iat + 3600,
  })));
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    app.key,
    enc.encode(`${head}.${body}`),
  );
  return `${head}.${body}.${b64url(new Uint8Array(sig))}`;
}

/** Llama a la API; lanza con el mensaje de Enable Banking si falla. */
export async function eb(
  app: EbApp,
  path: string,
  init: { method?: string; body?: unknown } = {},
  // deno-lint-ignore no-explicit-any
): Promise<any> {
  const res = await fetch(`${EB_API}${path}`, {
    method: init.method ?? "GET",
    headers: {
      Authorization: `Bearer ${await jwt(app)}`,
      "Content-Type": "application/json",
    },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data?.message ?? `Enable Banking respondió ${res.status}`);
  }
  return data;
}

/** Aplicación del usuario desde Vault, o null si aún no la ha guardado. */
export async function loadApp(
  admin: SupabaseClient,
  ownerId: string,
): Promise<EbApp | null> {
  const { data, error } = await admin.rpc("wallet_bank_app_key", {
    p_owner: ownerId,
  });
  if (error) throw error;
  const row = (data as { app_id: string; pem: string }[])[0];
  return row ? { appId: row.app_id, key: await importPem(row.pem) } : null;
}

export type BankRow = {
  date: string;
  concept: string;
  amount: number;
  external_id: string;
};

/** Movimiento de Enable Banking -> fila para PrezWallet; null si pendiente. */
// deno-lint-ignore no-explicit-any
export function toRow(t: any): BankRow | null {
  if (t.status && t.status !== "BOOK") return null;
  const date = t.booking_date ?? t.value_date ?? t.transaction_date;
  const abs = Math.abs(Number(t.transaction_amount?.amount));
  if (!date || !abs) return null;
  const debit = t.credit_debit_indicator === "DBIT";
  const party = debit ? t.creditor?.name : t.debtor?.name;
  const info = (t.remittance_information ?? []).join(" ").trim();
  // Trade Republic no manda contraparte: el texto viene en note o en el código.
  const concept = (party || info || t.note || t.bank_transaction_code?.description ||
    "").trim();
  const amount = debit ? -abs : abs;
  return {
    date,
    concept,
    amount,
    external_id: t.entry_reference ?? t.transaction_id ??
      `${date}|${amount}|${concept}`,
  };
}

/** Saldo actual: el contable o el disponible, el que dé el banco. */
// deno-lint-ignore no-explicit-any
export function pickBalance(balances: any[]): number | null {
  const order = ["CLBD", "ITBD", "XPCD", "ITAV", "CLAV"];
  const rank = (x: { balance_type: string }) => {
    const i = order.indexOf(x.balance_type);
    return i < 0 ? order.length : i;
  };
  const b = [...balances].sort((x, y) => rank(x) - rank(y))[0];
  return b ? Number(b.balance_amount.amount) : null;
}
