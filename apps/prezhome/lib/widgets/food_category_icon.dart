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
  preparados('🍱', 'Platos preparados', Icons.lunch_dining),
  panaderia('🥖', 'Panadería', Icons.bakery_dining),
  cereales('🌾', 'Pasta, arroz y legumbres', Icons.rice_bowl),
  conservas('🥫', 'Conservas', Icons.inventory_2),
  congelados('🧊', 'Congelados', Icons.ac_unit),
  dulces('🍫', 'Dulces y snacks', Icons.cookie),
  bebidas('🥤', 'Bebidas', Icons.local_drink),
  // Especias, condimentos y básicos de despensa (aceite, sal, vinagre...).
  // Se separan para darles un icono propio coherente y porque no suelen
  // gastarse rápido ni interesa que acaben en la lista de la compra.
  especias('🧂', 'Especias y condimentos', Icons.grass),
  higiene('🧴', 'Higiene', Icons.soap),
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
///   3. Gana la palabra que sale antes en el nombre y, a igual posición, la
///      keyword más larga ("leche de avena" de bebidas antes que "leche").
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

  /// Posición (índice de palabra) donde casa una keyword (que puede tener
  /// varias palabras, p.ej. "leche de avena") dentro del nombre, o null.
  ///   - Una palabra: acierta si alguna palabra del nombre es igual o empieza
  ///     por la keyword. Las keywords cortas (<= 3 letras: "col", "ajo",
  ///     "te") exigen igualdad exacta para no arrastrar prefijos ambiguos.
  ///   - Varias palabras: se busca la secuencia dentro del nombre.
  static int? _matchAt(List<String> tokens, String keyword) {
    final parts = keyword.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    for (var i = 0; i + parts.length <= tokens.length; i++) {
      var all = true;
      for (var j = 0; j < parts.length; j++) {
        final token = tokens[i + j];
        final kw = parts[j];
        final ok = token == kw || (kw.length > 3 && token.startsWith(kw));
        if (!ok) {
          all = false;
          break;
        }
      }
      if (all) return i;
    }
    return null;
  }

  /// Palabras clave por categoría (normalizadas, en castellano y algunas en
  /// catalán, como salen en los tickets). Gana la keyword que aparece ANTES en
  /// el nombre ("tarta de queso" es dulce, "yogur de chocolate" es lácteo);
  /// a igual posición, la de más palabras ("leche de avena" gana a "leche") y
  /// luego el orden de este mapa.
  static const Map<FoodCategory, List<String>> _keywords = {
    FoodCategory.higiene: [
      'champu',
      'acondicionador',
      'gel',
      'pasta de dientes',
      'dentifrico',
      'cepillo de dientes',
      'enjuague',
      'colutorio',
      'hilo dental',
      'desodorante',
      'mascarilla',
      'toallita',
      'toallitas',
      'panal',
      'panales',
      'compresa',
      'compresas',
      'tampon',
      'tampones',
      'salvaslip',
      'maquinilla',
      'cuchilla',
      'cuchillas',
      'espuma de afeitar',
      'colonia',
      'perfume',
      'crema hidratante',
      'crema corporal',
      'crema facial',
      'crema de manos',
      'protector solar',
      'locion',
      'bastoncillos',
      'bastoncillo',
      'algodon',
      'algodones',
      'desmaquillante',
      'disco desmaquillante',
      'panuelos',
      'jabon de manos',
      'tinte',
      'laca',
      'gomina',
      'tirita',
      'tiritas',
      'compeed',
      'ibuprofeno',
      'paracetamol',
      'vitamina',
      'vitaminas',
    ],
    FoodCategory.limpieza: [
      'limpiacristales',
      'limpiahogar',
      'limpiador',
      'limpia',
      'multiusos',
      'detergente',
      'detergent',
      'lejia',
      'lleixiu',
      'jabon',
      'sabo',
      'fregona',
      'estropajo',
      'bayeta',
      'bayetas',
      'esponja',
      'suavizante',
      'friegaplatos',
      'lavavajillas',
      'rentaplats',
      'papel higienico',
      'paper higienic',
      'papel de cocina',
      'papel',
      'rollo',
      'rollos',
      'servilleta',
      'servilletas',
      'basura',
      'bolsa de basura',
      'bolsas de basura',
      'escombraries',
      'escoba',
      'recogedor',
      'ambientador',
      'friegasuelos',
      'quitamanchas',
      'quitagrasas',
      'antical',
      'desatascador',
      'insecticida',
      'guantes',
      'guants',
      'fairy',
      'mistol',
      'sanytol',
      'cubo',
    ],
    FoodCategory.hogar: [
      'bombilla',
      'pila',
      'pilas',
      'bateria',
      'cargador',
      'bolsa',
      'bolsas',
      'bossa',
      'film',
      'aluminio',
      'papel de horno',
      'papel de aluminio',
      'vela',
      'velas',
      'mechero',
      'cerillas',
      'tupper',
      'pienso',
      'arena de gato',
      'comida de gato',
      'comida de perro',
    ],
    FoodCategory.bebidas: [
      'agua',
      'aigua',
      'refresco',
      'refresc',
      'coca cola',
      'cola',
      'tonica',
      'gaseosa',
      'zumo',
      'suc',
      'cerveza',
      'cervesa',
      'vino',
      'vi',
      'cava',
      'sidra',
      'cafe',
      'the',
      'te',
      'infusion',
      'manzanilla',
      'bebida',
      'beguda',
      'leche de avena',
      'leche de soja',
      'leche de almendra',
      'leche de coco',
      'llet de civada',
      'horchata',
      'orxata',
      'batido',
      'kombucha',
      'isotonica',
      'ron',
      'ginebra',
      'whisky',
      'vodka',
      'licor',
    ],
    FoodCategory.conservas: [
      'conserva',
      'conservas',
      'lata',
      'latas',
      'enlatado',
      'tomate frito',
      'tomate triturado',
      'tomaquet fregit',
      'maiz',
      'olivas',
      'oliva',
      'aceituna',
      'aceitunas',
      'encurtido',
      'pepinillos',
      'pimientos asados',
      'esparragos en conserva',
    ],
    FoodCategory.preparados: [
      'tortilla',
      'truita patata',
      'truita de patata',
      'pizza',
      'lasana',
      'lasanya',
      'croqueta',
      'croquetas',
      'empanada',
      'empanadilla',
      'empanadillas',
      'gazpacho',
      'salmorejo',
      'hummus',
      'humus',
      'guacamole',
      'sandwich',
      'bocadillo',
      'sushi',
      'canelones',
      'canelons',
      'precocinado',
      'precocinados',
      'plato preparado',
      'platos preparados',
      'nuggets',
      'san jacobo',
      'paella',
      'fideua',
      'wrap',
      'burrito',
      'quiche',
      'ensaladilla',
      'ensalada rusa',
      'ensalada russa',
      'pure',
      'sopa',
      'crema de verduras',
      'albondigas',
      'pollo asado',
      'pollastre rostit',
      'gyoza',
      'gyozas',
    ],
    FoodCategory.congelados: [
      'congelado',
      'congelados',
      'congelada',
      'congeladas',
      'congelat',
      'helado',
      'helados',
      'gelat',
      'gelats',
      'polo',
      'polos',
      'hielo',
      'cubitos',
    ],
    FoodCategory.dulces: [
      'chocolate',
      'chocolatina',
      'xocolata',
      'cacao',
      'crema de cacao',
      'nocilla',
      'nutella',
      'coulant',
      'tarta',
      'pastel',
      'pastis',
      'flan',
      'natilla',
      'natillas',
      'mousse',
      'postre',
      'postres',
      'brownie',
      'donut',
      'donuts',
      'bombon',
      'bombones',
      'caramelo',
      'caramelos',
      'gominola',
      'gominolas',
      'chuche',
      'chuches',
      'regaliz',
      'turron',
      'mermelada',
      'confitura',
      'gofre',
      'churros',
      'cookies',
      'patatas fritas',
      'patates fregides',
      'chips',
      'nachos',
      'frutos secos',
      'fruits secs',
      'almendra',
      'almendras',
      'nuez',
      'nueces',
      'avellana',
      'avellanas',
      'cacahuete',
      'cacahuetes',
      'pistacho',
      'pistachos',
      'anacardo',
      'anacardos',
      'palomitas',
      'pipas',
      'aperitivo',
      'snack',
      'snacks',
      'barrita',
      'barritas',
    ],
    FoodCategory.especias: [
      'sal',
      'pimienta',
      'pebre',
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
      'julivert',
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
      'oli',
      'vinagre',
      'azucar',
      'sucre',
      'levadura',
      'bicarbonato',
      'colorante',
      'caldo',
      'brou',
      'pastilla de caldo',
      'salsa',
      'salsa de soja',
      'pesto',
      'alioli',
      'all i oli',
      'mostaza',
      'ketchup',
      'mayonesa',
      'maionesa',
      'miel',
      'mel',
      'vainilla',
    ],
    FoodCategory.lacteos: [
      'leche',
      'llet',
      'yogur',
      'yogures',
      'iogurt',
      'skyr',
      'queso',
      'quesos',
      'formatge',
      'mantequilla',
      'mantega',
      'margarina',
      'nata',
      'cuajada',
      'kefir',
      'requeson',
      'mozzarella',
      'burrata',
      'ricotta',
      'cuajo',
    ],
    FoodCategory.pescado: [
      'pescado',
      'peix',
      'merluza',
      'lluc',
      'salmon',
      'salmo',
      'atun',
      'tonyina',
      'bacalao',
      'bacalla',
      'gamba',
      'gambas',
      'gambes',
      'marisco',
      'sardina',
      'sardinas',
      'dorada',
      'lubina',
      'llobarro',
      'calamar',
      'calamares',
      'sepia',
      'pulpo',
      'pop',
      'mejillon',
      'mejillones',
      'musclos',
      'almeja',
      'almejas',
      'berberechos',
      'trucha',
      'truita',
      'langostino',
      'langostinos',
      'boqueron',
      'boquerones',
      'anchoa',
      'anchoas',
      'rape',
      'lenguado',
      'surimi',
    ],
    FoodCategory.carne: [
      'pollo',
      'pollastre',
      'pechuga',
      'muslo',
      'muslos',
      'contramuslo',
      'alitas',
      'carne',
      'carn',
      'ternera',
      'vedella',
      'cerdo',
      'porc',
      'cordero',
      'conejo',
      'jamon',
      'pernil',
      'chorizo',
      'xorico',
      'salchicha',
      'salchichas',
      'frankfurt',
      'butifarra',
      'botifarra',
      'fuet',
      'salami',
      'salchichon',
      'longaniza',
      'morcilla',
      'sobrasada',
      'mortadela',
      'chistorra',
      'pavo',
      'gall dindi',
      'bacon',
      'beicon',
      'panceta',
      'lomo',
      'llom',
      'costilla',
      'costillas',
      'chuleta',
      'chuletas',
      'hamburguesa',
      'hamburguesas',
      'embutido',
      'huevo',
      'huevos',
      'ou',
      'ous',
      'solomillo',
      'filete',
      'filetes',
      'entrecot',
    ],
    FoodCategory.verdura: [
      'verdura',
      'verduras',
      'lechuga',
      'enciam',
      'ensalada',
      'rucula',
      'canonigos',
      'brotes',
      'tomate',
      'tomaquet',
      'cebolla',
      'ceba',
      'cebolleta',
      'ajo',
      'all',
      'patata',
      'patatas',
      'boniato',
      'zanahoria',
      'pastanaga',
      'pimiento',
      'pebrot',
      'calabacin',
      'carbasso',
      'calabaza',
      'carbassa',
      'brocoli',
      'espinaca',
      'espinacas',
      'espinacs',
      'pepino',
      'cogombre',
      'champinon',
      'champinones',
      'xampinyons',
      'seta',
      'setas',
      'bolets',
      'judia',
      'judias',
      'mongeta',
      'guisante',
      'guisantes',
      'berenjena',
      'alberginia',
      'puerro',
      'porro',
      'apio',
      'coliflor',
      'col',
      'repollo',
      'acelga',
      'acelgas',
      'escarola',
      'esparrago',
      'esparragos',
      'alcachofa',
      'carxofa',
      'remolacha',
      'rabano',
      'nabo',
      'cogollo',
      'cogollos',
    ],
    FoodCategory.fruta: [
      'fruta',
      'frutas',
      'fruita',
      'manzana',
      'poma',
      'platano',
      'platan',
      'banana',
      'naranja',
      'taronja',
      'pera',
      'fresa',
      'fresas',
      'maduixa',
      'maduixes',
      'uva',
      'uvas',
      'raim',
      'melon',
      'sandia',
      'kiwi',
      'limon',
      'llimona',
      'lima',
      'mandarina',
      'clementina',
      'melocoton',
      'presec',
      'nectarina',
      'albaricoque',
      'pina',
      'pinya',
      'mango',
      'papaya',
      'coco',
      'granada',
      'higo',
      'higos',
      'cereza',
      'cerezas',
      'aguacate',
      'alvocat',
      'ciruela',
      'ciruelas',
      'frambuesa',
      'arandano',
      'arandanos',
      'datiles',
      'pasas',
    ],
    FoodCategory.panaderia: [
      'pan',
      'pa',
      'barra',
      'baguette',
      'chapata',
      'pan de molde',
      'pan rallado',
      'tortilla de trigo',
      'tortillas de trigo',
      'bolleria',
      'croissant',
      'cruasan',
      'tostada',
      'tostadas',
      'biscote',
      'biscotes',
      'bizcocho',
      'magdalena',
      'magdalenas',
      'muffin',
      'galleta',
      'galletas',
      'galetes',
      'tortitas',
    ],
    FoodCategory.cereales: [
      'harina',
      'farina',
      'arroz',
      'arros',
      'pasta',
      'macarron',
      'macarrones',
      'espagueti',
      'espaguetis',
      'fideo',
      'fideos',
      'tallarines',
      'raviolis',
      'tortellini',
      'noodles',
      'cereal',
      'cereales',
      'avena',
      'civada',
      'copos',
      'muesli',
      'granola',
      'lenteja',
      'lentejas',
      'llenties',
      'garbanzo',
      'garbanzos',
      'cigrons',
      'alubia',
      'alubias',
      'legumbre',
      'legumbres',
      'quinoa',
      'cuscus',
    ],
  };

  /// Devuelve la categoría inferida del nombre del producto.
  ///
  /// Si no hay match claro y [itemType] es 'hogar', usamos
  /// [FoodCategory.limpieza] como respaldo (icono de limpieza), que para los
  /// productos de hogar queda más coherente que la casa vacía de
  /// [FoodCategory.hogar]; en cualquier otro caso devolvemos
  /// [FoodCategory.otros] (emoji neutro).
  static FoodCategory categoryFor(String name, {String? itemType}) {
    final tokens = _tokens(normalize(name));
    FoodCategory? best;
    var bestPos = 1 << 30, bestWords = 0;
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        final pos = _matchAt(tokens, keyword);
        if (pos == null) continue;
        final words = ' '.allMatches(keyword).length + 1;
        if (pos < bestPos || (pos == bestPos && words > bestWords)) {
          best = entry.key;
          bestPos = pos;
          bestWords = words;
        }
      }
    }
    if (best != null) return best;
    if (itemType == 'hogar') return FoodCategory.limpieza;
    return FoodCategory.otros;
  }

  /// ¿Es algo de casa (limpieza, higiene, hogar) y no comida?
  static bool isHousehold(FoodCategory c) =>
      c == FoodCategory.limpieza ||
      c == FoodCategory.higiene ||
      c == FoodCategory.hogar;

  /// Emoji directo para un nombre de producto.
  static String emojiFor(String name, {String? itemType}) =>
      categoryFor(name, itemType: itemType).emoji;

  /// Par de colores cozy (fondo suave + color del icono) por categoría, tomados
  /// de [AppColors]. Pensado como ilustración cálida de respaldo, no como
  /// semáforo de estado (eso lo cubren los colores de caducidad aparte).
  static final Map<FoodCategory, (Color, Color)> _palette = {
    FoodCategory.verdura: (AppColors.sageBg, AppColors.sage),
    FoodCategory.fruta: (AppColors.peachBg, AppColors.peach),
    FoodCategory.carne: (AppColors.terracottaBg, AppColors.terracotta),
    FoodCategory.pescado: (AppColors.frostBg, AppColors.frost),
    FoodCategory.lacteos: (AppColors.cream, AppColors.woodDark),
    FoodCategory.bebidas: (AppColors.frostBg, AppColors.frost),
    FoodCategory.panaderia: (AppColors.peachBg, AppColors.peach),
    FoodCategory.preparados: (AppColors.peachBg, AppColors.peach),
    FoodCategory.cereales: (AppColors.cream, AppColors.woodDark),
    FoodCategory.conservas: (AppColors.terracottaBg, AppColors.terracotta),
    FoodCategory.congelados: (AppColors.frostBg, AppColors.frost),
    FoodCategory.dulces: (AppColors.peachBg, AppColors.peach),
    FoodCategory.higiene: (AppColors.frostBg, AppColors.frost),
    FoodCategory.especias: (AppColors.terracottaBg, AppColors.terracotta),
    FoodCategory.limpieza: (AppColors.sageBg, AppColors.sage),
    FoodCategory.hogar: (AppColors.cream, AppColors.woodDark),
    FoodCategory.otros: (AppColors.cream, AppColors.woodDark),
  };

  /// Devuelve el estilo visual cozy (icono + fondo + color del icono) para el
  /// enum de categoría directamente. Útil en cabeceras de sección (compra e
  /// inventario) donde ya conocemos la categoría y queremos su tono cozy sin
  /// pasar por el nombre de un producto.
  static CategoryStyle styleForCategory(FoodCategory category) {
    final (background, foreground) =
        _palette[category] ?? _palette[FoodCategory.otros]!;
    return CategoryStyle(
      icon: category.icon,
      background: background,
      foreground: foreground,
    );
  }

  /// Devuelve el estilo visual cozy (icono + fondo + color del icono) para la
  /// categoría inferida del nombre. Es la fuente única de la ilustración de
  /// respaldo que sustituye al emoji genérico del sistema.
  static CategoryStyle styleFor(String name, {String? itemType}) {
    return styleForCategory(categoryFor(name, itemType: itemType));
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

  /// Pequeño distintivo visual (icono de la categoría en un círculo con su
  /// tono) listo para usar como leading de un ListTile. Consistente entre
  /// compra e inventario. Sin emojis: se ven distinto en cada móvil y la guía
  /// de diseño los evita.
  static Widget badge(String name, {String? itemType, double size = 40}) {
    final style = styleFor(name, itemType: itemType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(style.icon, color: style.foreground, size: size * 0.5),
    );
  }
}
