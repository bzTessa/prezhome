// Gemini mira las fotos candidatas y dice cuál es de verdad el plato.
// El texto de Unsplash/Pexels (alt, etiquetas) no basta: "Pollo al queso azul
// con arroz" casaba con una ensalada César (salen pollo y queso) y "Cheesecake
// Happy Hippo" con un hipopótamo (la marca se buscaba tal cual).
// Sin GEMINI_API_KEY o si Gemini falla, todo devuelve null y la función usa el
// filtro por palabras de relevance.ts.

import { encodeBase64 } from "jsr:@std/encoding@1/base64";

export interface Dish {
  title: string;
  description?: string;
  ingredients?: string[];
}

const API = "https://generativelanguage.googleapis.com/v1beta";

// Modelos flash con generateContent (los nombres cambian: se piden a Google).
let modelsCache: string[] | null = null;
async function models(key: string): Promise<string[]> {
  if (modelsCache) return modelsCache;
  try {
    const res = await fetch(`${API}/models?key=${key}`, {
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return [];
    const data = await res.json();
    modelsCache = (data?.models ?? [])
      // deno-lint-ignore no-explicit-any
      .filter((m: any) =>
        m?.supportedGenerationMethods?.includes("generateContent")
      )
      // deno-lint-ignore no-explicit-any
      .map((m: any) => String(m.name))
      .filter((n: string) =>
        n.includes("flash") && !/image|tts|audio|live|embedding/.test(n)
      )
      .sort((a: string, b: string) => b.localeCompare(a));
    return modelsCache!;
  } catch (_) {
    return [];
  }
}

// deno-lint-ignore no-explicit-any
async function askJson(key: string, parts: unknown[]): Promise<any | null> {
  for (const model of (await models(key)).slice(0, 3)) {
    try {
      const res = await fetch(`${API}/${model}:generateContent?key=${key}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts }],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0,
          },
        }),
        signal: AbortSignal.timeout(20000),
      });
      if (!res.ok) {
        console.error(`${model}: HTTP ${res.status}`, await res.text());
        if (res.status === 401 || res.status === 403) return null;
        continue;
      }
      const data = await res.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text !== "string") continue;
      return JSON.parse(text.replace(/^```(json)?|```$/g, "").trim());
    } catch (e) {
      console.error(`${model}:`, e);
    }
  }
  return null;
}

function describe(dish: Dish): string {
  const ings = (dish.ingredients ?? []).slice(0, 12).join(", ");
  return [
    `Título: ${dish.title}`,
    dish.description ? `Descripción: ${dish.description}` : "",
    ings ? `Ingredientes: ${ings}` : "",
  ].filter(Boolean).join("\n");
}

/**
 * Búsquedas en inglés para un banco de fotos que describen cómo se VE el plato
 * terminado, sin marcas ni nombres propios ("Happy Hippo" es una chocolatina,
 * no un animal). null si Gemini no responde.
 */
export async function photoQueries(
  key: string,
  dish: Dish,
): Promise<string[] | null> {
  const out = await askJson(key, [{
    text: `Vas a buscar en Unsplash una foto del plato de esta receta.
${describe(dish)}

Escribe 2 búsquedas cortas EN INGLÉS (2 a 5 palabras) que describan el plato
terminado tal como se ve en una foto: tipo de plato y su ingrediente principal.
- Quita marcas, nombres de productos y nombres propios: "Cheesecake Happy Hippo"
  es "chocolate cheesecake", nunca "hippo".
- No uses adjetivos de marketing (súper, cremosa, fácil, casera).
- La primera, la más fiel; la segunda, más general.
Devuelve SOLO JSON: {"queries": ["...", "..."]}`,
  }]);
  const qs = Array.isArray(out?.queries)
    ? out.queries.map((q: unknown) => String(q ?? "").trim()).filter(Boolean)
    : [];
  return qs.length > 0 ? qs.slice(0, 2) : null;
}

// Solo bajamos fotos de los bancos que usamos (nada de URLs arbitrarias).
const ALLOWED_HOSTS = ["images.unsplash.com", "images.pexels.com"];

export function allowedPhotoUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return u.protocol === "https:" && ALLOWED_HOSTS.includes(u.hostname);
  } catch (_) {
    return false;
  }
}

async function inline(url: string): Promise<unknown | null> {
  if (!allowedPhotoUrl(url)) return null;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const type = res.headers.get("content-type") ?? "image/jpeg";
    const bytes = new Uint8Array(await res.arrayBuffer());
    if (bytes.length > 1_500_000) return null;
    return {
      inline_data: {
        mime_type: type.split(";")[0],
        data: encodeBase64(bytes),
      },
    };
  } catch (_) {
    return null;
  }
}

/**
 * Índice (en [thumbs]) de la foto que muestra el plato, -1 si ninguna, null si
 * Gemini no ha podido mirarlas. [thumbs] son URLs pequeñas (~400 px).
 */
export async function chooseDishPhoto(
  key: string,
  dish: Dish,
  thumbs: string[],
): Promise<number | null> {
  const images = await Promise.all(thumbs.map(inline));
  const parts: unknown[] = [];
  const index: number[] = [];
  images.forEach((img, i) => {
    if (!img) return;
    parts.push({ text: `Foto ${index.length}:` }, img);
    index.push(i);
  });
  if (index.length === 0) return null;
  const out = await askJson(key, [
    {
      text: `Eres editor de fotos de una app de recetas. Elige la foto que
mejor muestra ESTE plato ya cocinado.
${describe(dish)}

Una foto vale solo si:
- Es comida y es el mismo TIPO de plato (una ensalada no vale para un plato de
  arroz, ni una tarta normal para un guiso).
- Se ven el ingrediente principal o la base del plato (p. ej. pollo y arroz;
  tarta de queso). La presentación puede variar.
No valen: animales, personas, paisajes, envases o productos de marca,
ingredientes crudos sueltos, ni otro plato aunque comparta ingredientes.
Las marcas o nombres propios del título no se buscan en la foto.
Si dudas, ninguna: es mejor un dibujo que una foto equivocada.`,
    },
    ...parts,
    {
      text: `Devuelve SOLO JSON: {"best": <número de foto o -1>, "why": "<5 palabras>"}`,
    },
  ]);
  if (out == null || typeof out.best !== "number") return null;
  const best = Math.trunc(out.best);
  if (best < 0 || best >= index.length) return -1;
  return index[best];
}
