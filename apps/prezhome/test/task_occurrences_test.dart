import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/services/task_scheduler.dart';

/// Crea una HomeTask minima para probar la proyeccion de ocurrencias. Solo nos
/// interesan los campos que usan TaskOccurrences.inRange y computeNextDue:
/// recurrencia, ancla (nextDue/dueDate), is_done y los parametros de
/// recurrencia (weekdays / intervalCount / intervalUnit).
HomeTask _task({
  required String recurrence,
  DateTime? nextDue,
  DateTime? dueDate,
  bool isDone = false,
  int? intervalCount,
  String? intervalUnit,
  List<int> weekdays = const [],
}) {
  return HomeTask(
    id: 't',
    homeId: 'h',
    title: 'Prueba',
    recurrence: recurrence,
    nextDue: nextDue,
    dueDate: dueDate,
    isDone: isDone,
    intervalCount: intervalCount,
    intervalUnit: intervalUnit,
    weekdays: weekdays,
  );
}

void main() {
  group('TaskOccurrences.inRange', () {
    // Mes concreto: enero de 2024 (1 de enero fue lunes).
    final from = DateTime(2024, 1, 1);
    final to = DateTime(2024, 1, 31);

    test('daily proyecta una ocurrencia por cada dia del mes', () {
      final task = _task(recurrence: 'daily', nextDue: DateTime(2024, 1, 1));
      final days = TaskOccurrences.inRange(task, from, to);
      // Del 1 al 31 ambos inclusive: 31 ocurrencias.
      expect(days.length, 31);
      expect(days.first, DateTime(2024, 1, 1));
      expect(days.last, DateTime(2024, 1, 31));
    });

    test('weekly proyecta los lunes del mes', () {
      final task = _task(recurrence: 'weekly', nextDue: DateTime(2024, 1, 1));
      final days = TaskOccurrences.inRange(task, from, to);
      // Lunes de enero 2024: 1, 8, 15, 22, 29.
      expect(days, [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 8),
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 22),
        DateTime(2024, 1, 29),
      ]);
    });

    test('custom_weekdays [L,X,V] proyecta todas sus apariciones del mes', () {
      // weekdays 1=Lun, 3=Mie, 5=Vie. Ancla el lunes 1 de enero.
      final task = _task(
        recurrence: 'custom_weekdays',
        weekdays: const [1, 3, 5],
        nextDue: DateTime(2024, 1, 1),
      );
      final days = TaskOccurrences.inRange(task, from, to);
      // L/X/V de enero 2024, empezando por el ancla (lunes 1).
      expect(days, [
        DateTime(2024, 1, 1), // L
        DateTime(2024, 1, 3), // X
        DateTime(2024, 1, 5), // V
        DateTime(2024, 1, 8), // L
        DateTime(2024, 1, 10), // X
        DateTime(2024, 1, 12), // V
        DateTime(2024, 1, 15), // L
        DateTime(2024, 1, 17), // X
        DateTime(2024, 1, 19), // V
        DateTime(2024, 1, 22), // L
        DateTime(2024, 1, 24), // X
        DateTime(2024, 1, 26), // V
        DateTime(2024, 1, 29), // L
        DateTime(2024, 1, 31), // X
      ]);
    });

    test('avanza el cursor cuando el ancla es anterior al rango', () {
      // Ancla en diciembre: weekly cada 7 dias debe adelantarse hasta entrar
      // en enero y proyectar desde el primer lunes dentro del rango.
      final task = _task(
        recurrence: 'weekly',
        nextDue: DateTime(2023, 12, 18), // lunes anterior al rango
      );
      final days = TaskOccurrences.inRange(task, from, to);
      // No incluye ninguna fecha de diciembre y arranca dentro del rango.
      expect(days.first, DateTime(2024, 1, 1));
      expect(days.every((d) => !d.isBefore(from) && !d.isAfter(to)), isTrue);
      expect(days, [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 8),
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 22),
        DateTime(2024, 1, 29),
      ]);
    });

    test('custom_interval cada 3 dias desde el ancla', () {
      final task = _task(
        recurrence: 'custom_interval',
        intervalCount: 3,
        intervalUnit: 'day',
        nextDue: DateTime(2024, 1, 1),
      );
      final days = TaskOccurrences.inRange(task, from, to);
      expect(days.first, DateTime(2024, 1, 1));
      expect(days[1], DateTime(2024, 1, 4));
      expect(days[2], DateTime(2024, 1, 7));
      expect(days.last, DateTime(2024, 1, 31));
      // Todas separadas por 3 dias.
      for (var i = 1; i < days.length; i++) {
        expect(days[i].difference(days[i - 1]).inDays, 3);
      }
    });

    test('once pendiente aparece una vez si cae dentro del rango', () {
      final task = _task(
        recurrence: 'once',
        nextDue: DateTime(2024, 1, 10),
        isDone: false,
      );
      final days = TaskOccurrences.inRange(task, from, to);
      expect(days, [DateTime(2024, 1, 10)]);
    });

    test('once completada (is_done) NO aparece', () {
      final task = _task(
        recurrence: 'once',
        nextDue: DateTime(2024, 1, 10),
        isDone: true,
      );
      final days = TaskOccurrences.inRange(task, from, to);
      expect(days, isEmpty);
    });

    test('once fuera del rango NO aparece', () {
      final task = _task(
        recurrence: 'once',
        nextDue: DateTime(2024, 2, 5),
        isDone: false,
      );
      final days = TaskOccurrences.inRange(task, from, to);
      expect(days, isEmpty);
    });
  });
}
