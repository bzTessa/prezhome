// ¿La foto de un banco de imágenes es del plato que buscamos?
// Unsplash/Pexels devuelven lo "más popular" para la búsqueda, y con nombres
// en español o búsquedas genéricas salían retratos, paisajes u otro plato.
// Comparamos el texto de la foto (alt/descripción/etiquetas, casi siempre en
// inglés) con las palabras clave del plato y su traducción, y solo aceptamos
// fotos que mencionen al menos una.

// Ingredientes y platos habituales es -> en, para casar con el alt en inglés.
// shortcut: lista corta a mano; si faltan platos, ampliarla o pedir query_en a la IA.
const ES_EN: Record<string, string[]> = {
  pollo: ["chicken"],
  contramuslo: ["chicken"],
  pechuga: ["chicken"],
  pavo: ["turkey"],
  ternera: ["beef"],
  carne: ["meat", "beef"],
  cerdo: ["pork"],
  lomo: ["pork", "loin"],
  cordero: ["lamb"],
  salmon: ["salmon"],
  merluza: ["hake", "fish"],
  bacalao: ["cod", "fish"],
  atun: ["tuna"],
  pescado: ["fish"],
  sardinas: ["sardine"],
  gambas: ["shrimp", "prawn"],
  langostinos: ["shrimp", "prawn"],
  mejillones: ["mussel"],
  calamares: ["squid", "calamari"],
  arroz: ["rice"],
  paella: ["paella"],
  pasta: ["pasta"],
  espaguetis: ["spaghetti"],
  macarrones: ["macaroni", "pasta"],
  lasana: ["lasagna"],
  fideos: ["noodle"],
  pan: ["bread"],
  tostada: ["toast"],
  tostadas: ["toast"],
  pizza: ["pizza"],
  hamburguesa: ["burger"],
  lentejas: ["lentil"],
  garbanzos: ["chickpea"],
  alubias: ["bean"],
  judias: ["bean"],
  patatas: ["potato"],
  patata: ["potato"],
  huevo: ["egg"],
  huevos: ["egg"],
  tortilla: ["omelet", "tortilla", "frittata"],
  espinacas: ["spinach"],
  queso: ["cheese"],
  tomate: ["tomato"],
  ensalada: ["salad"],
  sopa: ["soup"],
  crema: ["soup", "cream"],
  caldo: ["broth", "soup"],
  verduras: ["vegetable"],
  champinones: ["mushroom"],
  setas: ["mushroom"],
  cebolla: ["onion"],
  pimiento: ["pepper"],
  calabacin: ["zucchini"],
  berenjena: ["eggplant", "aubergine"],
  brocoli: ["broccoli"],
  zanahoria: ["carrot"],
  aguacate: ["avocado"],
  esparragos: ["asparagus"],
  chorizo: ["chorizo", "sausage"],
  jamon: ["ham"],
  cafe: ["coffee"],
  leche: ["milk", "latte"],
  chocolate: ["chocolate"],
  tarta: ["cake", "tart", "pie"],
  pastel: ["cake"],
  bizcocho: ["cake"],
  cheesecake: ["cheesecake"],
  galletas: ["cookie"],
  yogur: ["yogurt"],
  fruta: ["fruit"],
  manzana: ["apple"],
  platano: ["banana"],
  fresas: ["strawberr"],
  avena: ["oat", "porridge"],
  batido: ["smoothie", "shake"],
  zumo: ["juice"],
  bowl: ["bowl"],
  curry: ["curry"],
  quinoa: ["quinoa"],
  tofu: ["tofu"],
  gazpacho: ["gazpacho", "soup"],
  croquetas: ["croquette"],
  empanada: ["empanada", "pie"],
  crepes: ["crepe"],
  tortitas: ["pancake"],
};

// Palabras que no describen el plato (en inglés y español).
const IGNORE = new Set([
  "with",
  "and",
  "the",
  "style",
  "dish",
  "food",
  "meal",
  "homemade",
  "baked",
  "roasted",
  "fried",
  "grilled",
  "stir",
  "fry",
  "double",
  "con",
  "del",
  "los",
  "las",
  "plato",
  "comida",
  "horno",
  "salteado",
  "salteados",
  "salteada",
  "estofadas",
  "estofado",
  "casero",
  "casera",
  "doble",
  "super",
  "cremosa",
  "cremoso",
  "hacendado",
  "redondo",
  "azul",
  "costra",
  "panaderas",
]);

function norm(s: string): string {
  return s.toLowerCase().normalize("NFD").replace(/\p{M}/gu, "");
}

/** Palabras que deberían aparecer en la descripción de una foto acertada. */
export function keywordsFor(query: string, queryEn = ""): string[] {
  const out = new Set<string>();
  for (const w of norm(`${query} ${queryEn}`).split(/[^\p{L}\p{N}]+/u)) {
    if (w.length < 3 || IGNORE.has(w)) continue;
    // "potatoes" -> "potato": comparamos por raíz para casar plurales.
    const stem = w.replace(/(es|s)$/, "");
    out.add(stem.length >= 3 ? stem : w);
    for (const en of ES_EN[w] ?? []) out.add(en);
  }
  return [...out];
}

/** Cuántas palabras clave menciona el texto de la foto (0 = no es el plato). */
export function relevance(photoText: string, keywords: string[]): number {
  const text = norm(photoText);
  return keywords.filter((k) => text.includes(k)).length;
}

/** Texto descriptivo de un resultado de Unsplash (alt, descripción, etiquetas). */
// deno-lint-ignore no-explicit-any
export function unsplashText(r: Record<string, any>): string {
  const tags = Array.isArray(r?.tags)
    ? r.tags.map((t: Record<string, unknown>) => t?.title ?? "").join(" ")
    : "";
  return `${r?.alt_description ?? ""} ${r?.description ?? ""} ${tags}`;
}

/**
 * La foto más relevante de una lista (la primera en caso de empate, que es la
 * más popular para el banco). null si ninguna menciona el plato.
 */
export function pickRelevant<T>(
  items: T[],
  textOf: (item: T) => string,
  keywords: string[],
): T | null {
  let best: T | null = null;
  let bestScore = 0;
  for (const item of items) {
    const s = relevance(textOf(item), keywords);
    if (s > bestScore) {
      best = item;
      bestScore = s;
    }
  }
  return best;
}
