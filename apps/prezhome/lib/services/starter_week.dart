import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/starter_recipes.dart';
import '../models/ingredient.dart';
import '../models/meal_plan_entry.dart';
import '../models/recipe.dart';
import 'meal_planner.dart';
import 'plan_shopping.dart';

/// Al terminar el cuestionario, un hogar sin recetas recibe unas caseras y
/// su semana planificada (comida y cena) con la lista de la compra hecha.
class StarterWeek {
  StarterWeek._();

  /// Devuelve true si ha montado la semana.
  static Future<bool> buildIfEmpty(
    SupabaseClient client,
    String homeId,
    int people,
  ) async {
    final existing = await client
        .from('recipes')
        .select('id')
        .eq('home_id', homeId)
        .limit(1);
    if ((existing as List).isNotEmpty) return false;

    final inserted = await client.from('recipes').insert([
      for (final s in starterRecipes)
        {
          'home_id': homeId,
          'title': s.title,
          'instructions': s.steps.join('\n'),
          'servings': 2,
          'prep_minutes': s.prepMinutes,
          'cook_minutes': s.cookMinutes,
          'appliance': s.appliance,
          'meal_types': s.mealTypes,
          'meal_type': s.mealTypes.first,
          'freezable': s.freezable,
        },
    ]).select();
    final recipes = [for (final m in inserted) Recipe.fromMap(m)];
    final byTitle = {for (final s in starterRecipes) s.title: s};

    await client.from('recipe_ingredients').insert([
      for (final r in recipes)
        for (final (i, (name, qty, unit))
            in byTitle[r.title]!.ingredients.indexed)
          Ingredient(
            name: name,
            quantity: qty,
            unit: unit,
            position: i,
          ).toInsertMap(recipeId: r.id, homeId: homeId),
    ]);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final plan = MealPlanner().generate(
      startDate: start,
      days: 7,
      mealTypes: const ['lunch', 'dinner'],
      recipes: recipes,
    );
    final rows = [
      for (final day in plan.entries)
        for (final meal in day.value.entries)
          MealPlanEntry(
            homeId: homeId,
            date: day.key,
            mealType: meal.key,
            recipeId: meal.value,
            servings: people,
          ).toMap(),
    ];
    if (rows.isEmpty) return false;
    await client.from('meal_plan_entries').insert(rows);

    final service = PlanShoppingService(client);
    final added = await service.syncFromPlan(
      homeId: homeId,
      from: start,
      to: start.add(const Duration(days: 7)),
    );
    if (added.isNotEmpty) unawaited(service.fillMissingPhotos(homeId, added));
    return true;
  }
}
