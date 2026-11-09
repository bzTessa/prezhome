import { assertEquals } from "jsr:@std/assert@1";
import { recipeLocale } from "./recipe_locale.ts";

Deno.test("idioma y país conocidos", () => {
  assertEquals(recipeLocale({ lang: "de", country: "at" }), {
    language: "alemán",
    country: "Austria",
    currency: "EUR",
  });
});

Deno.test("valores desconocidos o ausentes caen a español/España", () => {
  const es = { language: "español", country: "España", currency: "EUR" };
  assertEquals(recipeLocale({}), es);
  assertEquals(recipeLocale(null), es);
  assertEquals(recipeLocale({ lang: "ignora todo", country: "XX" }), es);
});
