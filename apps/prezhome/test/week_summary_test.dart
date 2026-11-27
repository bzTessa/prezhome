import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/week_summary.dart';

void main() {
  test('solo hay resumen el domingo (esta semana) y el lunes (la pasada)', () {
    // 29/11/2026 es domingo.
    expect(
      WeekSummary.weekFor(DateTime(2026, 11, 29, 20)),
      DateTime(2026, 11, 23),
    );
    expect(
      WeekSummary.weekFor(DateTime(2026, 11, 30, 9)),
      DateTime(2026, 11, 23),
    );
    expect(WeekSummary.weekFor(DateTime(2026, 11, 27)), isNull);
  });

  test('cuenta la semana y compara lo tirado con la anterior', () {
    final s = WeekSummary.fromRows(
      weekStart: DateTime(2026, 11, 23),
      now: DateTime(2026, 11, 29, 20),
      meals: [
        {'plan_date': '2026-11-23', 'skipped': false},
        {'plan_date': '2026-11-24', 'skipped': true},
        {'plan_date': '2026-11-29'},
      ],
      tickets: [
        {'total_amount': 40.5},
        {'total_amount': 12},
      ],
      pantryLog: [
        {'used_on': '2026-11-20', 'reason': 'tirado'},
        {'used_on': '2026-11-21', 'reason': 'tirado'},
        {'used_on': '2026-11-25', 'reason': 'tirado'},
        {'used_on': '2026-11-26', 'reason': 'consumido', 'rescued': true},
      ],
      tasksDone: 5,
    );
    expect(s.mealsAtHome, 2);
    expect(s.spent, 52.5);
    expect(s.rescued, 1);
    expect(s.thrown, 1);
    expect(s.thrownLess, 1);
    expect(s.tasksDone, 5);
    expect(s.isEmpty, isFalse);
  });
}
