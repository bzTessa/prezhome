import { assertEquals } from "jsr:@std/assert@1";
import {
  extractCoverImage,
  instagramCaption,
  instagramEmbedUrl,
  jsonLdRecipe,
  tiktokDescription,
  tiktokSubtitlesUrl,
  vttText,
  youtubeDescription,
  youtubeId,
} from "./extract.ts";

Deno.test("lee la descripción completa de TikTok", () => {
  const html = `<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__">{"itemStruct":` +
    `{"desc":"TARTA DE QUESO 🍰 • INGREDIENTES: 900 grs. queso \\"crema\\"\\n5 huevos"}}</script>`;
  assertEquals(
    tiktokDescription(html),
    'TARTA DE QUESO 🍰 • INGREDIENTES: 900 grs. queso "crema"\n5 huevos',
  );
  assertEquals(tiktokDescription('{"desc":""}'), null);
  assertEquals(tiktokDescription("<html></html>"), null);
});

Deno.test("lee la descripción completa de YouTube", () => {
  const html = `var ytInitialPlayerResponse = {"videoDetails":` +
    `{"shortDescription":"Ingredientes:\\n- 200 g lentejas"}};`;
  assertEquals(youtubeDescription(html), "Ingredientes:\n- 200 g lentejas");
});

Deno.test("saca el id de cualquier enlace de YouTube", () => {
  for (const url of [
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=1",
    "https://m.youtube.com/watch?v=dQw4w9WgXcQ",
    "https://youtu.be/dQw4w9WgXcQ?si=x",
    "https://www.youtube.com/shorts/dQw4w9WgXcQ",
  ]) assertEquals(youtubeId(url), "dQw4w9WgXcQ", url);
  assertEquals(youtubeId("https://www.tiktok.com/@a/video/1"), null);
  assertEquals(youtubeId("https://www.youtube.com/@canal"), null);
});

Deno.test("lee los subtítulos automáticos de TikTok", () => {
  const html = `{"video":{"subtitleInfos":[{"LanguageCodeName":"spa-ES",` +
    `"Url":"https:\\/\\/v16m.tiktokcdn.com\\/sub?a=1\\u0026b=2"}]}}`;
  assertEquals(tiktokSubtitlesUrl(html), "https://v16m.tiktokcdn.com/sub?a=1&b=2");
  assertEquals(tiktokSubtitlesUrl("<html></html>"), null);
  assertEquals(
    vttText("WEBVTT\n\n00:00:00.183 --> 00:00:00.960\nAl loro\n\n" +
      "00:00:05.023 --> 00:00:07.280\npon 900 g de queso crema\n"),
    "Al loro pon 900 g de queso crema",
  );
});

Deno.test("Instagram: embed URL y caption con entidades", () => {
  assertEquals(
    instagramEmbedUrl("https://instagr.am/reel/DAbc_12-x/?igsh=xyz"),
    "https://www.instagram.com/p/DAbc_12-x/embed/captioned/",
  );
  assertEquals(
    instagramEmbedUrl("https://www.instagram.com/share/reel/xyz"),
    null,
  );
  const html =
    '<div class="Caption"><a class="CaptionUsername" href="/ana">ana</a>' +
    "<br /><br />Bizcocho &amp; yogur<br />3 huevos<br />200 g harina" +
    '<div class="CaptionComments"><div>rico</div></div></div>';
  assertEquals(
    instagramCaption(html),
    "Bizcocho & yogur\n3 huevos\n200 g harina",
  );
});

Deno.test("JSON-LD schema.org/Recipe con @graph, HowToSection y portada", () => {
  const html = `<html><head>
    <meta property="og:image" content="https://cdn.example.com/fallback.jpg" />
    <script type="application/ld+json">{
      "@context": "https://schema.org",
      "@graph": [{
        "@type": ["Recipe"],
        "name": "Lentejas caseras",
        "recipeYield": "4 raciones",
        "prepTime": "PT15M",
        "image": {"url": "https://cdn.example.com/lentejas.jpg"},
        "recipeIngredient": ["300 g lentejas", "1 zanahoria"],
        "recipeInstructions": [{
          "@type": "HowToSection",
          "name": "Cocción",
          "itemListElement": [{"@type": "HowToStep", "text": "Cocer 35 minutos."}]
        }]
      }]
    }</script></head></html>`;
  const parsed = jsonLdRecipe(html);
  assertEquals(parsed?.image, "https://cdn.example.com/lentejas.jpg");
  assertEquals(parsed?.text.includes("Lentejas caseras"), true);
  assertEquals(parsed?.text.includes("- 300 g lentejas"), true);
  assertEquals(parsed?.text.includes("2. Cocer 35 minutos."), true);
  assertEquals(
    extractCoverImage(html, "https://recetas.example.com/lentejas"),
    "https://cdn.example.com/lentejas.jpg",
  );
  assertEquals(
    extractCoverImage(
      "<html></html>",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ",
    ),
    "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
  );
});
