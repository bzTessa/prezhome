/// Categorías por defecto de la lista de la compra y helper para asignar la
/// categoría de un producto por su nombre.
///
/// Lógica PURA (sin Flutter ni red) para poder testearla con datos fijos y para
/// reutilizarla tanto en el seed (al preparar las categorías por defecto del
/// hogar) como en la UI (sugerir la categoría de un artículo nuevo).
///
/// Las categorías son las que una persona reconoce de la compra en español
/// (secciones del súper): Frutas y Verduras, Carnes y Pescados, Lácteos,
/// Panadería, Congelados, Conservas, Pastas y Cereales, Bebidas, Limpieza y
/// Hogar, Condimentos y, por último, "Sin categorizar" como respaldo.
library;

/// Categoría por defecto: nombre visible + palabras clave (ya normalizadas,
/// minúsculas y sin acentos) con las que un producto cae en ella.
class DefaultShoppingCategory {
  final String name;
  final List<String> keywords;

  const DefaultShoppingCategory(this.name, this.keywords);
}

/// Nombre de la categoría de respaldo cuando ningún producto hace match claro.
/// También es el nombre de la categoría "comodín" que la UI muestra para los
/// artículos con category_id NULL.
const String kUncategorizedName = 'Sin categorizar';

/// Lista ORDENADA de categorías por defecto (en español). El orden define la
/// `position` al sembrarlas y el orden en que se evalúa el match (de específico
/// a genérico). "Sin categorizar" va SIEMPRE la última.
const List<DefaultShoppingCategory> kDefaultShoppingCategories = [
  DefaultShoppingCategory('Frutas y Verduras', [
    'fruta',
    'frutas',
    'verdura',
    'verduras',
    'manzana',
    'platano',
    'naranja',
    'pera',
    'fresa',
    'uva',
    'limon',
    'tomate',
    'lechuga',
    'cebolla',
    'patata',
    'zanahoria',
    'pimiento',
    'calabacin',
    'brocoli',
    'espinaca',
    'pepino',
    'champinon',
    'ajo',
    'aguacate',
    'melon',
    'sandia',
    'kiwi',
    'mandarina',
  ]),
  DefaultShoppingCategory('Carnes y Pescados', [
    'pollo',
    'carne',
    'ternera',
    'cerdo',
    'jamon',
    'chorizo',
    'salchicha',
    'pavo',
    'bacon',
    'lomo',
    'costilla',
    'hamburguesa',
    'embutido',
    'solomillo',
    'filete',
    'pescado',
    'merluza',
    'salmon',
    'atun',
    'bacalao',
    'gamba',
    'marisco',
    'sardina',
    'dorada',
    'lubina',
    'calamar',
    'pulpo',
    'mejillon',
    'huevo',
    'huevos',
  ]),
  DefaultShoppingCategory('Lácteos', [
    'leche',
    'yogur',
    'yogures',
    'queso',
    'mantequilla',
    'nata',
    'cuajada',
    'kefir',
    'requeson',
    'mozzarella',
  ]),
  DefaultShoppingCategory('Panadería', [
    'pan',
    'barra',
    'bolleria',
    'croissant',
    'tostada',
    'bizcocho',
    'magdalena',
    'galleta',
    'galletas',
  ]),
  DefaultShoppingCategory('Congelados', [
    'congelado',
    'congelados',
    'helado',
    'helados',
    'pizza congelada',
    'guisante congelado',
    'verdura congelada',
  ]),
  DefaultShoppingCategory('Conservas', [
    'conserva',
    'conservas',
    'lata',
    'latas',
    'bote',
    'botes',
    'enlatado',
    'maiz',
    'olivas',
    'aceituna',
    'aceitunas',
    'tomate frito',
  ]),
  DefaultShoppingCategory('Pastas y Cereales', [
    'pasta',
    'macarron',
    'macarrones',
    'espagueti',
    'espaguetis',
    'arroz',
    'harina',
    'cereal',
    'cereales',
    'avena',
    'lenteja',
    'lentejas',
    'garbanzo',
    'garbanzos',
    'quinoa',
    'cuscus',
  ]),
  DefaultShoppingCategory('Bebidas', [
    'agua',
    'refresco',
    'zumo',
    'cerveza',
    'vino',
    'cafe',
    'infusion',
    'bebida',
    'horchata',
    'batido',
    'coca cola',
  ]),
  DefaultShoppingCategory('Limpieza y Hogar', [
    'detergente',
    'lejia',
    'jabon',
    'fregona',
    'estropajo',
    'bayeta',
    'suavizante',
    'lavavajillas',
    'papel higienico',
    'servilleta',
    'basura',
    'escoba',
    'ambientador',
    'bombilla',
    'pila',
    'pilas',
    'champu',
    'gel',
    'pasta de dientes',
    'cepillo',
    'desodorante',
  ]),
  DefaultShoppingCategory('Condimentos', [
    'sal',
    'azucar',
    'pimienta',
    'pimenton',
    'oregano',
    'comino',
    'curcuma',
    'curry',
    'canela',
    'nuez moscada',
    'clavo',
    'laurel',
    'perejil',
    'albahaca',
    'tomillo',
    'romero',
    'jengibre',
    'especia',
    'especias',
    'condimento',
    'aceite',
    'vinagre',
    'salsa de soja',
    'mostaza',
    'ketchup',
    'mayonesa',
    'miel',
    'vainilla',
    'levadura',
  ]),
  DefaultShoppingCategory(kUncategorizedName, []),
];

/// Normaliza un texto a minúsculas y sin acentos para comparar (misma lógica
/// que CategoryIcons.normalize pero SIN depender de Flutter, para mantener este
/// helper PURO). Cubre los acentos habituales del español.
String normalizeCategoryText(String input) {
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

/// Tokeniza un texto normalizado en palabras (letras/números), descartando
/// signos y espacios. Ej: "arroz, 2 tazas" -> ["arroz","2","tazas"].
List<String> _tokens(String normalized) {
  return normalized
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();
}

/// Comprueba si una [keyword] (ya normalizada; puede tener varias palabras)
/// casa con los [tokens] del nombre. Keywords de 1 palabra: igualdad o prefijo
/// claro (para keywords <= 3 letras exigimos igualdad exacta, p. ej. "sal" no
/// debe casar con "salmon"). Keywords multi-palabra: secuencia dentro de los
/// tokens.
bool _matches(List<String> tokens, String keyword) {
  final parts = keyword.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return false;

  if (parts.length == 1) {
    final kw = parts.first;
    final exactOnly = kw.length <= 3;
    for (final token in tokens) {
      if (token == kw) return true;
      if (!exactOnly && token.startsWith(kw)) return true;
    }
    return false;
  }

  for (var i = 0; i + parts.length <= tokens.length; i++) {
    var all = true;
    for (var j = 0; j < parts.length; j++) {
      final token = tokens[i + j];
      final kw = parts[j];
      final exactOnly = kw.length <= 3;
      final ok = token == kw || (!exactOnly && token.startsWith(kw));
      if (!ok) {
        all = false;
        break;
      }
    }
    if (all) return true;
  }
  return false;
}

/// Devuelve el NOMBRE de la categoría por defecto para [productName], o
/// [kUncategorizedName] si no hay match claro. Evalúa las categorías en el
/// orden de [kDefaultShoppingCategories] (de específico a genérico).
String defaultCategoryFor(String productName) {
  final tokens = _tokens(normalizeCategoryText(productName));
  if (tokens.isEmpty) return kUncategorizedName;
  for (final cat in kDefaultShoppingCategories) {
    for (final keyword in cat.keywords) {
      if (_matches(tokens, keyword)) return cat.name;
    }
  }
  return kUncategorizedName;
}

/// Nombres de las categorías por defecto, en orden, para sembrarlas en el
/// hogar (la `position` es el índice en esta lista).
List<String> defaultCategoryNames() =>
    kDefaultShoppingCategories.map((c) => c.name).toList();

/// Agrupa los productos por las categorías del hogar, en el orden que la
/// persona les dio (el de su súper). Cada producto va a su categoría por id,
/// si no por nombre, y si no por la que le toca según [defaultCategoryFor].
/// Los que no encajan van al final, en [kUncategorizedName]. Solo devuelve
/// grupos con productos.
List<(String, List<T>)> groupByHomeCategories<T>(
  List<T> items,
  List<({String? id, String name})> categories, {
  required String? Function(T) categoryIdOf,
  required String? Function(T) categoryNameOf,
  required String Function(T) nameOf,
}) {
  final byId = {for (final c in categories) c.id: c.name};
  final byName = {
    for (final c in categories) normalizeCategoryText(c.name): c.name,
  };
  String? known(String? name) =>
      name == null ? null : byName[normalizeCategoryText(name)];

  final groups = <String, List<T>>{};
  for (final item in items) {
    final cat =
        byId[categoryIdOf(item)] ??
        known(categoryNameOf(item)) ??
        known(defaultCategoryFor(nameOf(item))) ??
        kUncategorizedName;
    groups.putIfAbsent(cat, () => []).add(item);
  }
  return [
    for (final c in categories)
      if (c.name != kUncategorizedName && groups[c.name] != null)
        (c.name, groups[c.name]!),
    if (groups[kUncategorizedName] != null)
      (kUncategorizedName, groups[kUncategorizedName]!),
  ];
}

/// "Lo habitual": lo que más se compra según los tickets (al menos 2 veces),
/// sin lo que ya está en la lista. Como mucho [limit].
List<String> usualProducts(
  Iterable<({String? name, int times})> history,
  Iterable<String> inList, {
  int limit = 10,
}) {
  final pending = inList.map(normalizeCategoryText).toSet();
  final sorted = history.where((h) => h.times >= 2 && h.name != null).toList()
    ..sort((a, b) => b.times.compareTo(a.times));
  return [
    for (final h in sorted)
      if (!pending.contains(normalizeCategoryText(h.name!))) h.name!,
  ].take(limit).toList();
}
