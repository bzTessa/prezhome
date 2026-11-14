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

  test('ordena por urgencia y junta las atrasadas', () {
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
      DayLineKind.overdue,
      DayLineKind.expired,
      DayLineKind.shopping,
    ]);
    expect(lines[1].names, ['Leche', 'Yogur']);
    expect(lines[1].count, 3);
    expect(lines.where((l) => l.task != null).map((l) => l.task!.title), [
      'hoy',
      'sin fecha',
    ]);
    expect(lines[4].count, 3);
  });

  test('dos o más atrasadas van juntas para ponerse al día', () {
    final lines = buildDayBrief(
      today: today,
      tasks: [
        _task('vieja', DateTime(2026, 10, 21)),
        _task('sin fecha', null),
        _task('ayer', DateTime(2026, 11, 11)),
        _task('hoy', DateTime(2026, 11, 12)),
      ],
    );
    expect(lines.map((l) => l.kind), [
      DayLineKind.task,
      DayLineKind.task,
      DayLineKind.overdue,
    ]);
    expect(lines.take(2).map((l) => l.task!.title), ['hoy', 'sin fecha']);
    expect(lines.last.count, 2);
  });

  test('una sola atrasada sigue en la lista', () {
    final lines = buildDayBrief(
      today: today,
      tasks: [_task('ayer', DateTime(2026, 11, 11))],
    );
    expect(lines.single.kind, DayLineKind.task);
  });

  test('por la noche, lo que hay que sacar del congelador para mañana', () {
    final lines = buildDayBrief(today: today, defrostTomorrow: ['Pisto']);
    expect(lines.single.kind, DayLineKind.defrostTomorrow);
    expect(lines.single.names, ['Pisto']);
  });

  test('ponerse al día reparte las atrasadas, las más antiguas primero', () {
    final dates = spreadOverdue([
      _task('c', DateTime(2026, 11, 10)),
      _task('a', DateTime(2026, 10, 1)),
      _task('b', DateTime(2026, 11, 1)),
    ], today);
    expect(dates, {
      'a': DateTime(2026, 11, 12),
      'b': DateTime(2026, 11, 12),
      'c': DateTime(2026, 11, 13),
    });
  });

  test('limita las tareas de hoy a tres con "y N más"', () {
    final lines = buildDayBrief(
      today: today,
      tasks: [
        for (final n in ['a', 'b', 'c', 'd', 'e'])
          _task(n, DateTime(2026, 11, 12)),
      ],
    );
    expect(lines.map((l) => l.kind), [
      DayLineKind.task,
      DayLineKind.task,
      DayLineKind.task,
      DayLineKind.moreTasks,
    ]);
    expect(lines.last.count, 2);
  });
}
