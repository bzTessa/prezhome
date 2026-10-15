/// Categorías por defecto de la lista de la compra y helper para asignar la
/// categoría de un producto por su nombre.
///
/// Lógica pura (sin red) para poder testearla con datos fijos y para
/// reutilizarla tanto en el seed (al preparar las categorías por defecto del
/// hogar) como en la UI (sugerir la categoría de un artículo nuevo).
///
/// Las categorías son las que una persona reconoce de la compra en español
/// (secciones del súper): Frutas y Verduras, Carnes y Pescados, Lácteos,
/// Platos preparados, Panadería, Congelados, Conservas, Pastas y Cereales,
/// Dulces y snacks, Bebidas, Higiene, Limpieza y Hogar, Condimentos y, por último, "Sin categorizar" como respaldo.
library;

import '../widgets/food_category_icon.dart';

/// Nombre de la categoría de respaldo cuando ningún producto hace match claro.
/// También es el nombre de la categoría "comodín" que la UI muestra para los
/// artículos con category_id NULL.
const String kUncategorizedName = 'Sin categorizar';

/// Pasillos por defecto, en el orden habitual del súper. "Sin categorizar"
/// va SIEMPRE el último.
const List<String> kDefaultShoppingCategories = [
  'Frutas y Verduras',
  'Carnes y Pescados',
  'Lácteos',
  'Platos preparados',
  'Panadería',
  'Congelados',
  'Conservas',
  'Pastas y Cereales',
  'Dulces y snacks',
  'Bebidas',
  'Higiene',
  'Limpieza y Hogar',
  'Condimentos',
  kUncategorizedName,
];

/// Pasillos que se añadieron después: los hogares que ya tenían categorías
/// los reciben una vez.
const List<String> kNewShoppingCategories = [
  'Platos preparados',
  'Dulces y snacks',
  'Higiene',
];

/// Pasillo de cada tipo de producto. El tipo lo deduce
/// [CategoryIcons.categoryFor], así compra, despensa y tickets clasifican igual.
const Map<FoodCategory, String> _aisleOf = {
  FoodCategory.verdura: 'Frutas y Verduras',
  FoodCategory.fruta: 'Frutas y Verduras',
  FoodCategory.carne: 'Carnes y Pescados',
  FoodCategory.pescado: 'Carnes y Pescados',
  FoodCategory.lacteos: 'Lácteos',
  FoodCategory.preparados: 'Platos preparados',
  FoodCategory.panaderia: 'Panadería',
  FoodCategory.congelados: 'Congelados',
  FoodCategory.conservas: 'Conservas',
  FoodCategory.cereales: 'Pastas y Cereales',
  FoodCategory.dulces: 'Dulces y snacks',
  FoodCategory.bebidas: 'Bebidas',
  FoodCategory.higiene: 'Higiene',
  FoodCategory.limpieza: 'Limpieza y Hogar',
  FoodCategory.hogar: 'Limpieza y Hogar',
  FoodCategory.especias: 'Condimentos',
};

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

/// Devuelve el NOMBRE de la categoría por defecto para [productName], o
/// [kUncategorizedName] si no hay match claro. Lo de casa sin match
/// ([itemType] 'hogar') va a "Limpieza y Hogar".
String defaultCategoryFor(String productName, {String? itemType}) =>
    _aisleOf[CategoryIcons.categoryFor(productName, itemType: itemType)] ??
    kUncategorizedName;

/// Nombres de las categorías por defecto, en orden, para sembrarlas en el
/// hogar (la `position` es el índice en esta lista).
List<String> defaultCategoryNames() => kDefaultShoppingCategories;

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
