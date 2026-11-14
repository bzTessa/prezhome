import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/utils/task_share.dart';

HomeTask t(String id, String? who) =>
    HomeTask(id: id, homeId: 'h', title: id, assignedTo: who);

void main() {
  test('la semana empieza el lunes', () {
    expect(startOfWeek(DateTime(2026, 11, 14, 18)), DateTime(2026, 11, 9));
    expect(startOfWeek(DateTime(2026, 11, 9, 1)), DateTime(2026, 11, 9));
  });

  test('solo cuenta los puntos desde el lunes', () {
    final rows = [
      {'user_id': 'a', 'points': 10, 'created_at': '2026-11-10T10:00:00'},
      {'user_id': 'a', 'points': 5, 'created_at': '2026-11-12T10:00:00'},
      {'user_id': 'b', 'points': 20, 'created_at': '2026-11-01T10:00:00'},
    ];
    expect(pointsSince(rows, DateTime(2026, 11, 9)), {'a': 15});
  });

  test('agrupa: yo primero, luego el resto y al final sin asignar', () {
    final groups = groupByPerson(
      [t('1', 'm'), t('2', null), t('3', 'yo'), t('4', 'otro')],
      'yo',
      {'m': 'Marta', 'yo': 'Tessa'},
    );
    expect(groups.map((g) => g.key), ['yo', 'm', null]);
    expect(groups.last.value.map((x) => x.id), ['2', '4']);
  });

  test('ponerme al día: puntuales a hoy y recurrentes a su próxima vez', () {
    final now = DateTime(2026, 11, 14, 10); // sábado
    final dates = catchUpDates([
      HomeTask(id: 'once', homeId: 'h', title: 'x'),
      HomeTask(id: 'daily', homeId: 'h', title: 'x', recurrence: 'daily'),
      HomeTask(id: 'weekly', homeId: 'h', title: 'x', recurrence: 'weekly'),
      HomeTask(
        id: 'mon',
        homeId: 'h',
        title: 'x',
        recurrence: 'custom_weekdays',
        weekdays: const [1],
      ),
    ], now);
    expect(dates['once'], DateTime(2026, 11, 14));
    expect(dates['daily'], DateTime(2026, 11, 14));
    expect(dates['weekly'], DateTime(2026, 11, 20));
    expect(dates['mon'], DateTime(2026, 11, 16));
  });
}
