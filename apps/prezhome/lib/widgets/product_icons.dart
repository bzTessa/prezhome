import 'food_category_icon.dart';

/// Icono propio de cada producto genérico (cebolla, patata, pollo...): en la
/// compra se ve siempre el mismo dibujo, en vez de una foto de Open Food Facts
/// que a veces es otro producto ("tortilla de cebolla" por cebolla).
///
/// Dibujos de Fluent Emoji 3D (Microsoft, licencia MIT) en
/// `assets/icons/products/`.
class ProductIcons {
  ProductIcons._();

  /// Palabra clave (minúsculas, sin acentos, en singular) -> icono. Las de
  /// varias palabras se miran antes; entre iguales, gana la que va primero
  /// ("zumo de naranja" es zumo; "tarta de manzana", tarta).
  static const Map<String, String> _icons = {
    // Preparados y envasados (antes que sus ingredientes).
    'tomate frito': 'canned_food',
    'tomate triturado': 'canned_food',
    'patata frita': 'pretzel',
    'aceite de oliva': 'olive',
    'judia verde': 'pea_pod',
    'barra de pan': 'baguette_bread',
    'pan de molde': 'bread',
    'pan rallado': 'bread',
    'tortilla de trigo': 'flatbread',
    'fruto seco': 'peanuts',
    'bolsa de basura': 'wastebasket',
    'papel higienico': 'roll_of_paper',
    'papel de cocina': 'roll_of_paper',
    'papel de aluminio': 'roll_of_paper',
    'pasta de dientes': 'toothbrush',
    'cepillo de dientes': 'toothbrush',
    'comida de perro': 'paw_prints',
    'comida de gato': 'paw_prints',
    'arena de gato': 'paw_prints',
    'crema de cacao': 'jar',
    'zumo': 'beverage_box',
    'batido': 'beverage_box',
    'helado': 'ice_cream',
    'tarta': 'shortcake',
    'pastel': 'shortcake',
    'bizcocho': 'shortcake',
    'galleta': 'cookie',
    'magdalena': 'cupcake',
    'muffin': 'cupcake',
    'donut': 'doughnut',
    'croissant': 'croissant',
    'cruasan': 'croissant',
    'bolleria': 'croissant',
    'tortita': 'pancakes',
    'crepe': 'pancakes',
    'gofre': 'waffle',
    'yogur': 'bowl_with_spoon',
    'cereal': 'bowl_with_spoon',
    'muesli': 'bowl_with_spoon',
    'copo': 'bowl_with_spoon',
    'flan': 'custard',
    'natilla': 'custard',
    'mermelada': 'jar',
    'mayonesa': 'jar',
    'mostaza': 'jar',
    'ketchup': 'jar',
    'salsa': 'jar',
    'hummus': 'jar',
    'tarro': 'jar',
    'conserva': 'canned_food',
    'lata': 'canned_food',
    'pizza': 'pizza',
    'sandwich': 'sandwich',
    'ensalada': 'green_salad',
    'hamburguesa': 'hamburger',
    'salchicha': 'hot_dog',
    'frankfurt': 'hot_dog',
    'croqueta': 'falafel',
    'empanadilla': 'dumpling',
    'gyoza': 'dumpling',
    'empanada': 'pie',
    'quiche': 'pie',
    'paella': 'shallow_pan_of_food',
    'palomita': 'popcorn',
    'snack': 'pretzel',
    'chocolate': 'chocolate_bar',
    'cacao': 'chocolate_bar',
    'caramelo': 'candy',
    'gominola': 'candy',
    'chuche': 'candy',
    'miel': 'honey_pot',
    // Lácteos y huevos.
    'leche': 'glass_of_milk',
    'nata': 'glass_of_milk',
    'kefir': 'glass_of_milk',
    'queso': 'cheese_wedge',
    'mozzarella': 'cheese_wedge',
    'mantequilla': 'butter',
    'margarina': 'butter',
    'huevo': 'egg',
    // Panadería, pasta y legumbres.
    'pan': 'bread',
    'baguette': 'baguette_bread',
    'wrap': 'flatbread',
    'arroz': 'cooked_rice',
    'pasta': 'spaghetti',
    'espagueti': 'spaghetti',
    'macarron': 'spaghetti',
    'fideo': 'spaghetti',
    'tallarin': 'spaghetti',
    'lasana': 'spaghetti',
    'garbanzo': 'beans',
    'lenteja': 'beans',
    'alubia': 'beans',
    'judia': 'beans',
    'frijol': 'beans',
    'legumbre': 'beans',
    'guisante': 'pea_pod',
    'haba': 'pea_pod',
    // Carne y pescado.
    'pollo': 'poultry_leg',
    'pavo': 'poultry_leg',
    'pechuga': 'poultry_leg',
    'muslo': 'poultry_leg',
    'alita': 'poultry_leg',
    'costilla': 'meat_on_bone',
    'chuleta': 'meat_on_bone',
    'cordero': 'meat_on_bone',
    'carne': 'cut_of_meat',
    'ternera': 'cut_of_meat',
    'cerdo': 'cut_of_meat',
    'filete': 'cut_of_meat',
    'solomillo': 'cut_of_meat',
    'lomo': 'cut_of_meat',
    'entrecot': 'cut_of_meat',
    'bacon': 'bacon',
    'beicon': 'bacon',
    'panceta': 'bacon',
    'jamon': 'bacon',
    'chorizo': 'bacon',
    'salchichon': 'bacon',
    'fuet': 'bacon',
    'embutido': 'bacon',
    'pescado': 'fish',
    'merluza': 'fish',
    'salmon': 'fish',
    'bacalao': 'fish',
    'atun': 'fish',
    'dorada': 'fish',
    'lubina': 'fish',
    'sardina': 'fish',
    'boqueron': 'fish',
    'trucha': 'fish',
    'lenguado': 'fish',
    'rape': 'fish',
    'gamba': 'shrimp',
    'langostino': 'shrimp',
    'bogavante': 'lobster',
    'langosta': 'lobster',
    'cigala': 'lobster',
    'cangrejo': 'crab',
    'calamar': 'squid',
    'pulpo': 'squid',
    'sepia': 'squid',
    'chipiron': 'squid',
    'mejillon': 'oyster',
    'almeja': 'oyster',
    'berberecho': 'oyster',
    'ostra': 'oyster',
    // Verdura.
    'cebolla': 'onion',
    'cebolleta': 'onion',
    'chalota': 'onion',
    'puerro': 'onion',
    'patata': 'potato',
    'boniato': 'roasted_sweet_potato',
    'batata': 'roasted_sweet_potato',
    'ajo': 'garlic',
    'zanahoria': 'carrot',
    'brocoli': 'broccoli',
    'coliflor': 'broccoli',
    'tomate': 'tomato',
    'pepino': 'cucumber',
    'calabacin': 'cucumber',
    'guindilla': 'hot_pepper',
    'cayena': 'hot_pepper',
    'jalapeno': 'hot_pepper',
    'pimiento': 'bell_pepper',
    'maiz': 'ear_of_corn',
    'lechuga': 'leafy_green',
    'espinaca': 'leafy_green',
    'acelga': 'leafy_green',
    'canonigo': 'leafy_green',
    'rucula': 'leafy_green',
    'escarola': 'leafy_green',
    'col': 'leafy_green',
    'repollo': 'leafy_green',
    'kale': 'leafy_green',
    'berenjena': 'eggplant',
    'champinon': 'mushroom',
    'seta': 'mushroom',
    'jengibre': 'ginger_root',
    'aceituna': 'olive',
    'perejil': 'herb',
    'cilantro': 'herb',
    'albahaca': 'herb',
    'hierbabuena': 'herb',
    'menta': 'herb',
    'romero': 'herb',
    'tomillo': 'herb',
    'oregano': 'herb',
    'laurel': 'herb',
    'eneldo': 'herb',
    // Fruta.
    'manzana': 'red_apple',
    'pera': 'pear',
    'platano': 'banana',
    'banana': 'banana',
    'naranja': 'tangerine',
    'mandarina': 'tangerine',
    'clementina': 'tangerine',
    'limon': 'lemon',
    'lima': 'lemon',
    'uva': 'grapes',
    'fresa': 'strawberry',
    'sandia': 'watermelon',
    'melon': 'melon',
    'cereza': 'cherries',
    'melocoton': 'peach',
    'nectarina': 'peach',
    'albaricoque': 'peach',
    'pina': 'pineapple',
    'kiwi': 'kiwi_fruit',
    'mango': 'mango',
    'coco': 'coconut',
    'arandano': 'blueberries',
    'mora': 'blueberries',
    'aguacate': 'avocado',
    'cacahuete': 'peanuts',
    'nuez': 'peanuts',
    'almendra': 'peanuts',
    'avellana': 'peanuts',
    'pistacho': 'peanuts',
    'castana': 'chestnut',
    'sal': 'salt',
    'pimienta': 'salt',
    // Bebidas.
    'agua': 'droplet',
    'cafe': 'hot_beverage',
    'te': 'teacup_without_handle',
    'infusion': 'teacup_without_handle',
    'manzanilla': 'teacup_without_handle',
    'refresco': 'cup_with_straw',
    'cola': 'cup_with_straw',
    'tonica': 'cup_with_straw',
    'gaseosa': 'cup_with_straw',
    'cerveza': 'beer_mug',
    'vino': 'wine_glass',
    'cava': 'bottle_with_popping_cork',
    'champan': 'bottle_with_popping_cork',
    'sidra': 'bottle_with_popping_cork',
    'hielo': 'ice',
    'biberon': 'baby_bottle',
    // Limpieza y hogar.
    'papel': 'roll_of_paper',
    'servilleta': 'roll_of_paper',
    'panuelo': 'roll_of_paper',
    'detergente': 'bubbles',
    'suavizante': 'bubbles',
    'jabon': 'soap',
    'lavavajillas': 'soap',
    'friegaplatos': 'soap',
    'gel': 'lotion_bottle',
    'champu': 'lotion_bottle',
    'lejia': 'lotion_bottle',
    'limpiador': 'lotion_bottle',
    'friegasuelos': 'lotion_bottle',
    'estropajo': 'sponge',
    'bayeta': 'sponge',
    'esponja': 'sponge',
    'escoba': 'broom',
    'fregona': 'broom',
    'cubo': 'bucket',
    'basura': 'wastebasket',
    'bombilla': 'light_bulb',
    'pila': 'battery',
    'bateria': 'battery',
    'vela': 'candle',
    'tirita': 'adhesive_bandage',
    'ibuprofeno': 'pill',
    'paracetamol': 'pill',
    'vitamina': 'pill',
    'cuchilla': 'razor',
    'maquinilla': 'razor',
    'pienso': 'paw_prints',
  };

  /// Palabras que no cambian qué producto es: "2 cebollas moradas" sigue
  /// siendo cebolla genérica; "Cebolla Hacendado" ya es un producto concreto.
  static const Set<String> _neutral = {
    'de', 'del', 'la', 'el', 'los', 'las', 'en', 'con', 'para', 'y', //
    'kg', 'g', 'gr', 'l', 'ml', 'cl', 'ud', 'uds', 'unidad', 'unidades',
    'pack', 'malla', 'bolsa', 'bandeja', 'docena', 'manojo', 'racimo',
    'fresco', 'fresca', 'frescos', 'frescas', 'congelado', 'congelada',
    'congelados', 'congeladas', 'entero', 'entera', 'enteros', 'enteras',
    'semidesnatada', 'desnatada', 'natural', 'naturales', 'ecologico',
    'ecologica', 'ecologicos', 'ecologicas', 'bio', 'grande', 'grandes',
    'pequeno', 'pequena', 'pequenos', 'pequenas', 'rojo', 'roja', 'rojos',
    'rojas', 'verde', 'verdes', 'amarillo', 'amarilla', 'amarillos',
    'amarillas', 'blanco', 'blanca', 'blancos', 'blancas', 'morado',
    'morada', 'morados', 'moradas', 'negro', 'negra', 'negros', 'negras',
    'dulce', 'dulces', 'tierno', 'tierna', 'maduro', 'madura', 'nuevo',
    'nueva', 'nuevas', 'picado', 'picada', 'rallado', 'rallada', 'molido',
    'molida', 'cherry', 'pera', 'cocido', 'cocida', 'cocidos', 'cocidas',
    'integral', 'integrales', 'sin', 'lactosa', 'gluten',
  };

  static bool _same(String token, String word) =>
      token == word ||
      token == '${word}s' ||
      token == '${word}es' ||
      (word.endsWith('z') &&
          token == '${word.substring(0, word.length - 1)}ces');

  static List<String> _tokens(String name) => CategoryIcons.normalize(
    name,
  ).split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

  static final List<MapEntry<String, String>> _ordered = [
    ..._icons.entries.where((e) => e.key.contains(' ')),
    ..._icons.entries.where((e) => !e.key.contains(' ')),
  ];

  /// Dónde aparece la primera palabra clave que casa: (inicio, fin, icono).
  static (int, int, String)? _find(List<String> tokens) {
    for (final e in _ordered) {
      final parts = e.key.split(' ');
      for (var i = 0; i + parts.length <= tokens.length; i++) {
        var all = true;
        for (var j = 0; j < parts.length && all; j++) {
          all = _same(tokens[i + j], parts[j]);
        }
        if (all) return (i, i + parts.length, e.value);
      }
    }
    return null;
  }

  /// Ruta del icono de [name], o null si no hay uno que lo represente.
  static String? assetFor(String name) {
    final hit = _find(_tokens(name));
    return hit == null ? null : 'assets/icons/products/${hit.$3}.png';
  }

  /// Si [name] es un producto genérico ("cebollas", "leche entera"), sin
  /// marca ni nada más: se pinta su icono y no se busca foto de envase.
  static bool isGeneric(String name) {
    final tokens = _tokens(name);
    final hit = _find(tokens);
    if (hit == null) return false;
    for (var i = 0; i < tokens.length; i++) {
      if (i >= hit.$1 && i < hit.$2) continue;
      final t = tokens[i];
      if (!_neutral.contains(t) && int.tryParse(t) == null) return false;
    }
    return true;
  }
}
