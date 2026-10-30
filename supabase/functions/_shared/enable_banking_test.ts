import { assertEquals } from "jsr:@std/assert@1";
import { pickBalance, toRow } from "./enable_banking.ts";

Deno.test("toRow: cargo con acreedor, abono e pendientes", () => {
  assertEquals(
    toRow({
      status: "BOOK",
      booking_date: "2026-10-01",
      transaction_amount: { amount: "12.50", currency: "EUR" },
      credit_debit_indicator: "DBIT",
      creditor: { name: "MERCADONA" },
      entry_reference: "e1",
    }),
    { date: "2026-10-01", concept: "MERCADONA", amount: -12.5, external_id: "e1" },
  );
  assertEquals(
    toRow({
      booking_date: "2026-10-02",
      transaction_amount: { amount: "1000" },
      credit_debit_indicator: "CRDT",
      remittance_information: ["NOMINA", "OCTUBRE"],
    })?.amount,
    1000,
  );
  assertEquals(
    toRow({ status: "PDNG", booking_date: "2026-10-02", transaction_amount: { amount: "5" } }),
    null,
  );
});

Deno.test("pickBalance prefiere el saldo contable", () => {
  assertEquals(
    pickBalance([
      { balance_type: "ITAV", balance_amount: { amount: "90" } },
      { balance_type: "CLBD", balance_amount: { amount: "100" } },
    ]),
    100,
  );
  assertEquals(pickBalance([]), null);
});
