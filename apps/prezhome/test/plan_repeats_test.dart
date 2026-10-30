import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/plan_repeats.dart';

void main() {
  test('Cada 2 días, solo después de lo ya rellenado', () {
    final dates = PlanRepeats.dueDates(
      start: DateTime(2026, 11, 1),
      everyDays: 2,
      after: DateTime(2026, 11, 3),
      until: DateTime(2026, 11, 9),
    );
    expect(dates, [
      DateTime(2026, 11, 5),
      DateTime(2026, 11, 7),
      DateTime(2026, 11, 9),
    ]);
  });

  test('Respeta la fecha de fin y cruza meses', () {
    final dates = PlanRepeats.dueDates(
      start: DateTime(2026, 10, 25),
      everyDays: 7,
      end: DateTime(2026, 11, 10),
      after: DateTime(2026, 10, 25),
      until: DateTime(2026, 12, 31),
    );
    expect(dates, [DateTime(2026, 11, 1), DateTime(2026, 11, 8)]);
  });
}
