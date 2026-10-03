import '../widgets/food_category_icon.dart';

/// Precio APROXIMADO de alimentos, por si no tenemos el precio real de los
/// tickets todavía. Son valores ORIENTATIVOS de supermercado español (€/kg
/// para sólidos, €/l para líquidos, €/unidad para contables), pensados para
/// dar un coste "más o menos" de una receta cuando aún no se ha escaneado un
/// ticket con ese producto. Lógica PURA (sin red) y testeable.
///
/// Filosofía (como el resto de PrezHome): no busca exactitud, sino un número
/// razonable para que la receta nunca se quede sin coste. El precio REAL de
/// los tickets de la usuaria siempre tiene prioridad sobre esta estimación.
class ApproxPrice {
  ApproxPrice._();

  /// Precio aproximado por KILO de alimentos concretos (€/kg) o, para los que
  /// se cuentan por unidad, se tratan aparte en [_byUnit]. Claves normalizadas
  /// con CategoryIcons.normalize (minúsculas, sin acentos).
  static const Map<String, double> _perKg = {
    // Carnes y pescados
    'pollo': 6.0,
    'pechuga': 7.5,
    'pavo': 8.0,
    'ternera': 12.0,
    'cerdo': 7.0,
    'carne': 9.0,
    'jamon': 14.0,
    'bacon': 9.0,
    'salmon': 14.0,
    'merluza': 10.0,
    'atun': 11.0,
    'gambas': 12.0,
    // Verduras y frutas (frescas)
    'tomate': 2.2,
    'cebolla': 1.3,
    'ajo': 6.0,
    'patata': 1.1,
    'zanahoria': 1.2,
    'pimiento': 2.5,
    'calabacin': 1.8,
    'brocoli': 2.5,
    'espinaca': 3.0,
    'lechuga': 2.0,
    'champinon': 3.5,
    'manzana': 2.0,
    'platano': 1.8,
    'naranja': 1.5,
    'fresa': 4.0,
    'aguacate': 6.0,
    // Secos / legumbres / cereales
    'arroz': 1.3,
    'pasta': 1.4,
    'harina': 0.9,
    'lenteja': 1.8,
    'lentejas': 1.8,
    'garbanzo': 1.6,
    'garbanzos': 1.6,
    'avena': 2.2,
    'azucar': 1.1,
    // Lácteos
    'queso': 10.0,
    'mantequilla': 9.0,
    'yogur': 2.5,
  };

  /// Precio aproximado por LITRO (€/l) de líquidos.
  static const Map<String, double> _perL = {
    'leche': 1.0,
    'aceite': 6.0, // aceite de oliva
    'nata': 3.0,
    'vino': 4.0,
    'zumo': 1.8,
    'caldo': 1.5,
    'vinagre': 2.0,
  };

  /// Precio aproximado por UNIDAD (€/ud) de contables.
  static const Map<String, double> _perUnit = {
    'huevo': 0.25,
    'huevos': 0.25,
    'limon': 0.3,
    'pan': 0.9,
    'lata': 1.2,
    'bote': 1.3,
    'yogur': 0.5,
  };

  /// Precio por KILO por CATEGORÍA, para cuando no hay match de alimento.
  static const Map<FoodCategory, double> _perKgByCategory = {
    FoodCategory.verdura: 2.0,
    FoodCategory.fruta: 2.2,
    FoodCategory.carne: 9.0,
    FoodCategory.pescado: 12.0,
    FoodCategory.lacteos: 4.0,
    FoodCategory.panaderia: 2.0,
    FoodCategory.bebidas: 1.5,
    FoodCategory.especias: 15.0, // se usan en poca cantidad
    FoodCategory.otros: 4.0,
  };

  static List<String> _tokens(String name) => CategoryIcons.normalize(
    name,
  ).split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

  static double? _match(Map<String, double> table, List<String> tokens) {
    for (final entry in table.entries) {
      final kw = entry.key;
      final hit = tokens.any(
        (t) => t == kw || (kw.length >= 4 && t.startsWith(kw)),
      );
      if (hit) return entry.value;
    }
    return null;
  }

  /// Coste aproximado de una cantidad+unidad de un alimento (en €), o null si
  /// no se puede estimar. Convierte g/kg/ml/l a la base del precio.
  static double? estimate(String name, double? quantity, String? unit) {
    final tokens = _tokens(name);
    if (tokens.isEmpty) return null;
    final u = (unit ?? '').trim().toLowerCase();
    final qty = quantity ?? 1;

    // Unidades contables: precio por unidad.
    const unitUnits = {
      'unidad',
      'unidades',
      'ud',
      'huevo',
      'huevos',
      'lata',
      'latas',
      'bote',
      'botes',
      'loncha',
      'lonchas',
      'diente',
      'dientes',
    };
    if (unitUnits.contains(u)) {
      final perUnit = _match(_perUnit, tokens);
      if (perUnit != null) return perUnit * qty;
      // Si no hay precio por unidad, asumimos ~0.2 kg por pieza para estimar.
      final perKg = _match(_perKg, tokens) ?? _byCategoryKg(name);
      if (perKg != null) return perKg * 0.2 * qty;
      return null;
    }

    // Peso: convertir a kg.
    double? kg;
    if (u == 'g' || u == 'gr' || u == 'gramo' || u == 'gramos') {
      kg = qty / 1000.0;
    } else if (u == 'kg') {
      kg = qty;
    }
    if (kg != null) {
      final perKg = _match(_perKg, tokens) ?? _byCategoryKg(name);
      if (perKg != null) return perKg * kg;
      return null;
    }

    // Volumen: convertir a litros.
    double? l;
    if (u == 'ml' || u == 'mililitro' || u == 'mililitros') {
      l = qty / 1000.0;
    } else if (u == 'l' || u == 'litro' || u == 'litros') {
      l = qty;
    }
    if (l != null) {
      final perL = _match(_perL, tokens);
      if (perL != null) return perL * l;
      return null;
    }

    // Cucharadas/pizcas de especias: coste despreciable pero no nulo.
    if (u.contains('cucharad') || u.contains('pizca')) {
      return 0.05 * qty;
    }

    // Sin unidad clara: asumimos ~0.15 kg por el precio del alimento/categoría.
    final perKg = _match(_perKg, tokens) ?? _byCategoryKg(name);
    if (perKg != null) return perKg * 0.15 * qty;
    return null;
  }

  static double? _byCategoryKg(String name) {
    final cat = CategoryIcons.categoryFor(name);
    return _perKgByCategory[cat];
  }
}
