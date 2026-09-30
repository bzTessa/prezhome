class InventoryItem {
  final String id;
  final String homeId;
  final String name;
  final String category; // Despensa | Nevera | Congelador (ubicación)
  final double quantity;
  final String unit;
  final DateTime? expirationDate;

  // Niveles del inventario inteligente
  final String kind; // ingredient | prep | dish
  final String? recipeId; // si procede de una receta
  final double? servings; // nº de raciones (para platos/preparados)
  final DateTime? frozenOn; // fecha de congelación
  final DateTime? bestBefore; // consumo preferente

  InventoryItem({
    required this.id,
    required this.homeId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.kind = 'ingredient',
    this.recipeId,
    this.servings,
    this.frozenOn,
    this.bestBefore,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      homeId: map['home_id'],
      name: map['name'],
      category: map['category'],
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      expirationDate: map['expiration_date'] != null
          ? DateTime.parse(map['expiration_date'])
          : null,
      kind: map['kind'] ?? 'ingredient',
      recipeId: map['recipe_id'],
      servings: (map['servings'] as num?)?.toDouble(),
      frozenOn: map['frozen_on'] != null
          ? DateTime.parse(map['frozen_on'])
          : null,
      bestBefore: map['best_before'] != null
          ? DateTime.parse(map['best_before'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String().split('T').first,
      'kind': kind,
      'recipe_id': recipeId,
      'servings': servings,
      'frozen_on': frozenOn?.toIso8601String().split('T').first,
      'best_before': bestBefore?.toIso8601String().split('T').first,
    };
  }

  /// Días que quedan hasta el consumo preferente (null si no tiene fecha).
  int? get daysUntilBestBefore {
    if (bestBefore == null) return null;
    final today = DateTime.now();
    return bestBefore!
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  static const Map<String, String> kindLabels = {
    'ingredient': 'Ingrediente',
    'prep': 'Preparado',
    'dish': 'Plato listo',
  };

  String get kindLabel => kindLabels[kind] ?? 'Ingrediente';
}
