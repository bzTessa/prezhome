/// Una entrada del diario de consumo personal: algo que la persona se comió
/// un día concreto. Es PERSONAL (va por user_id), a diferencia del resto de la
/// app que es por hogar.
class FoodLogEntry {
  final String? id;
  final String userId;
  final DateTime logDate;
  final String? mealType; // breakfast/lunch/dinner/snack/dessert (opcional)
  final String name;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String source; // manual/receta/foto (foto reservado para la pieza 2)
  final String? recipeId;
  final DateTime? createdAt;

  FoodLogEntry({
    this.id,
    required this.userId,
    required this.logDate,
    this.mealType,
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.source = 'manual',
    this.recipeId,
    this.createdAt,
  });

  factory FoodLogEntry.fromMap(Map<String, dynamic> map) {
    // Parseo tolerante: no todas las consultas traen todas las columnas y
    // algunos campos pueden venir nulos. Nunca debe reventar la carga.
    return FoodLogEntry(
      id: map['id'] as String?,
      userId: (map['user_id'] ?? '') as String,
      logDate: _parseDate(map['log_date']),
      mealType: map['meal_type'] as String?,
      name: (map['name'] ?? '') as String,
      calories: (map['calories'] as num?)?.toDouble(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      source: (map['source'] ?? 'manual') as String,
      recipeId: map['recipe_id'] as String?,
      createdAt: _parseNullableDate(map['created_at']),
    );
  }

  // Parsea la fecha de forma segura. Si viene nula o con formato inválido,
  // devolvemos la fecha de hoy para no romper la carga del diario.
  static DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  // Igual que _parseDate pero sin fecha de hoy por defecto: devuelve null si
  // no hay valor (p. ej. created_at ausente antes de insertar).
  static DateTime? _parseNullableDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// Columnas insertables (sin id ni created_at, que los pone la BD).
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'log_date': logDate.toIso8601String().split('T').first,
      'meal_type': mealType,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'source': source,
      'recipe_id': recipeId,
    };
  }

  /// Etiquetas legibles en español de los tipos de comida, para que la UI
  /// agrupe por tipo con textos en español.
  static const Map<String, String> mealTypeLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Snack',
    'dessert': 'Postre',
  };
}
