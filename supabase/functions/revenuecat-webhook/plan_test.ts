import { assertEquals } from "jsr:@std/assert@1";
import { planChanges } from "./plan.ts";

const now = Date.UTC(2026, 9, 19);
const later = now + 30 * 86400000;

Deno.test("compra y renovación dan Pro hasta la caducidad", () => {
  for (const type of ["INITIAL_PURCHASE", "RENEWAL", "CANCELLATION"]) {
    assertEquals(
      planChanges({
        type,
        app_user_id: "u1",
        entitlement_ids: ["pro"],
        expiration_at_ms: later,
      }, now),
      [{ userId: "u1", plan: "pro", renewsAt: new Date(later).toISOString() }],
    );
  }
});

Deno.test("caducada vuelve a gratis", () => {
  assertEquals(
    planChanges({
      type: "EXPIRATION",
      app_user_id: "u1",
      entitlement_ids: ["pro"],
      expiration_at_ms: now - 1,
    }, now),
    [{ userId: "u1", plan: "free", renewsAt: null }],
  );
});

Deno.test("sin permiso pro o evento de prueba no cambia nada", () => {
  assertEquals(planChanges({ type: "TEST", app_user_id: "u1" }, now), []);
});

Deno.test("transferir mueve Pro a la cuenta nueva", () => {
  assertEquals(
    planChanges({
      type: "TRANSFER",
      transferred_from: ["a"],
      transferred_to: ["b"],
    }, now).map((c) => [c.userId, c.plan]),
    [["a", "free"], ["b", "pro"]],
  );
});
