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
  final List<String> mealTypes; // breakfast/lunch/dinner/snack/dessert
  final bool isFavorite;
  final bool freezable;
  final double? gramsPerServing; // peso de una ración ya preparada
  final String? imageUrl; // URL pública de la foto de la receta
  final List<RecipeComponent> components; // partes del plato (pollo, arroz...)
  final int? freezerDays; // días recomendados de congelación (estimado por IA)

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
    this.gramsPerServing,
    this.imageUrl,
    this.components = const [],
    this.freezerDays,
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
      gramsPerServing: (map['grams_per_serving'] as num?)?.toDouble(),
      imageUrl: _imageUrlFrom(map['image_path']),
      components: _componentsFrom(map['components']),
      freezerDays: map['freezer_days'],
    );
  }

  static List<RecipeComponent> _componentsFrom(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => RecipeComponent.fromMap(Map<String, dynamic>.from(m)))
          .where((c) => c.name.isNotEmpty)
          .toList();
    }
    return const [];
  }

  // URL pública del bucket recipe-images a partir de la ruta guardada.
  static const String _supabaseUrl = 'https://ubrihtnnkbwcbchvvlno.supabase.co';
  static String? _imageUrlFrom(dynamic path) {
    if (path == null || path.toString().isEmpty) return null;
    return '$_supabaseUrl/storage/v1/object/public/recipe-images/$path';
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
      'grams_per_serving': gramsPerServing,
      'components': components.isEmpty
          ? null
          : components.map((c) => c.toMap()).toList(),
      'freezer_days': freezerDays,
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
    'dessert': 'Postre',
  };

  String get applianceLabel => applianceLabels[appliance] ?? 'Ninguno';

  /// Etiquetas legibles de los tipos de comida (ej. "Comida, Cena").
  List<String> get mealTypeLabelsList =>
      mealTypes.map((t) => mealTypeLabels[t] ?? t).toList();

  /// Icono representativo según el tipo de comida (para el placeholder visual).
  int get placeholderIconCode {
    if (mealTypes.contains('breakfast')) return 0xe57a; // free_breakfast
    if (mealTypes.contains('dessert')) return 0xe544; // cake
    if (mealTypes.contains('snack')) return 0xe561; // fastfood
    return 0xe56c; // restaurant
  }

  /// Densidad calórica: kcal por 100 g del plato preparado.
  double? get kcalPer100g {
    if (calories == null || gramsPerServing == null || gramsPerServing! <= 0) {
      return null;
    }
    return calories! / gramsPerServing! * 100;
  }

  /// Gramos necesarios para alcanzar [targetKcal] de este plato.
  double? gramsForCalories(int targetKcal) {
    final density = kcalPer100g; // kcal / 100 g
    if (density == null || density <= 0) return null;
    return targetKcal / density * 100;
  }

  bool get hasComponents => components.isNotEmpty;
}

/// Parte de un plato combinado (ej. "Arroz") con su % del peso total.
class RecipeComponent {
  final String name;
  final double proportion; // % del peso total del plato (0-100)

  RecipeComponent({required this.name, required this.proportion});

  factory RecipeComponent.fromMap(Map<String, dynamic> m) {
    return RecipeComponent(
      name: (m['name'] ?? '').toString(),
      proportion: (m['proportion'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'proportion': proportion};

  /// Gramos de este componente dado el peso total en gramos.
  double gramsFromTotal(double totalGrams) => totalGrams * proportion / 100;
}
