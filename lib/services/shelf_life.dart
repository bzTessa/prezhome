import '../widgets/food_category_icon.dart';

/// Estima una VIDA ÚTIL aproximada (en días) de un alimento según su nombre y
/// la ubicación donde se guarda (Despensa, Nevera, Congelador). Sirve para
/// autocompletar una fecha de caducidad orientativa cuando la usuaria añade un
/// producto o escanea un ticket, de modo que no tenga que pensar en fechas:
/// la app la propone y ella puede ajustarla.
///
/// Filosofía (como el resto de PrezHome): "que quede bien en general". No busca
/// precisión de laboratorio, sino un valor razonable y seguro por defecto.
/// Siempre tira a la baja (mejor avisar un poco antes que tarde).
///
/// Estrategia en dos niveles:
///   1. Coincidencia por ALIMENTO concreto (mapa [_byFood]): palabras clave muy
///      habituales con su vida útil típica por ubicación (ej. leche abierta en
///      nevera ~5 días, pollo fresco ~2, pan ~4). Es lo más fino.
///   2. Si no hay match concreto, caemos a la CATEGORÍA del alimento
///      (reutilizando [CategoryIcons.categoryFor]) con una vida útil típica por
///      categoría y ubicación (ej. verdura en nevera ~6 días).
///
/// Para el CONGELADOR usamos una ventana por tipo (carnes/pescados/platos
/// cocinados aguantan distinto), con un valor por defecto de 90 días alineado
/// con [InventoryItem.defaultFreezerDays]. Las ESPECIAS no caducan de forma
/// relevante y devuelven null (sin fecha).
class ShelfLife {
  ShelfLife._();

  /// Ventana por defecto del congelador (días), alineada con
  /// InventoryItem.defaultFreezerDays.
  static const int defaultFreezerDays = 90;

  /// Vida útil típica (días) de alimentos concretos por ubicación.
  /// Las claves son palabras tal cual las normaliza [CategoryIcons.normalize]
  /// (minúsculas, sin acentos). Se comparan como prefijo de palabra, igual que
  /// la categorización, para que "pollos"/"pollo troceado" casen con "pollo".
  ///
  /// Cada entrada: (días en despensa, días en nevera, días en congelador).
  /// Un valor null significa "no aplica" en esa ubicación (p.ej. no tiene
  /// sentido tener leche en despensa, o congelar lechuga).
  static const Map<String, (int?, int?, int?)> _byFood = {
    // Lácteos y huevos
    'leche': (null, 5, null),
    'yogur': (null, 20, null),
    'queso': (null, 15, 120),
    'mantequilla': (null, 40, 180),
    'nata': (null, 5, null),
    'huevo': (null, 25, null),
    'huevos': (null, 25, null),
    // Carnes
    'pollo': (null, 2, 180),
    'pavo': (null, 2, 180),
    'ternera': (null, 3, 240),
    'cerdo': (null, 3, 180),
    'carne': (null, 3, 180),
    'filete': (null, 3, 180),
    'filetes': (null, 3, 180),
    'hamburguesa': (null, 2, 120),
    'salchicha': (null, 7, 60),
    'bacon': (null, 10, 60),
    'jamon': (null, 10, 60),
    'chorizo': (30, 30, 90),
    'embutido': (null, 10, 60),
    // Pescados
    'pescado': (null, 2, 120),
    'salmon': (null, 2, 120),
    'merluza': (null, 2, 120),
    'atun': (null, 2, 120),
    'gamba': (null, 2, 90),
    'gambas': (null, 2, 90),
    'marisco': (null, 1, 90),
    // Verduras
    'lechuga': (null, 5, null),
    'tomate': (7, 7, null),
    'cebolla': (30, 30, null),
    'ajo': (60, 60, null),
    'patata': (30, 30, null),
    'patatas': (30, 30, null),
    'zanahoria': (null, 15, 120),
    'pimiento': (null, 7, 120),
    'calabacin': (null, 7, 120),
    'brocoli': (null, 5, 120),
    'espinaca': (null, 4, 120),
    'espinacas': (null, 4, 120),
    'champinon': (null, 5, 90),
    'champinones': (null, 5, 90),
    'seta': (null, 5, 90),
    'setas': (null, 5, 90),
    // Frutas
    'manzana': (15, 25, null),
    'platano': (6, null, null),
    'banana': (6, null, null),
    'naranja': (15, 20, null),
    'pera': (10, 15, null),
    'fresa': (null, 4, 180),
    'fresas': (null, 4, 180),
    'uva': (null, 7, null),
    'uvas': (null, 7, null),
    'limon': (20, 30, null),
    'aguacate': (5, 7, null),
    'arandano': (null, 7, 180),
    'arandanos': (null, 7, 180),
    // Panadería / cereales / legumbres secas o en bote
    'pan': (4, 7, 60),
    'pan de molde': (10, null, 60),
    'harina': (240, null, null),
    'arroz': (365, null, null),
    'pasta': (365, null, null),
    'macarrones': (365, null, null),
    'espaguetis': (365, null, null),
    'avena': (240, null, null),
    'galleta': (120, null, null),
    'galletas': (120, null, null),
    'cereales': (120, null, null),
    'lenteja': (365, null, null),
    'lentejas': (365, null, null),
    'garbanzo': (365, null, null),
    'garbanzos': (365, null, null),
    'legumbres': (365, null, null),
    // Bebidas / conservas
    'zumo': (null, 5, null),
    'agua': (365, null, null),
    'refresco': (180, null, null),
    'conserva': (730, null, null),
    'lata': (730, null, null),
    'bote': (365, null, null),
  };

  /// Vida útil típica (días) por CATEGORÍA cuando no hay match de alimento
  /// concreto. (despensa, nevera, congelador).
  static const Map<FoodCategory, (int?, int?, int?)> _byCategory = {
    FoodCategory.verdura: (7, 6, 120),
    FoodCategory.fruta: (8, 10, 180),
    FoodCategory.carne: (null, 3, 180),
    FoodCategory.pescado: (null, 2, 120),
    FoodCategory.lacteos: (null, 10, 90),
    FoodCategory.bebidas: (180, 7, null),
    FoodCategory.panaderia: (120, null, 60),
    // Especias: no caducan de forma relevante -> sin fecha.
    FoodCategory.especias: (null, null, null),
    FoodCategory.otros: (30, 10, 90),
  };

  /// Índice de ubicación en las tuplas (despensa, nevera, congelador).
  static int _locationIndex(String category) {
    switch (category) {
      case 'Nevera':
        return 1;
      case 'Congelador':
        return 2;
      case 'Despensa':
      default:
        return 0;
    }
  }

  /// Devuelve la vida útil estimada en DÍAS para [name] en la ubicación
  /// [category] ('Despensa' | 'Nevera' | 'Congelador' | 'Especias'), o null si
  /// no se puede estimar (especias, o combinación sin valor típico).
  static int? estimateDays(String name, String category) {
    // Las especias no tienen fecha de caducidad relevante.
    if (category == 'Especias') return null;

    final tokens = CategoryIcons.normalize(
      name,
    ).split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();
    final idx = _locationIndex(category);

    // 1. Match por alimento concreto (prefijo de palabra, >=4 letras para
    //    evitar falsos positivos de palabras muy cortas).
    for (final entry in _byFood.entries) {
      final kw = entry.key;
      final parts = kw.split(' ');
      final matches = parts.length == 1
          ? tokens.any((t) => t == kw || (kw.length >= 4 && t.startsWith(kw)))
          : CategoryIcons.normalize(name).contains(kw);
      if (matches) {
        final days = _pick(entry.value, idx);
        if (days != null) return days;
        // Si el alimento no tiene valor en esta ubicación, seguimos a la
        // categoría (p.ej. congelar algo que la tabla concreta marca null).
        break;
      }
    }

    // 2. Caer a la categoría del alimento.
    final cat = CategoryIcons.categoryFor(name);
    final byCat = _byCategory[cat];
    if (byCat != null) {
      final days = _pick(byCat, idx);
      if (days != null) return days;
    }

    // 3. Congelador sin dato específico: ventana por defecto.
    if (category == 'Congelador') return defaultFreezerDays;

    return null;
  }

  static int? _pick((int?, int?, int?) t, int idx) {
    switch (idx) {
      case 0:
        return t.$1;
      case 1:
        return t.$2;
      case 2:
        return t.$3;
      default:
        return null;
    }
  }

  /// Fecha de caducidad estimada a partir de HOY para [name] en [category],
  /// o null si no se puede estimar. La fecha se normaliza a medianoche.
  static DateTime? estimateDate(
    String name,
    String category, {
    DateTime? from,
  }) {
    final days = estimateDays(name, category);
    if (days == null) return null;
    final base = from ?? DateTime.now();
    return DateTime(base.year, base.month, base.day + days);
  }
}
