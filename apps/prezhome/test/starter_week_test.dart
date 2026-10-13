import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/data/starter_recipes.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/meal_planner.dart';

void main() {
  test('las recetas iniciales llenan comidas y cenas de una semana', () {
    expect(
      starterRecipes.map((s) => s.title).toSet().length,
      starterRecipes.length,
    );
    for (final s in starterRecipes) {
      expect(s.ingredients, isNotEmpty, reason: s.title);
      expect(s.steps, isNotEmpty, reason: s.title);
    }
    final recipes = [
      for (final s in starterRecipes)
        Recipe(
          id: s.title,
          homeId: 'h',
          title: s.title,
          servings: 2,
          mealTypes: s.mealTypes,
        ),
    ];
    final plan = MealPlanner(seed: 1).generate(
      startDate: DateTime(2026, 10, 13),
      days: 7,
      mealTypes: const ['lunch', 'dinner'],
      recipes: recipes,
    );
    expect(plan.length, 7);
    for (final meals in plan.values) {
      expect(meals.keys.toSet(), {'lunch', 'dinner'});
    }
  });
}
