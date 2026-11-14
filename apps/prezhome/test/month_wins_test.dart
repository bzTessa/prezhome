import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/month_wins.dart';

void main() {
  final now = DateTime(2026, 11, 14, 20);

  test('cuenta aprovechado y tirado de este mes y compara con el anterior', () {
    final w = MonthWins.fromRows(
      pantryLog: [
        {'reason': 'consumido', 'rescued': true, 'used_on': '2026-11-03'},
        {'reason': 'consumido', 'rescued': false, 'used_on': '2026-11-04'},
        {'reason': 'consumido', 'rescued': true, 'used_on': '2026-10-30'},
        {'reason': 'tirado', 'rescued': false, 'used_on': '2026-11-10'},
        {'reason': 'tirado', 'rescued': false, 'used_on': '2026-10-02'},
        {'reason': 'tirado', 'rescued': false, 'used_on': '2026-10-20'},
        {'reason': 'tirado', 'rescued': false, 'used_on': '2026-10-21'},
      ],
      meals: const [],
      tasksDone: 0,
      now: now,
    );
    expect(w.rescued, 1);
    expect(w.thrown, 1);
    expect(w.thrownLastMonth, 3);
    expect(w.thrownLess, 2);
  });

  test('comidas en casa: este mes, hasta hoy y sin las saltadas', () {
    final w = MonthWins.fromRows(
      pantryLog: const [],
      meals: [
        {'plan_date': '2026-11-01', 'skipped': false},
        {'plan_date': '2026-11-14', 'skipped': null},
        {'plan_date': '2026-11-13', 'skipped': true},
        {'plan_date': '2026-11-15', 'skipped': false},
        {'plan_date': '2026-10-31', 'skipped': false},
      ],
      tasksDone: 4,
      now: now,
    );
    expect(w.mealsAtHome, 2);
    expect(w.tasksDone, 4);
    expect(w.isEmpty, isFalse);
  });

  test('sin datos queda vacío y sin mejora', () {
    final w = MonthWins.fromRows(
      pantryLog: const [],
      meals: const [],
      tasksDone: 0,
      now: now,
    );
    expect(w.isEmpty, isTrue);
    expect(w.thrownLess, 0);
  });
}
