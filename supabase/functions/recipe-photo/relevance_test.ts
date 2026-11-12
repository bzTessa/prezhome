import { assertEquals } from "jsr:@std/assert@1";
import {
  conflictingDishTypes,
  keywordsFor,
  pickRelevant,
  plausible,
} from "./relevance.ts";

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
    { alt: "chicken with blue cheese sauce" },
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

Deno.test("una marca en el título no trae fotos de animales", () => {
  const kw = keywordsFor("Cheesecake Happy Hippo Súper Cremosa");
  const hippo = { alt: "happy hippo opening its mouth in the river" };
  const cake = { alt: "slice of cheesecake with chocolate on a plate" };
  assertEquals(plausible(hippo.alt, kw), false);
  assertEquals(pickRelevant([hippo], alt, kw), null);
  assertEquals(pickRelevant([hippo, cake], alt, kw)?.alt, cake.alt);
});

Deno.test("otro tipo de plato con los mismos ingredientes no vale", () => {
  const kw = keywordsFor("Pollo al queso azul con arroz redondo");
  const caesar = { alt: "chicken caesar salad with parmesan cheese" };
  const rice = { alt: "chicken in creamy cheese sauce with rice" };
  assertEquals(conflictingDishTypes(caesar.alt, kw), ["salad"]);
  assertEquals(pickRelevant([caesar], alt, kw), null);
  assertEquals(pickRelevant([caesar, rice], alt, kw)?.alt, rice.alt);
});

Deno.test("cheesecake no choca con 'cake'", () => {
  const kw = keywordsFor("Tarta de queso", "cheesecake");
  assertEquals(conflictingDishTypes("strawberry cheesecake cake", kw), []);
});
