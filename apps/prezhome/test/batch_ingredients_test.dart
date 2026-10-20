import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/meal_plan_entry.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/meal_prep_planner.dart';
import 'package:prezhome/services/plan_prep.dart';
import 'package:prezhome/services/plan_shopping.dart';

void main() {
  test('los ingredientes de la tanda se multiplican y se suman', () {
    const batches = [
      PrepBatch(
        recipeId: 'a',
        title: 'Lentejas',
        totalServings: 4,
        fridgeServings: 4,
        freezerServings: 0,
      ),
      PrepBatch(
        recipeId: 'b',
        title: 'Guiso',
        totalServings: 2,
        fridgeServings: 2,
        freezerServings: 0,
      ),
    ];
    final lines = batchIngredientLines(
      [
        {'recipe_id': 'a', 'name': 'cebolla', 'quantity': 1, 'unit': 'unidad'},
        {'recipe_id': 'b', 'name': 'cebolla', 'quantity': 1, 'unit': 'unidad'},
        {'recipe_id': 'a', 'name': 'sal', 'quantity': null, 'unit': 'al gusto'},
        {'recipe_id': 'x', 'name': 'otra', 'quantity': 1, 'unit': 'g'},
      ],
      batches,
      {'a': 2, 'b': 2},
    );
    expect(lines, ['3 unidades cebolla', 'al gusto sal']);
  });

  test('la tanda sale del día en que se hizo el plan y no se mueve', () {
    final monday = DateTime(2025, 10, 6);
    Recipe recipe(String id) => Recipe.fromMap({
      'id': id,
      'home_id': 'h',
      'title': id,
      'servings': 1,
      'freezable': true,
    });
    MealPlanEntry e(int day, String id, {bool frozen = false}) => MealPlanEntry(
      homeId: 'h',
      date: monday.add(Duration(days: day)),
      mealType: 'lunch',
      recipeId: id,
      servings: 1,
      fromFreezer: frozen,
      createdAt: DateTime(2025, 10, 7, 9),
    );
    final plan = prepPlanForWeek(
      entries: [e(2, 'a'), e(3, 'b', frozen: true), e(4, 'a')],
      recipesById: {'a': recipe('a'), 'b': recipe('b')},
      weekStart: monday,
      energyLevel: 0,
    );
    expect(plan.cookingDays.single.date, DateTime(2025, 10, 7));
    // Lo que sale del congelador ya está hecho.
    expect(plan.cookingDays.single.batches.map((b) => b.recipeId), ['a']);
  });
}
