/// Estado de caducidad de un producto, pensado para que la usuaria lo entienda
/// de un vistazo con colores cálidos (ver AppColors "Estados de caducidad").
enum ExpiryStatus {
  /// Aún queda tiempo de sobra.
  fresco,

  /// Caduca pronto (hoy o en los próximos días).
  pronto,

  /// Ya ha caducado.
  caducado,

  /// No tiene fecha de caducidad conocida.
  sinFecha,
}

class InventoryItem {
  final String id;
  final String homeId;
  final String name;
  final String category; // Despensa | Nevera | Congelador (ubicación)
  final String itemType; // comida | hogar
  final double quantity;
  final String unit;
  final DateTime? expirationDate;

  // "Siempre en casa": basico/especia que damos por supuesto. Cuando es true,
  // _generarDesdePlan lo trata como disponible y NO lo anade a la compra.
  final bool isStaple;

  // Niveles del inventario inteligente
  final String kind; // ingredient | prep | dish
  final String? recipeId; // si procede de una receta
  final double? servings; // nº de raciones (para platos/preparados)
  final DateTime? frozenOn; // fecha de congelación
  final DateTime? bestBefore; // consumo preferente

  /// URL http(s) COMPLETA de la foto real del alimento (banco de imágenes vía
  /// la edge function recipe-photo). NULL = sin foto; la UI muestra la
  /// ilustración cozy de la categoría en su lugar.
  final String? imageUrl;

  InventoryItem({
    required this.id,
    required this.homeId,
    required this.name,
    required this.category,
    this.itemType = 'comida',
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.isStaple = false,
    this.kind = 'ingredient',
    this.recipeId,
    this.servings,
    this.frozenOn,
    this.bestBefore,
    this.imageUrl,
  });

  // Devuelve el valor como String si no es null ni vacío; si no, null. Trata
  // la cadena vacía como ausencia de foto (igual que Recipe._nonEmptyString).
  static String? _nonEmptyString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      homeId: map['home_id'],
      name: map['name'],
      category: map['category'],
      itemType: map['item_type'] ?? 'comida',
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      expirationDate: map['expiration_date'] != null
          ? DateTime.parse(map['expiration_date'])
          : null,
      isStaple: (map['is_staple'] as bool?) ?? false,
      kind: map['kind'] ?? 'ingredient',
      recipeId: map['recipe_id'],
      servings: (map['servings'] as num?)?.toDouble(),
      frozenOn: map['frozen_on'] != null
          ? DateTime.parse(map['frozen_on'])
          : null,
      bestBefore: map['best_before'] != null
          ? DateTime.parse(map['best_before'])
          : null,
      imageUrl: _nonEmptyString(map['image_url']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'name': name,
      'category': category,
      'item_type': itemType,
      'quantity': quantity,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String().split('T').first,
      'is_staple': isStaple,
      'kind': kind,
      'recipe_id': recipeId,
      'servings': servings,
      'frozen_on': frozenOn?.toIso8601String().split('T').first,
      'best_before': bestBefore?.toIso8601String().split('T').first,
      'image_url': imageUrl,
    };
  }

  /// Serialización COMPLETA (incluye id) para CACHEAR la fila entera en disco y
  /// poder releerla con [InventoryItem.fromMap] al abrir la app sin conexión. A
  /// diferencia de [toMap] (que omite id porque lo pone la base de datos), aquí
  /// conservamos TODO el estado para reconstruir la fila tal cual. Útil también
  /// para el merge caché<->remoto. Usa las mismas claves snake_case que
  /// Supabase.
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'home_id': homeId,
      'name': name,
      'category': category,
      'item_type': itemType,
      'quantity': quantity,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String().split('T').first,
      'is_staple': isStaple,
      'kind': kind,
      'recipe_id': recipeId,
      'servings': servings,
      'frozen_on': frozenOn?.toIso8601String().split('T').first,
      'best_before': bestBefore?.toIso8601String().split('T').first,
      'image_url': imageUrl,
    };
  }

  /// Alias de [toCacheMap] para serializar a JSON (misma forma completa).
  Map<String, dynamic> toJson() => toCacheMap();

  /// Días que quedan hasta el consumo preferente (null si no tiene fecha).
  int? get daysUntilBestBefore {
    if (bestBefore == null) return null;
    final today = DateTime.now();
    return bestBefore!
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  // --- API de caducidades ----------------------------------------------------
  // Semántica única y sencilla para la usuaria: no tiene que pensar en reglas
  // distintas por ubicación. Nevera y Despensa usan la fecha de caducidad
  // directa; el Congelador usa el consumo preferente (best_before), que si no
  // se indica se calcula sumando una ventana de congelación por defecto a la
  // fecha de congelación.

  /// Ventana de congelación por defecto (en días). Es un valor genérico y
  /// seguro para que la usuaria no tenga que recordar cuánto aguanta cada
  /// alimento congelado: unos 3 meses cubren la mayoría de los casos.
  static const int defaultFreezerDays = 90;

  /// Fecha de caducidad efectiva según la ubicación:
  /// - Congelador: best_before si está, si no frozen_on + [defaultFreezerDays].
  /// - Nevera/Despensa (y cualquier otra): expiration_date, o best_before si no
  ///   hay fecha de caducidad.
  DateTime? get effectiveExpiry {
    if (category == 'Congelador') {
      if (bestBefore != null) return bestBefore;
      if (frozenOn != null) {
        return frozenOn!.add(const Duration(days: defaultFreezerDays));
      }
      return null;
    }
    return expirationDate ?? bestBefore;
  }

  /// Días que quedan hasta la caducidad efectiva (null si no tiene fecha).
  /// Usa la misma normalización de fecha que [daysUntilBestBefore].
  int? get daysUntilExpiry {
    final expiry = effectiveExpiry;
    if (expiry == null) return null;
    final today = DateTime.now();
    return expiry
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  /// Estado de caducidad según umbrales cálidos y sencillos:
  /// - sin fecha => [ExpiryStatus.sinFecha]
  /// - días < 0 => [ExpiryStatus.caducado]
  /// - días <= 3 => [ExpiryStatus.pronto]
  /// - en otro caso => [ExpiryStatus.fresco]
  ExpiryStatus get expiryStatus {
    final days = daysUntilExpiry;
    if (days == null) return ExpiryStatus.sinFecha;
    if (days < 0) return ExpiryStatus.caducado;
    if (days <= 3) return ExpiryStatus.pronto;
    return ExpiryStatus.fresco;
  }

  static const Map<ExpiryStatus, String> expiryLabels = {
    ExpiryStatus.fresco: 'Fresco',
    ExpiryStatus.pronto: 'Caduca pronto',
    ExpiryStatus.caducado: 'Caducado',
    ExpiryStatus.sinFecha: 'Sin fecha',
  };

  /// Etiqueta corta en español para el estado de caducidad.
  String get expiryLabel => expiryLabels[expiryStatus] ?? 'Sin fecha';

  static const Map<String, String> kindLabels = {
    'ingredient': 'Ingrediente',
    'prep': 'Preparado',
    'dish': 'Plato listo',
  };

  String get kindLabel => kindLabels[kind] ?? 'Ingrediente';

  static const Map<String, String> itemTypeLabels = {
    'comida': 'Comida',
    'hogar': 'Hogar/Limpieza',
  };

  String get itemTypeLabel => itemTypeLabels[itemType] ?? 'Comida';
}
