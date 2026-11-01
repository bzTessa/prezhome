import { assertEquals } from "jsr:@std/assert@1";
import { keywordsFor, pickRelevant } from "./relevance.ts";

const alt = (a: { alt: string }) => a.alt;

Deno.test("descarta un retrato para 'Café doble con leche'", () => {
  const kw = keywordsFor("Café doble con leche");
  const photos = [
    { alt: "man in black crew neck shirt" },
    { alt: "white ceramic mug with latte art coffee" },
  ];
  assertEquals(pickRelevant(photos, alt, kw)?.alt, photos[1].alt);
  assertEquals(pickRelevant([photos[0]], alt, kw), null);
});

Deno.test("prefiere la foto que menciona más ingredientes", () => {
  const kw = keywordsFor("Lentejas estofadas con chorizo", "lentil stew");
  const photos = [
    { alt: "a bowl of soup on a table" },
    { alt: "sausage on grill" },
    { alt: "lentil stew with chorizo sausage" },
  ];
  assertEquals(pickRelevant(photos, alt, kw)?.alt, photos[2].alt);
});

Deno.test("casa plurales en inglés", () => {
  const kw = keywordsFor("Pollo al horno con patatas");
  const photos = [{ alt: "roasted chicken with potatoes" }];
  assertEquals(pickRelevant(photos, alt, kw)?.alt, photos[0].alt);
});
