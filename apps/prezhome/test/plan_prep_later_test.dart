import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/meal_plan_entry.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/plan_prep.dart';

MealPlanEntry _e(DateTime d, String recipe, {bool freezer = false}) =>
    MealPlanEntry(
      homeId: 'h',
      date: d,
      mealType: 'lunch',
      recipeId: recipe,
      servings: 2,
      fromFreezer: freezer,
    );

void main() {
  final recipes = {
    'caldo': Recipe(id: 'caldo', homeId: 'h', title: 'Caldo', servings: 4),
    'ensalada': Recipe(
      id: 'ensalada',
      homeId: 'h',
      title: 'Ensalada',
      servings: 2,
    ),
  };
  final w1 = DateTime(2026, 11, 2); // lunes
  final entries = [
    _e(w1, 'caldo'),
    _e(w1.add(const Duration(days: 1)), 'ensalada'),
    // Semanas siguientes: el caldo sale del congelador (plan de un mes).
    _e(DateTime(2026, 11, 10), 'caldo', freezer: true),
    _e(DateTime(2026, 11, 24), 'caldo', freezer: true),
  ];

  test('Lo de las semanas siguientes se cocina y congela la primera', () {
    final plan = prepPlanForWeek(
      entries: entries,
      recipesById: recipes,
      weekStart: w1,
    );
    final caldo = plan.cookingDays
        .expand((d) => d.batches)
        .firstWhere((b) => b.recipeId == 'caldo');
    expect(caldo.totalServings, 6);
    expect(caldo.freezerServings, 4);
    expect(caldo.freezerByDay.keys, [
      DateTime(2026, 11, 10),
      DateTime(2026, 11, 24),
    ]);
  });

  test('La semana siguiente no lo vuelve a cocinar', () {
    final plan = prepPlanForWeek(
      entries: entries,
      recipesById: recipes,
      weekStart: DateTime(2026, 11, 9),
    );
    expect(plan.cookingDays, isEmpty);
  });
}
