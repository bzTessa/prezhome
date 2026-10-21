import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/streak.dart';

void main() {
  // Miércoles 21/10/2026 por la tarde.
  final now = DateTime(2026, 10, 21, 18);
  DateTime d(int day) => DateTime(2026, 10, day, 10);

  test('cuenta días seguidos hasta hoy', () {
    final s = Streak.count({d(19), d(20), d(21)}, now);
    expect(s.days, 3);
    expect(s.doneToday, isTrue);
    expect(s.milestoneToday, isTrue);
  });

  test('si hoy aún no hay nada, la racha de ayer sigue viva', () {
    final s = Streak.count({d(19), d(20)}, now);
    expect(s.days, 2);
    expect(s.doneToday, isFalse);
  });

  test('un hueco por semana se perdona; el segundo la corta', () {
    // Semana del 19 al 25: falta el 20. Semana del 12 al 18: faltan 14 y 16.
    final s = Streak.count({d(13), d(15), d(17), d(18), d(19), d(21)}, now);
    // 21, (20 perdonado), 19, 18, 17, (16 perdonado), 15; el 14 corta.
    expect(s.days, 7);
  });

  test('dos días seguidos sin nada la cortan', () {
    expect(Streak.count({d(17), d(18)}, now).days, 0);
  });

  test('sin actividad, cero', () {
    expect(Streak.count({}, now).days, 0);
  });
}
