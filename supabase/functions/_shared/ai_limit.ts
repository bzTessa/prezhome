import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

// Mensaje del 429 por límite mensual de IA: dice cuándo se renueva el cupo.
// consume_ai_credit reinicia el contador el día 1 de cada mes (hora UTC).
const MESES = [
  "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
  "agosto", "septiembre", "octubre", "noviembre", "diciembre",
];

export function aiLimitMessage(now = new Date()): string {
  const next = MESES[(now.getUTCMonth() + 1) % 12];
  return `Has llegado al límite de este mes. Se renueva el 1 de ${next}.`;
}

// Funciones con cupo propio en plan_quotas (migración 0049).
export type AiFeature =
  | "scan_ticket"
  | "recipes"
  | "meal_photo"
  | "import_link"
  | "product_icon";

export type UseCredit = (
  admin: SupabaseClient,
  homeId: string,
) => Promise<"ok" | "limit" | "error">;

// Deno.serve que cobra un uso de `feature` con useCredit y lo devuelve si la
// respuesta acaba en error: un fallo nuestro o de Gemini no gasta cupo.
export function serveAi(
  feature: AiFeature,
  handle: (req: Request, useCredit: UseCredit) => Promise<Response>,
): void {
  Deno.serve(async (req) => {
    const charged: { refund?: () => Promise<void> } = {};
    const useCredit: UseCredit = async (admin, homeId) => {
      const args = { target_home_id: homeId, target_feature: feature };
      const { data, error } = await admin.rpc("consume_ai_credit", args);
      if (error) return "error";
      if (data !== true) return "limit";
      charged.refund = async () => {
        const { error } = await admin.rpc("refund_ai_credit", args);
        if (error) console.error("refund_ai_credit:", error.message);
      };
      return "ok";
    };
    const res = await handle(req, useCredit);
    if (!res.ok && charged.refund) await charged.refund();
    return res;
  });
}
