/// Sugerencias rápidas ("añadir con un toque") de condimentos típicos y de
/// básicos frecuentes de despensa/compra, para que la usuaria no tenga ni que
/// escribir: toca un chip y el producto se rellena/añade solo.
///
/// Lógica PURA (sin Flutter) para poder testearla y reutilizarla desde varias
/// pantallas (alta de inventario, despensa...). Aquí solo vive la LISTA de
/// nombres y su normalización; cada pantalla decide cómo pintarlos (iconos y
/// colores salen de los tokens de tema vía CategoryIcons, no de aquí).
library;

/// Un elemento de sugerencia rápida: el [name] legible que verá y guardará la
/// usuaria (en español) y la [unit] por defecto con la que se añade.
///
/// Para condimentos usamos SIEMPRE 'unidades' como unidad por defecto: la sal,
/// el comino o el pimentón se compran por bote/paquete entero, nunca por
/// cucharadas (coherente con la regla de FEAT: condimentos en unidades
/// enteras, no cucharaditas).
class QuickItem {
  const QuickItem(this.name, {this.unit = 'unidades'});

  /// Nombre legible del producto, en español, tal cual se guarda.
  final String name;

  /// Unidad por defecto con la que se añade al tocar el chip.
  final String unit;
}

/// Normaliza un texto a minúsculas, recortado y sin acentos, para comparar y
/// detectar duplicados de forma estable. Misma estrategia que
/// `CategoryIcons.normalize`, replicada aquí para mantener este archivo PURO
/// (sin importar Flutter ni widgets).
String normalizeQuickName(String input) {
  final lower = input.toLowerCase().trim();
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final idx = from.indexOf(char);
    buffer.write(idx >= 0 ? to[idx] : char);
  }
  return buffer.toString();
}

/// Condimentos y especias típicas que se añaden con un solo toque desde el alta
/// de la categoría 'Especias'. Pensado para que estén "los de siempre" sin
/// teclear: sal, azúcar, pimientas, comino, etc.
const List<QuickItem> kQuickCondiments = [
  QuickItem('Sal'),
  QuickItem('Azúcar'),
  QuickItem('Pimienta negra'),
  QuickItem('Pimienta blanca'),
  QuickItem('Comino'),
  QuickItem('Orégano'),
  QuickItem('Pimentón'),
  QuickItem('Aceite'),
  QuickItem('Vinagre'),
  QuickItem('Canela'),
  QuickItem('Laurel'),
  QuickItem('Ajo en polvo'),
  QuickItem('Perejil'),
  QuickItem('Nuez moscada'),
  QuickItem('Curry'),
  QuickItem('Cúrcuma'),
  QuickItem('Albahaca'),
  QuickItem('Tomillo'),
  QuickItem('Romero'),
  QuickItem('Levadura'),
];

/// Básicos frecuentes de despensa/compra que también se añaden con un toque.
/// Son productos "de siempre" que no suele apetecer teclear uno a uno.
const List<QuickItem> kQuickBasics = [
  QuickItem('Leche'),
  QuickItem('Huevos'),
  QuickItem('Pan'),
  QuickItem('Arroz'),
  QuickItem('Pasta'),
  QuickItem('Harina'),
  QuickItem('Agua'),
  QuickItem('Café'),
  QuickItem('Mantequilla'),
  QuickItem('Tomate frito'),
  QuickItem('Atún'),
  QuickItem('Garbanzos'),
  QuickItem('Lentejas'),
  QuickItem('Papel higiénico'),
];
