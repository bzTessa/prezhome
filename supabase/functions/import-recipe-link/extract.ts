// Extrae texto e imagen de portada de recetas en TikTok, YouTube, Instagram
// y páginas web con datos estructurados JSON-LD (`schema.org/Recipe`).

const HTML_ENTITIES: Record<string, string> = {
  "&quot;": '"',
  "&lt;": "<",
  "&gt;": ">",
  "&nbsp;": " ",
  "&#39;": "'",
  "&#x27;": "'",
};

export function decodeHtmlEntities(s: string): string {
  let out = s.replace(/&#(x?)([0-9a-fA-F]+);/g, (_m, hex, digits) => {
    const code = Number.parseInt(digits, hex ? 16 : 10);
    return Number.isFinite(code) ? String.fromCodePoint(code) : "";
  });
  for (const [k, v] of Object.entries(HTML_ENTITIES)) {
    out = out.split(k).join(v);
  }
  return out.replace(/&amp;/g, "&");
}

// Lee el string JSON que sigue a "key": en el HTML (escapes incluidos).
function jsonString(html: string, key: string): string | null {
  const m = html.match(new RegExp(`"${key}":("(?:[^"\\\\]|\\\\.)*")`));
  if (!m) return null;
  try {
    const s = (JSON.parse(m[1]) as string).trim();
    return s.length > 0 ? s : null;
  } catch (_e) {
    return null;
  }
}

// Descripción del post de TikTok (bloque __UNIVERSAL_DATA_FOR_REHYDRATION__).
export function tiktokDescription(html: string): string | null {
  return jsonString(html, "desc");
}

// Subtítulos automáticos (WebVTT) del vídeo de TikTok: lo que se DICE en él.
export function tiktokSubtitlesUrl(html: string): string | null {
  const i = html.indexOf('"subtitleInfos"');
  if (i < 0) return null;
  const m = html.slice(i).match(/"Url":("(?:[^"\\]|\\.)*")/);
  if (!m) return null;
  try {
    const u = JSON.parse(m[1]) as string;
    return u.startsWith("https://") ? u : null;
  } catch (_e) {
    return null;
  }
}

// Solo el texto de un WebVTT (sin cabecera ni tiempos).
export function vttText(vtt: string): string {
  return vtt.split("\n").map((l) => l.trim())
    .filter((l) => l && l !== "WEBVTT" && !l.includes("-->"))
    .join(" ");
}

// Descripción completa de un vídeo de YouTube (ytInitialPlayerResponse).
export function youtubeDescription(html: string): string | null {
  return jsonString(html, "shortDescription");
}

// Id del vídeo de YouTube (watch, youtu.be, shorts, embed, live) o null.
export function youtubeId(url: string): string | null {
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^(www|m|music)\./, "");
    let id: string | null = null;
    if (host === "youtu.be") id = u.pathname.split("/")[1];
    else if (host === "youtube.com") {
      id = u.searchParams.get("v") ??
        u.pathname.match(/^\/(?:shorts|embed|live)\/([^/]+)/)?.[1] ?? null;
    }
    return id && /^[\w-]{11}$/.test(id) ? id : null;
  } catch (_e) {
    return null;
  }
}

// `instagram.com/p/CÓDIGO` (reel, reels, tv, instagr.am) → página para incrustar.
export function instagramEmbedUrl(url: string): string | null {
  try {
    const u = new URL(url);
    if (!/(^|\.)(?:instagram\.com|instagr\.am)$/i.test(u.hostname)) return null;
    if (/^\/(?:share|explore|stories|accounts)\//i.test(u.pathname)) return null;
    const m = u.pathname.match(/^\/(?:[\w.]+\/)?(?:p|reels?|tv)\/([\w-]+)/);
    return m ? `https://www.instagram.com/p/${m[1]}/embed/captioned/` : null;
  } catch (_e) {
    return null;
  }
}

// Descripción del post en la página embed de Instagram.
export function instagramCaption(html: string): string | null {
  const start = html.indexOf('class="Caption"');
  if (start < 0) return null;
  let end = html.indexOf('class="CaptionComments"', start);
  end = end < 0 ? html.indexOf("</div>", start) : html.lastIndexOf("<", end);
  if (end < 0) return null;
  const openEnd = html.indexOf(">", start);
  if (openEnd < 0) return null;
  let body = html.slice(openEnd + 1, end);
  body = body
    .replace(/<a[^>]*CaptionUsername[^>]*>.*?<\/a>/s, "")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]*>/g, "");
  const text = decodeHtmlEntities(body).trim();
  return text.length >= 40 ? text : null;
}

function validHttpUrl(raw: string): string | null {
  try {
    const u = new URL(raw);
    return (u.protocol === "http:" || u.protocol === "https:") && u.host
      ? raw
      : null;
  } catch (_e) {
    return null;
  }
}

function isRecipeNodeType(raw: unknown): boolean {
  const matchesOne = (v: unknown): boolean => {
    const s = typeof v === "string" ? v.trim().toLowerCase() : "";
    return s === "recipe" || s.endsWith("/recipe") || s.endsWith(":recipe");
  };
  return Array.isArray(raw) ? raw.some(matchesOne) : matchesOne(raw);
}

function walkJsonLdRecipe(node: unknown): Record<string, unknown> | null {
  if (Array.isArray(node)) {
    for (const item of node) {
      const found = walkJsonLdRecipe(item);
      if (found) return found;
    }
    return null;
  }
  if (!node || typeof node !== "object") return null;
  const map = node as Record<string, unknown>;
  if (isRecipeNodeType(map["@type"])) return map;
  if (map["@graph"] !== undefined) {
    const found = walkJsonLdRecipe(map["@graph"]);
    if (found) return found;
  }
  if (map["mainEntity"] !== undefined) {
    const found = walkJsonLdRecipe(map["mainEntity"]);
    if (found) return found;
  }
  return null;
}

function findJsonLdRecipe(html: string): Record<string, unknown> | null {
  const re =
    /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  for (const m of html.matchAll(re)) {
    const raw = (m[1] ?? "").trim();
    if (!raw) continue;
    try {
      const parsed = JSON.parse(raw);
      const found = walkJsonLdRecipe(parsed);
      if (found) return found;
    } catch (_e) {
      // Bloques JSON-LD rotos se ignoran sin tumbar la página.
    }
  }
  return null;
}

function cleanLdText(v: unknown): string {
  if (v === null || v === undefined) return "";
  return decodeHtmlEntities(String(v)).replace(/<[^>]*>/g, " ").trim();
}

function formatIsoDuration(raw: string): string | null {
  if (!raw) return null;
  const m = raw.match(/^P(?:\d+D)?(?:T(?:(\d+)H)?(?:(\d+)M)?)?$/i);
  if (!m) return raw;
  const h = Number.parseInt(m[1] ?? "0", 10) || 0;
  const mins = Number.parseInt(m[2] ?? "0", 10) || 0;
  const total = h * 60 + mins;
  return total > 0 ? `${total} min` : null;
}

function firstLdImage(raw: unknown): string | null {
  if (typeof raw === "string") return validHttpUrl(decodeHtmlEntities(raw.trim()));
  if (Array.isArray(raw)) {
    for (const item of raw) {
      const found = firstLdImage(item);
      if (found) return found;
    }
    return null;
  }
  if (raw && typeof raw === "object") {
    const obj = raw as Record<string, unknown>;
    return firstLdImage(obj.url ?? obj.contentUrl);
  }
  return null;
}

function ldIngredients(raw: unknown): string[] {
  const items = Array.isArray(raw) ? raw : [raw];
  const out: string[] = [];
  for (const item of items) {
    const txt = item && typeof item === "object"
      ? cleanLdText(
        (item as Record<string, unknown>).text ??
          (item as Record<string, unknown>).name,
      )
      : cleanLdText(item);
    if (txt) out.push(txt);
  }
  return out;
}

function ldSteps(raw: unknown): string[] {
  const out: string[] = [];
  const collect = (item: unknown) => {
    if (item === null || item === undefined) return;
    if (Array.isArray(item)) {
      for (const sub of item) collect(sub);
      return;
    }
    if (typeof item === "object") {
      const map = item as Record<string, unknown>;
      if (map.itemListElement !== undefined) {
        const sec = cleanLdText(map.name);
        if (sec) out.push(sec);
        collect(map.itemListElement);
        return;
      }
      const txt = cleanLdText(map.text ?? map.name);
      if (txt) out.push(txt);
      return;
    }
    const txt = cleanLdText(item);
    for (const line of txt.split(/\r?\n+/)) {
      const s = line.trim();
      if (s) out.push(s);
    }
  };
  collect(raw);
  return out;
}

// Extrae texto estructurado e imagen de un bloque JSON-LD schema.org/Recipe.
export function jsonLdRecipe(
  html: string,
): { text: string; image: string | null } | null {
  const recipe = findJsonLdRecipe(html);
  if (!recipe) return null;
  const ingredients = ldIngredients(recipe.recipeIngredient);
  const steps = ldSteps(recipe.recipeInstructions);
  if (ingredients.length === 0 && steps.length === 0) return null;

  const lines: string[] = [];
  const name = cleanLdText(recipe.name);
  if (name) lines.push(name);
  const desc = cleanLdText(recipe.description);
  if (desc) lines.push(desc);

  const meta: string[] = [];
  const yieldVal = Array.isArray(recipe.recipeYield)
    ? cleanLdText(recipe.recipeYield[0])
    : cleanLdText(recipe.recipeYield);
  if (yieldVal) meta.push(`Raciones: ${yieldVal}`);
  const prep = formatIsoDuration(cleanLdText(recipe.prepTime));
  if (prep) meta.push(`Prep: ${prep}`);
  const cook = formatIsoDuration(cleanLdText(recipe.cookTime));
  if (cook) meta.push(`Cocción: ${cook}`);
  const total = formatIsoDuration(cleanLdText(recipe.totalTime));
  if (total && !prep && !cook) meta.push(`Total: ${total}`);
  if (meta.length > 0) lines.push(meta.join(" · "));

  if (ingredients.length > 0) {
    lines.push("", "Ingredientes:");
    for (const ing of ingredients) lines.push(`- ${ing}`);
  }
  if (steps.length > 0) {
    lines.push("", "Pasos:");
    steps.forEach((s, idx) => lines.push(`${idx + 1}. ${s}`));
  }
  return {
    text: lines.join("\n").trim(),
    image: firstLdImage(recipe.image),
  };
}

function metaImage(html: string, keys: string[]): string | null {
  for (const key of keys) {
    for (const re of [
      new RegExp(
        `<meta[^>]+(?:property|name)=["']${key}["'][^>]*content=["']([^"']*)["']`,
        "i",
      ),
      new RegExp(
        `<meta[^>]+content=["']([^"']*)["'][^>]*(?:property|name)=["']${key}["']`,
        "i",
      ),
    ]) {
      const m = html.match(re);
      if (m?.[1]) {
        const u = validHttpUrl(decodeHtmlEntities(m[1].trim()));
        if (u) return u;
      }
    }
  }
  return null;
}

// Portada del vídeo o web de receta: JSON-LD -> Instagram embed -> OG/Twitter -> YouTube.
export function extractCoverImage(html: string, url: string): string | null {
  const fromJsonLd = firstLdImage(findJsonLdRecipe(html)?.image);
  if (fromJsonLd) return fromJsonLd;

  try {
    const host = new URL(url).hostname;
    if (/(^|\.)(?:instagram\.com|instagr\.am)$/i.test(host)) {
      for (const re of [
        /<img[^>]+class=["'][^"']*EmbeddedMediaImage[^"']*["'][^>]*src=["']([^"']+)["']/i,
        /<img[^>]+src=["']([^"']+)["'][^>]*class=["'][^"']*EmbeddedMediaImage[^"']*["']/i,
      ]) {
        const m = html.match(re);
        if (m?.[1]) {
          const u = validHttpUrl(decodeHtmlEntities(m[1].trim()));
          if (u) return u;
        }
      }
    }
  } catch (_e) {
    // URL inválida: seguimos con metadatos.
  }

  const fromMeta = metaImage(html, [
    "og:image",
    "og:image:secure_url",
    "twitter:image",
  ]);
  if (fromMeta) return fromMeta;

  const yt = youtubeId(url);
  return yt ? `https://i.ytimg.com/vi/${yt}/hqdefault.jpg` : null;
}
