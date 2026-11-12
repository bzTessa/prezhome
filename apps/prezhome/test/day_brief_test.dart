import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/utils/day_brief.dart';

HomeTask _task(String title, DateTime? due) =>
    HomeTask(id: title, homeId: 'h', title: title, nextDue: due);

void main() {
  final today = DateTime(2026, 11, 12, 21);

  test('sin nada pendiente, la lista sale vacía (casa al día)', () {
    expect(buildDayBrief(today: today), isEmpty);
  });

  test('ordena por urgencia y limita las tareas a tres con "y N más"', () {
    final lines = buildDayBrief(
      today: today,
      defrost: ['Lentejas'],
      expiring: ['Leche', 'Yogur', 'Pollo'],
      expired: 2,
      shopping: 6,
      tasks: [
        _task('vieja', DateTime(2026, 10, 21)),
        _task('sin fecha', null),
        _task('ayer', DateTime(2026, 11, 11)),
        _task('hoy', DateTime(2026, 11, 12)),
        _task('anteayer', DateTime(2026, 11, 10)),
      ],
    );
    expect(lines.map((l) => l.kind), [
      DayLineKind.defrost,
      DayLineKind.expiring,
      DayLineKind.task,
      DayLineKind.task,
      DayLineKind.task,
      DayLineKind.moreTasks,
      DayLineKind.expired,
      DayLineKind.shopping,
    ]);
    expect(lines[1].names, ['Leche', 'Yogur']);
    expect(lines[1].count, 3);
    expect(lines.where((l) => l.task != null).map((l) => l.task!.title), [
      'hoy',
      'ayer',
      'anteayer',
    ]);
    expect(lines[5].count, 2);
  });
}
