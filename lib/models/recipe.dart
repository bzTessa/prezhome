class Recipe {
  final String id;
  final String homeId;
  final String title;
  final String? description;
  final int servings;
  final int? prepTimeMinutes;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  Recipe({
    required this.id,
    required this.homeId,
    required this.title,
    this.description,
    required this.servings,
    this.prepTimeMinutes,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      homeId: map['home_id'],
      title: map['title'],
      description: map['description'],
      servings: map['servings'] ?? 1,
      prepTimeMinutes: map['prep_time_minutes'],
      calories: map['calories_per_serving'],
      protein: (map['protein_grams'] as num?)?.toDouble(),
      carbs: (map['carbs_grams'] as num?)?.toDouble(),
      fat: (map['fat_grams'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'title': title,
      'description': description,
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'calories_per_serving': calories,
      'protein_grams': protein,
      'carbs_grams': carbs,
      'fat_grams': fat,
    };
  }
}