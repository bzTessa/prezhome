class MealPlanEntry {
  final String? id;
  final String homeId;
  final DateTime date;
  final String mealType; // breakfast/lunch/dinner/snack/dessert
  final String? recipeId;
  final bool skipped;

  MealPlanEntry({
    this.id,
    required this.homeId,
    required this.date,
    required this.mealType,
    this.recipeId,
    this.skipped = false,
  });

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'],
      homeId: map['home_id'],
      date: DateTime.parse(map['plan_date']),
      mealType: map['meal_type'],
      recipeId: map['recipe_id'],
      skipped: map['skipped'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'plan_date': date.toIso8601String().split('T').first,
      'meal_type': mealType,
      'recipe_id': recipeId,
      'skipped': skipped,
    };
  }
}
