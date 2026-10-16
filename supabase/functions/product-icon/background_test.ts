import { assertEquals } from "jsr:@std/assert@1";
import { clearWhiteBackground } from "./background.ts";

// 5x5: borde blanco, anillo gris y un blanco dentro que se queda.
Deno.test("borra solo el blanco que toca el borde", () => {
  const W = 255, G = 100;
  const grid = [
    [W, W, W, W, W],
    [W, G, G, G, W],
    [W, G, W, G, W],
    [W, G, G, G, W],
    [W, W, W, W, W],
  ].flat();
  const rgba = new Uint8Array(grid.flatMap((v) => [v, v, v, 255]));
  clearWhiteBackground(rgba, 5, 5);
  const alpha = Array.from({ length: 25 }, (_, i) => rgba[i * 4 + 3]);
  assertEquals(alpha, grid.map((v, i) => (v === W && i !== 12 ? 0 : 255)));
});
