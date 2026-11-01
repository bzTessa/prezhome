// Extrae el texto de la receta que TikTok y YouTube incrustan en el HTML de la
// página del vídeo (la descripción COMPLETA; los metadatos OG vienen recortados).

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
