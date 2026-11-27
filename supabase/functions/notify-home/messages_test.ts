import { assertEquals } from "jsr:@std/assert@1";
import { clean, fcmMessage, isKind } from "./messages.ts";

Deno.test("clean squashes spaces and trims to the limit", () => {
  assertEquals(clean("  Sacar   la\nbasura  "), "Sacar la basura");
  assertEquals(clean("x".repeat(100), 10), "x".repeat(10));
  assertEquals(clean(null), "");
});

Deno.test("only the two known kinds are accepted", () => {
  assertEquals(isKind("shopping_run"), true);
  assertEquals(isKind("task_assigned"), true);
  assertEquals(isKind("anything"), false);
});

Deno.test("shopping run uses the shopping keys and opens Compra", () => {
  const m = fcmMessage("tok", { kind: "shopping_run", who: "Ana" }).message;
  assertEquals(m.android.notification.body_loc_key, "push_shopping_body");
  assertEquals(m.android.notification.body_loc_args, ["Ana"]);
  assertEquals(m.data.open, "shopping");
});

Deno.test("task assigned passes who and the task title", () => {
  const m = fcmMessage("tok", {
    kind: "task_assigned",
    who: "Ana",
    task: "Sacar la basura",
  }).message;
  assertEquals(m.android.notification.body_loc_args, ["Ana", "Sacar la basura"]);
  assertEquals(m.data.open, "tasks");
});
