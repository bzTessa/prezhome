// Evita que la función descargue direcciones internas (SSRF): solo hosts con
// nombre público o IPs públicas. URL ya normaliza formas raras (0x7f.1 → 127.0.0.1).
// shortcut: no resuelve DNS, así que un dominio que apunte a una IP interna pasa;
// si el runtime llega a exponer red interna, comprobar también la IP resuelta.
export function isPublicUrl(raw: string): boolean {
  let u: URL;
  try {
    u = new URL(raw);
  } catch (_e) {
    return false;
  }
  if (u.protocol !== "http:" && u.protocol !== "https:") return false;
  const h = u.hostname.toLowerCase().replace(/^\[|\]$/g, "");
  if (
    h === "localhost" || h.endsWith(".localhost") || h.endsWith(".local") ||
    h.endsWith(".internal")
  ) return false;
  if (h.includes(":")) {
    return !(h === "::" || h === "::1" || h.startsWith("fc") ||
      h.startsWith("fd") || h.startsWith("fe80") || h.startsWith("::ffff:"));
  }
  const v4 = h.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (v4) {
    const a = Number(v4[1]), b = Number(v4[2]);
    return !(a === 0 || a === 10 || a === 127 || a >= 224 ||
      (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168) || (a === 100 && b >= 64 && b <= 127));
  }
  return h.includes(".");
}
