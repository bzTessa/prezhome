// Decide el plan de cada usuario a partir de un evento de RevenueCat.
// Docs de eventos: https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields

export const PRO_ENTITLEMENT = "pro";

export type RcEvent = {
  type: string;
  app_user_id?: string;
  entitlement_ids?: string[] | null;
  expiration_at_ms?: number | null;
  transferred_from?: string[];
  transferred_to?: string[];
};

export type PlanChange = {
  userId: string;
  plan: "free" | "pro";
  renewsAt: string | null;
};

// Una cancelación no quita Pro: dura hasta EXPIRATION. TEST y eventos sin
// el permiso "pro" no cambian nada.
export function planChanges(e: RcEvent, now = Date.now()): PlanChange[] {
  if (e.type === "TRANSFER") {
    // Restaurar compras en otra cuenta: Pro pasa a la cuenta nueva.
    return [
      ...(e.transferred_from ?? []).map((userId) => ({
        userId,
        plan: "free" as const,
        renewsAt: null,
      })),
      ...(e.transferred_to ?? []).map((userId) => ({
        userId,
        plan: "pro" as const,
        renewsAt: null,
      })),
    ];
  }
  if (!e.app_user_id || !(e.entitlement_ids ?? []).includes(PRO_ENTITLEMENT)) {
    return [];
  }
  const exp = e.expiration_at_ms ?? null;
  const active = e.type !== "EXPIRATION" && (exp === null || exp > now);
  return [{
    userId: e.app_user_id,
    plan: active ? "pro" : "free",
    renewsAt: active && exp !== null ? new Date(exp).toISOString() : null,
  }];
}
