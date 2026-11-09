// Idioma y país del hogar para las recetas de la IA. Solo se aceptan los
// valores conocidos (el resto cae a español/España): el texto va al prompt.

const LANGUAGES: Record<string, string> = {
  es: "español",
  en: "inglés",
  de: "alemán",
  fr: "francés",
  it: "italiano",
  pt: "portugués",
  bs: "bosnio",
};

const COUNTRIES: Record<string, [name: string, currency: string]> = {
  ES: ["España", "EUR"],
  DE: ["Alemania", "EUR"],
  FR: ["Francia", "EUR"],
  IT: ["Italia", "EUR"],
  PT: ["Portugal", "EUR"],
  AT: ["Austria", "EUR"],
  BA: ["Bosnia y Herzegovina", "BAM"],
  HR: ["Croacia", "EUR"],
  RS: ["Serbia", "RSD"],
  GB: ["Reino Unido", "GBP"],
  US: ["Estados Unidos", "USD"],
  MX: ["México", "MXN"],
};

export interface RecipeLocale {
  language: string;
  country: string;
  currency: string;
}

export function recipeLocale(body: unknown): RecipeLocale {
  const b = (body ?? {}) as Record<string, unknown>;
  const lang = String(b.lang ?? "").toLowerCase();
  const code = String(b.country ?? "").toUpperCase();
  const [country, currency] = COUNTRIES[code] ?? COUNTRIES.ES;
  return { language: LANGUAGES[lang] ?? LANGUAGES.es, country, currency };
}

/// Línea final de los prompts de recetas: idioma del texto, ingredientes del
/// país y unidades fijas (la app las usa como claves para compra y despensa).
export function recipeLocaleLine(l: RecipeLocale): string {
  return `Escribe todo el contenido (título, descripción, nombres de
ingredientes, pasos y componentes) en ${l.language}. Usa ingredientes que se
encuentren con facilidad en los supermercados de ${l.country}. Los valores de
"unit" van SIEMPRE con las palabras exactas de arriba ("g", "ml", "unidad",
"cucharada", "cucharadita", "pizca", "al gusto"...), sin traducir.`;
}
