import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/meal_plan_entry.dart';
import 'package:prezhome/services/leftovers.dart';
import 'package:prezhome/services/meal_prep_planner.dart';

MealPlanEntry e(int day, String meal, String recipe, {bool skipped = false}) =>
    MealPlanEntry(
      homeId: 'h',
      date: DateTime(2026, 3, day),
      mealType: meal,
      recipeId: recipe,
      skipped: skipped,
      servings: 2,
    );

void main() {
  test('los días impares repiten solo las comidas elegidas', () {
    // 29 de marzo hay cambio de hora: no debe descolocar los días.
    final plan = {
      for (var d = 27; d <= 31; d++)
        DateTime(2026, 3, d): {'lunch': 'L$d', 'dinner': 'D$d'},
    };
    applyLeftovers(plan, DateTime(2026, 3, 27), {'dinner'});
    expect(
      [for (var d = 27; d <= 31; d++) plan[DateTime(2026, 3, d)]!['dinner']],
      ['D27', 'D27', 'D29', 'D29', 'D31'],
    );
    expect(plan[DateTime(2026, 3, 28)]!['lunch'], 'L28');
  });

  test('sobras: misma receta y comida la víspera, sin saltar', () {
    final all = [
      e(1, 'dinner', 'a'),
      e(2, 'dinner', 'a'),
      e(2, 'lunch', 'a'),
      e(4, 'dinner', 'b', skipped: true),
      e(5, 'dinner', 'b'),
    ];
    expect(
      [for (final x in all) isLeftover(x, all)],
      [false, true, false, false, false],
    );
  });

  test('táper de sobras: nevera al cocinar, comido al acabar el día', () {
    final all = [e(1, 'dinner', 'a'), e(2, 'dinner', 'a')];
    final moves = leftoverTaperMoves(all, {'a': 'lentejas'}, (_) => 21 * 60);
    expect(moves.map((m) => (m.step, m.at)), [
      (TaperStep.guardar, DateTime(2026, 3, 1, 21)),
      (TaperStep.comido, DateTime(2026, 3, 3)),
    ]);
    expect(moves.first.frozen, isFalse);
    expect(moves.first.name, 'Lentejas (lun 2)');
  });
}
