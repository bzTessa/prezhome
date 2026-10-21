import '../models/meal_plan_entry.dart';
import '../models/recipe.dart';
import 'meal_prep_planner.dart';

/// Plan de cocina en lote de la semana que empieza en [weekStart], desde el
/// día en que se hizo el plan. No cambia al pasar los días: así los tápers
/// que ya se guardaron cuadran con lo que se ve. Lo comparten el plan semanal,
/// el calendario del mes y los tápers automáticos para que digan lo mismo.
MealPrepPlan prepPlanForWeek({
  required List<MealPlanEntry> entries,
  required Map<String, Recipe> recipesById,
  required DateTime weekStart,
  int energyLevel = 1,
}) {
  final end = weekStart.add(const Duration(days: 7));
  // Rehacer el plan borra la semana y la vuelve a crear: la fila más antigua
  // dice cuándo se hizo.
  DateTime? made;
  for (final e in entries) {
    final c = e.createdAt;
    if (c == null || e.date.isBefore(weekStart) || !e.date.isBefore(end)) {
      continue;
    }
    final d = DateTime(c.year, c.month, c.day);
    if (made == null || d.isBefore(made)) made = d;
  }
  final from = made != null && made.isAfter(weekStart) ? made : weekStart;
  final meals = <PrepMeal>[
    for (final e in entries)
      // Sin raciones (nadie come en casa o plan antiguo) no se cocina; lo que
      // sale del congelador ya está hecho.
      if (!e.skipped &&
          !e.fromFreezer &&
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
