import '../models/meal_plan_entry.dart';
import '../models/recipe.dart';
import 'meal_prep_planner.dart';

/// Plan de cocina en lote de la semana que empieza en [weekStart], solo con
/// lo que queda por comer desde [today]. Lo comparten el plan semanal y el
/// calendario del mes para que digan lo mismo.
MealPrepPlan prepPlanForWeek({
  required List<MealPlanEntry> entries,
  required Map<String, Recipe> recipesById,
  required DateTime weekStart,
  required DateTime today,
  int energyLevel = 1,
}) {
  final from = weekStart.isAfter(today) ? weekStart : today;
  final end = weekStart.add(const Duration(days: 7));
  final meals = <PrepMeal>[
    for (final e in entries)
      // Sin raciones (nadie come en casa o plan antiguo) no se cocina.
      if (!e.skipped &&
          e.recipeId != null &&
          (e.servings ?? 0) > 0 &&
          !e.date.isBefore(from) &&
          e.date.isBefore(end))
        PrepMeal(
          recipeId: e.recipeId!,
          date: e.date,
          mealType: e.mealType,
          servings: e.servings!,
        ),
  ];
  return const MealPrepPlanner().buildPlan(
    meals: meals,
    recipesById: {
      for (final r in recipesById.values)
        r.id: PrepRecipe(
          id: r.id,
          title: r.title,
          freezable: r.freezable,
          freezerDays: r.freezerDays,
          prepTimeMinutes: r.prepTimeMinutes,
          cookTimeMinutes: r.cookTimeMinutes,
        ),
    },
    weekStart: from,
    energyLevel: energyLevel,
  );
}
