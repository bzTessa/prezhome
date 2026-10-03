import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Categoría visual de un producto, con su emoji representativo.
///
/// No existe un campo "categoría" en los modelos (ni en [ShoppingListItem] ni
/// en [InventoryItem]), así que la deducimos por palabras clave del nombre.
/// El objetivo es estético y organizativo: dar un toque visual tipo "apps de
/// la compra" y permitir agrupar la lista por secciones legibles.
enum FoodCategory {
  verdura('🥦', 'Verduras', Icons.eco),
  fruta('🍎', 'Frutas', Icons.apple),
  carne('🥩', 'Carne', Icons.kebab_dining),
  pescado('🐟', 'Pescado', Icons.set_meal),
  lacteos('🧀', 'Lácteos', Icons.icecream),
  bebidas('🥤', 'Bebidas', Icons.local_drink),
  panaderia('🥖', 'Panadería/Cereales', Icons.bakery_dining),
  // Especias, condimentos y básicos de despensa (aceite, sal, vinagre...).
  // Se separan para darles un icono propio coherente y porque no suelen
  // gastarse rápido ni interesa que acaben en la lista de la compra.
  especias('🧂', 'Especias y condimentos', Icons.grass),
  limpieza('🧽', 'Limpieza', Icons.cleaning_services),
  hogar('🏠', 'Hogar', Icons.home),
  // Neutro: carrito de la compra. Es el fallback cuando no hay match claro,
  // para no forzar una categoría dudosa.
  otros('🛒', 'Otros', Icons.shopping_cart);

  const FoodCategory(this.emoji, this.label, this.icon);

  /// Emoji representativo de la categoría.
  final String emoji;

  /// Nombre legible de la sección (para encabezados en la lista de la compra).
  final String label;

  /// Icono vectorial Material representativo de la categoría. Es el respaldo
  /// "cozy" cuando no hay foto real del alimento: una ilustración coherente y
  /// cuidada en lugar del emoji genérico del sistema.
  final IconData icon;
}

/// Estilo visual "cozy" de una categoría: su icono vectorial Material y el par
/// de colores (fondo suave + color del icono) con el que se dibuja. Se usa como
/// ilustración de respaldo cuando no hay foto real del alimento.
///
/// Los colores salen de [AppColors] (paleta Cozy) para mantener coherencia con
/// el resto de la app (chips, estados de caducidad, etc.).
class CategoryStyle {
  const CategoryStyle({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  /// Icono vectorial Material de la categoría.
  final IconData icon;

  /// Color de fondo suave (relleno del círculo/tarjeta).
  final Color background;

  /// Color del icono (y texto si procede), con contraste cálido sobre
  /// [background].
  final Color foreground;
}

/// Helper reutilizable para asignar un emoji/icono de categoría a un producto
/// a partir de su nombre. Se usa en la lista de la compra y en el inventario
/// para que cada item muestre un pequeño distintivo visual consistente.
///
/// Estrategia de categorización (evita falsos positivos por subcadena):
///   1. Normalizamos el nombre (minúsculas, sin acentos) y lo tokenizamos en
///      palabras.
///   2. Comparamos cada palabra clave contra las PALABRAS del nombre, no contra
///      la cadena entera. Una keyword acierta si alguna palabra del nombre es
///      igual a la keyword o empieza por ella (prefijo claro, p.ej. "tomate"
///      casa con "tomates"/"tomatitos"). Así "chocolate" ya NO cae en verdura
///      por contener "col", ni "ajonjolí" en verdura por contener "ajo".
///   3. Evaluamos las categorías de específico a genérico (p.ej. las keywords
///      "leche de avena"/"cafe" de bebidas antes que "leche" de lácteos).
///   4. Si no hay match claro devolvemos [FoodCategory.otros] (emoji neutro de
///      carrito) en lugar de inventar una categoría.
class CategoryIcons {
  CategoryIcons._();

  /// Normaliza un texto a minúsculas y sin acentos para comparar de forma
  /// razonable (no cubre todos los casos, pero sí los habituales en español).
  /// Público para que otras pantallas (p.ej. la exclusión de staples en la
  /// lista de la compra) reutilicen exactamente la misma normalización.
  static String normalize(String input) {
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

  /// Tokeniza el nombre normalizado en palabras (letras/números), descartando
  /// signos de puntuación y espacios. Ej: "arroz, 2 tazas" -> ["arroz","2","tazas"].
  static List<String> _tokens(String normalized) {
    return normalized
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Comprueba si una keyword (que puede tener varias palabras, p.ej.
  /// "leche de avena") casa con el nombre. Reglas:
  ///   - Keyword de una sola palabra: acierta si alguna palabra del nombre es
  ///     igual o empieza por la keyword (prefijo claro). Para keywords muy
  ///     cortas (<= 3 letras, p.ej. "col", "ajo", "te") exigimos igualdad
  ///     exacta para no arrastrar prefijos ambiguos ("col" NO casa "coliflor"
  ///     salvo que "coliflor" sea su propia keyword).
  ///   - Keyword de varias palabras: la buscamos como secuencia de palabras
  ///     dentro de los tokens del nombre (comparando por igualdad/prefijo).
  static bool _matches(List<String> tokens, String keyword) {
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

    // Keyword multi-palabra: buscar la secuencia dentro de los tokens.
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

  /// Palabras clave por categoría. El orden importa: evaluamos las categorías
  /// más específicas antes que las genéricas (p.ej. "leche de avena"/"cafe" de
  /// bebidas antes que "leche" de lácteos; "coliflor" propio para que no lo
  /// capture "col").
  static const Map<FoodCategory, List<String>> _keywords = {
    // Especias y condimentos primero: así "aceite de oliva", "sal",
    // "pimienta"... se categorizan como especias y no caen en otras.
    FoodCategory.especias: [
      'sal',
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
      'cayena',
      'guindilla',
      'especia',
      'especias',
      'condimento',
      'aceite',
      'vinagre',
      'azucar',
      'levadura',
      'bicarbonato',
      'colorante',
      'caldo',
      'pastilla de caldo',
      'salsa de soja',
      'mostaza',
      'ketchup',
      'mayonesa',
      'miel',
      'vainilla',
    ],
    FoodCategory.limpieza: [
      'limpiacristales',
      'limpiahogar',
      'limpia',
      'detergente',
      'lejia',
      'jabon',
      'fregona',
      'estropajo',
      'bayeta',
      'suavizante',
      'friegaplatos',
      'lavavajillas',
      'papel higienico',
      'servilleta',
      'servilletas',
      'basura',
      'escoba',
      'ambientador',
    ],
    FoodCategory.hogar: [
      'bombilla',
      'pila',
      'pilas',
      'bateria',
      'cargador',
      'panal',
      'panales',
      'toallita',
      'toallitas',
      'champu',
      'gel',
      'pasta de dientes',
      'cepillo',
      'desodorante',
      'mascarilla',
    ],
    FoodCategory.bebidas: [
      'agua',
      'refresco',
      'coca cola',
      'zumo',
      'cerveza',
      'vino',
      'cafe',
      'the',
      'te',
      'infusion',
      'bebida',
      'leche de avena',
      'leche de soja',
      'leche de almendra',
      'horchata',
      'batido',
    ],
    FoodCategory.lacteos: [
      'leche',
      'yogur',
      'yogures',
      'queso',
      'quesos',
      'mantequilla',
      'nata',
      'cuajada',
      'kefir',
      'requeson',
      'mozzarella',
      'cuajo',
    ],
    FoodCategory.pescado: [
      'pescado',
      'merluza',
      'salmon',
      'atun',
      'bacalao',
      'gamba',
      'gambas',
      'marisco',
      'sardina',
      'sardinas',
      'dorada',
      'lubina',
      'calamar',
      'calamares',
      'pulpo',
      'mejillon',
      'mejillones',
      'trucha',
      'langostino',
      'langostinos',
      'boqueron',
      'boquerones',
    ],
    FoodCategory.carne: [
      'pollo',
      'carne',
      'ternera',
      'cerdo',
      'jamon',
      'chorizo',
      'salchicha',
      'salchichas',
      'pavo',
      'bacon',
      'lomo',
      'costilla',
      'costillas',
      'hamburguesa',
      'hamburguesas',
      'embutido',
      'huevo',
      'huevos',
      'solomillo',
      'filete',
      'filetes',
    ],
    FoodCategory.verdura: [
      'verdura',
      'verduras',
      'lechuga',
      'tomate',
      'cebolla',
      'ajo',
      'patata',
      'patatas',
      'zanahoria',
      'pimiento',
      'calabacin',
      'calabaza',
      'brocoli',
      'espinaca',
      'espinacas',
      'pepino',
      'champinon',
      'champinones',
      'seta',
      'setas',
      'judia',
      'judias',
      'guisante',
      'guisantes',
      'berenjena',
      'puerro',
      'apio',
      'coliflor',
      'col',
      'repollo',
      'acelga',
      'acelgas',
      'escarola',
    ],
    FoodCategory.fruta: [
      'fruta',
      'frutas',
      'manzana',
      'platano',
      'banana',
      'naranja',
      'pera',
      'fresa',
      'fresas',
      'uva',
      'uvas',
      'melon',
      'sandia',
      'kiwi',
      'limon',
      'mandarina',
      'melocoton',
      'pina',
      'cereza',
      'cerezas',
      'aguacate',
      'ciruela',
      'ciruelas',
      'frambuesa',
      'arandano',
      'arandanos',
    ],
    FoodCategory.panaderia: [
      'pan',
      'harina',
      'arroz',
      'pasta',
      'macarron',
      'macarrones',
      'espagueti',
      'espaguetis',
      'cereal',
      'cereales',
      'avena',
      'galleta',
      'galletas',
      'bolleria',
      'croissant',
      'tostada',
      'tostadas',
      'bizcocho',
      'magdalena',
      'magdalenas',
      'lenteja',
      'lentejas',
      'garbanzo',
      'garbanzos',
    ],
  };

  /// Devuelve la categoría inferida del nombre del producto.
  ///
  /// Si no hay match claro de alimentos y [itemType] es 'hogar', usamos
  /// [FoodCategory.hogar] como respaldo razonable; en cualquier otro caso
  /// devolvemos [FoodCategory.otros] (emoji neutro).
  static FoodCategory categoryFor(String name, {String? itemType}) {
    final tokens = _tokens(normalize(name));
    if (tokens.isNotEmpty) {
      for (final entry in _keywords.entries) {
        for (final keyword in entry.value) {
          if (_matches(tokens, keyword)) return entry.key;
        }
      }
    }
    if (itemType == 'hogar') return FoodCategory.hogar;
    return FoodCategory.otros;
  }

  /// Emoji directo para un nombre de producto.
  static String emojiFor(String name, {String? itemType}) =>
      categoryFor(name, itemType: itemType).emoji;

  /// Par de colores cozy (fondo suave + color del icono) por categoría, tomados
  /// de [AppColors]. Pensado como ilustración cálida de respaldo, no como
  /// semáforo de estado (eso lo cubren los colores de caducidad aparte).
  static const Map<FoodCategory, (Color, Color)> _palette = {
    FoodCategory.verdura: (AppColors.sageBg, AppColors.sage),
    FoodCategory.fruta: (AppColors.peachBg, AppColors.peach),
    FoodCategory.carne: (AppColors.terracottaBg, AppColors.terracotta),
    FoodCategory.pescado: (AppColors.frostBg, AppColors.frost),
    FoodCategory.lacteos: (AppColors.cream, AppColors.woodDark),
    FoodCategory.bebidas: (AppColors.frostBg, AppColors.frost),
    FoodCategory.panaderia: (AppColors.peachBg, AppColors.peach),
    FoodCategory.especias: (AppColors.terracottaBg, AppColors.terracotta),
    FoodCategory.limpieza: (AppColors.sageBg, AppColors.sage),
    FoodCategory.hogar: (AppColors.cream, AppColors.woodDark),
    FoodCategory.otros: (AppColors.cream, AppColors.woodDark),
  };

  /// Devuelve el estilo visual cozy (icono + fondo + color del icono) para la
  /// categoría inferida del nombre. Es la fuente única de la ilustración de
  /// respaldo que sustituye al emoji genérico del sistema.
  static CategoryStyle styleFor(String name, {String? itemType}) {
    final category = categoryFor(name, itemType: itemType);
    final (background, foreground) =
        _palette[category] ?? _palette[FoodCategory.otros]!;
    return CategoryStyle(
      icon: category.icon,
      background: background,
      foreground: foreground,
    );
  }

  /// Icono vectorial Material representativo del producto (ilustración cozy de
  /// respaldo cuando no hay foto real).
  static IconData iconFor(String name, {String? itemType}) =>
      categoryFor(name, itemType: itemType).icon;

  /// Color de fondo suave (cozy) para el distintivo del producto.
  static Color backgroundColorFor(String name, {String? itemType}) =>
      styleFor(name, itemType: itemType).background;

  /// Color del icono (contraste cálido sobre el fondo) para el producto.
  static Color foregroundColorFor(String name, {String? itemType}) =>
      styleFor(name, itemType: itemType).foreground;

  /// Pequeño distintivo visual (emoji dentro de un círculo cozy) listo para
  /// usar como leading de un ListTile. Consistente entre compra e inventario.
  static Widget badge(String name, {String? itemType, double size = 40}) {
    final emoji = emojiFor(name, itemType: itemType);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
