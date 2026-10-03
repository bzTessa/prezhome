class MealPlanEntry {
  final String? id;
  final String homeId;
  final DateTime date;
  final String mealType; // breakfast/lunch/dinner/snack/dessert
  final String? recipeId;
  final bool skipped;
  final bool fromFreezer; // true = se consume de un plato congelado
  final String? inventoryItemId; // item del congelador del que procede
  final int? servings; // raciones a cocinar (nº de personas que comen en casa)

  MealPlanEntry({
    this.id,
    required this.homeId,
    required this.date,
    required this.mealType,
    this.recipeId,
    this.skipped = false,
    this.fromFreezer = false,
    this.inventoryItemId,
    this.servings,
  });

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    // Parseo tolerante: algunas consultas no traen todas las columnas
    // (por ejemplo el resumen de Inicio no pide home_id ni id). Antes esto
    // reventaba con "Null is not a subtype of String" y dejaba el calendario
    // y el resumen de hoy vacios aunque el plan existiera. Nunca debe petar.
    return MealPlanEntry(
      id: map['id'] as String?,
      homeId: (map['home_id'] ?? '') as String,
      date: _parseDate(map['plan_date']),
      mealType: (map['meal_type'] ?? '') as String,
      recipeId: map['recipe_id'] as String?,
      skipped: (map['skipped'] as bool?) ?? false,
      fromFreezer: (map['from_freezer'] as bool?) ?? false,
      inventoryItemId: map['inventory_item_id'] as String?,
      servings: (map['servings'] as num?)?.toInt(),
    );
  }

  // Parsea la fecha de forma segura. Si viene nula o con un formato invalido
  // devolvemos la fecha de hoy para no romper la carga del plan.
  static DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'plan_date': date.toIso8601String().split('T').first,
      'meal_type': mealType,
      'recipe_id': recipeId,
      'skipped': skipped,
      'from_freezer': fromFreezer,
      'inventory_item_id': inventoryItemId,
      'servings': servings,
    };
  }
}
