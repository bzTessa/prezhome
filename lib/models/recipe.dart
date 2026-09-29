class Recipe {
  final String id;
  final String homeId;
  final String title;
  final String? description;
  final String? instructions; // pasos de preparación
  final int servings;
  final int? prepTimeMinutes; // tiempo de preparación
  final int? cookTimeMinutes; // tiempo de cocción
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String appliance; // none | oven | stovetop | pot | airfryer | microwave
  final List<String> mealTypes; // varias: breakfast/lunch/dinner/snack
  final bool isFavorite;
  final bool freezable;

  Recipe({
    required this.id,
    required this.homeId,
    required this.title,
    this.description,
    this.instructions,
    required this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.appliance = 'none',
    this.mealTypes = const [],
    this.isFavorite = false,
    this.freezable = false,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    // meal_types (array) es lo nuevo; si viene vacío, caemos al meal_type (single).
    final rawTypes = map['meal_types'];
    List<String> types = [];
    if (rawTypes is List) {
      types = rawTypes.map((e) => e.toString()).toList();
    }
    if (types.isEmpty && map['meal_type'] != null) {
      types = [map['meal_type'].toString()];
    }

    return Recipe(
      id: map['id'],
      homeId: map['home_id'],
      title: map['title'],
      description: map['description'],
      instructions: map['instructions'],
      servings: map['servings'] ?? 1,
      prepTimeMinutes: map['prep_minutes'] ?? map['prep_time_minutes'],
      cookTimeMinutes: map['cook_minutes'],
      calories: map['calories_per_serving'],
      protein: (map['protein_grams'] as num?)?.toDouble(),
      carbs: (map['carbs_grams'] as num?)?.toDouble(),
      fat: (map['fat_grams'] as num?)?.toDouble(),
      appliance: map['appliance'] ?? 'none',
      mealTypes: types,
      isFavorite: map['is_favorite'] ?? false,
      freezable: map['freezable'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'servings': servings,
      'prep_minutes': prepTimeMinutes,
      'cook_minutes': cookTimeMinutes,
      'calories_per_serving': calories,
      'protein_grams': protein,
      'carbs_grams': carbs,
      'fat_grams': fat,
      'appliance': appliance,
      'meal_types': mealTypes,
      // Mantener meal_type (singular) sincronizado por compatibilidad.
      'meal_type': mealTypes.isNotEmpty ? mealTypes.first : 'lunch',
      'is_favorite': isFavorite,
      'freezable': freezable,
    };
  }

  int? get totalTimeMinutes {
    if (prepTimeMinutes == null && cookTimeMinutes == null) return null;
    return (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);
  }

  static const Map<String, String> applianceLabels = {
    'none': 'Ninguno',
    'oven': 'Horno',
    'stovetop': 'Sartén',
    'pot': 'Olla',
    'airfryer': 'Airfryer',
    'microwave': 'Microondas',
  };

  static const Map<String, String> mealTypeLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Snack',
  };

  String get applianceLabel => applianceLabels[appliance] ?? 'Ninguno';

  /// Etiquetas legibles de los tipos de comida (ej. "Comida, Cena").
  List<String> get mealTypeLabelsList =>
      mealTypes.map((t) => mealTypeLabels[t] ?? t).toList();
}
