import { assertEquals } from "jsr:@std/assert@1";
import { tiktokDescription, youtubeDescription, youtubeId } from "./extract.ts";

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
