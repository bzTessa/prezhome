import '../models/meal_plan_entry.dart';
import 'meal_prep_planner.dart';

/// Modo "Cada dos días": se cocina un día de más y al siguiente esas comidas
/// son sobras. Lógica pura, sin Flutter ni Supabase.

DateTime _day(DateTime d, [int plus = 0]) =>
    DateTime(d.year, d.month, d.day + plus);

/// Cambia el [plan] (fecha → comida → receta) para que en los días impares
/// desde [start] las [meals] repitan la receta del día anterior.
void applyLeftovers(
  Map<DateTime, Map<String, String>> plan,
  DateTime start,
  Set<String> meals,
) {
  // En UTC para que el cambio de hora no descuente un día.
  int index(DateTime d) => DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  final byDay = {for (final d in plan.keys) _day(d): plan[d]!};
  for (final entry in plan.entries) {
    final d = _day(entry.key);
    if (index(d).isOdd) {
      final prev = byDay[_day(d, -1)];
      if (prev == null) continue;
      for (final m in meals) {
        final r = prev[m];
        if (r != null) entry.value[m] = r;
      }
    }
  }
}

/// Si [e] son las sobras de ayer: la víspera, en la misma comida, hay la
/// misma receta y no se saltó.
bool isLeftover(MealPlanEntry e, Iterable<MealPlanEntry> all) {
  if (e.recipeId == null) return false;
  final prev = _day(e.date, -1);
  return all.any(
    (o) =>
        !o.skipped &&
        o.mealType == e.mealType &&
        o.recipeId == e.recipeId &&
        _day(o.date) == prev,
  );
}

/// Tápers de sobras: se guardan en la nevera a la hora de la comida del día
/// en que se cocina y se dan por comidos al acabar el día siguiente.
List<TaperMove> leftoverTaperMoves(
  List<MealPlanEntry> entries,
  Map<String, String> titles,
  int Function(String meal) minuteOf,
) {
  final moves = <TaperMove>[];
  for (final e in entries) {
    if (e.skipped || !isLeftover(e, entries)) continue;
    final eat = _day(e.date);
    final cook = _day(eat, -1);
    TaperMove move(TaperStep step, DateTime at) => TaperMove(
      at: at,
      step: step,
      recipeId: e.recipeId!,
      title: titles[e.recipeId] ?? '',
      eatDay: eat,
      servings: e.servings ?? 1,
      frozen: false,
      cookDay: cook,
    );
    moves
      ..add(
        move(
          TaperStep.guardar,
          DateTime(cook.year, cook.month, cook.day, 0, minuteOf(e.mealType)),
        ),
      )
      ..add(move(TaperStep.comido, _day(eat, 1)));
  }
  moves.sort((a, b) => a.at.compareTo(b.at));
  return moves;
}
