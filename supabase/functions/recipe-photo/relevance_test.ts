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

Deno.test("una sola palabra suelta no basta si el plato tiene varias", () => {
  const kw = keywordsFor("Pollo al queso azul con arroz redondo");
  const photos = [
    { alt: "bowl of white rice" },
    { alt: "caesar salad with chicken and parmesan cheese" },
  ];
  assertEquals(pickRelevant([photos[0]], alt, kw), null);
  assertEquals(pickRelevant(photos, alt, kw)?.alt, photos[1].alt);
});

Deno.test("query_en no cuenta dos veces la misma palabra", () => {
  const kw = keywordsFor("Lentejas con chorizo", "lentil stew");
  assertEquals(pickRelevant([{ alt: "lentil soup" }], alt, kw), null);
});

Deno.test("un plato de una palabra vale con esa palabra", () => {
  const kw = keywordsFor("Gazpacho");
  assertEquals(pickRelevant([{ alt: "cold tomato soup" }], alt, kw)?.alt, "cold tomato soup");
});
