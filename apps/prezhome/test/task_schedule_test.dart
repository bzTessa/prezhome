import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';

/// Crea una HomeTask minima con la recurrencia a probar. Solo nos interesan los
/// campos que usa computeNextDue.
HomeTask _task({
  required String recurrence,
  int? intervalCount,
  String? intervalUnit,
  List<int> weekdays = const [],
}) {
  return HomeTask(
    id: 't',
    homeId: 'h',
    title: 'Prueba',
    recurrence: recurrence,
    intervalCount: intervalCount,
    intervalUnit: intervalUnit,
    weekdays: weekdays,
  );
}

void main() {
  group('HomeTask.computeNextDue', () {
    // 2024-01-01 fue lunes: util para los casos de dias de la semana.
    final monday = DateTime(2024, 1, 1);

    test('once devuelve null (no se reprograma)', () {
      expect(_task(recurrence: 'once').computeNextDue(monday), isNull);
    });

    test('daily avanza un dia', () {
      final next = _task(recurrence: 'daily').computeNextDue(monday);
      expect(next, DateTime(2024, 1, 2));
    });

    test('weekly avanza siete dias', () {
      final next = _task(recurrence: 'weekly').computeNextDue(monday);
      expect(next, DateTime(2024, 1, 8));
    });

    test('custom_interval cada 3 dias', () {
      final next = _task(
        recurrence: 'custom_interval',
        intervalCount: 3,
        intervalUnit: 'day',
      ).computeNextDue(monday);
      expect(next, DateTime(2024, 1, 4));
    });

    test('custom_interval cada 2 semanas', () {
      final next = _task(
        recurrence: 'custom_interval',
        intervalCount: 2,
        intervalUnit: 'week',
      ).computeNextDue(monday);
      expect(next, DateTime(2024, 1, 15));
    });

    test('custom_weekdays: completar un lunes [L,X,V] da el miercoles', () {
      // weekdays 1=Lun, 3=Mie, 5=Vie.
      final next = _task(
        recurrence: 'custom_weekdays',
        weekdays: const [1, 3, 5],
      ).computeNextDue(monday);
      expect(next, DateTime(2024, 1, 3)); // miercoles
      expect(next!.weekday, DateTime.wednesday);
    });

    test('custom_weekdays: desde el viernes [L,X,V] da el lunes (wrap)', () {
      // 2024-01-05 es viernes. El proximo marcado es el lunes siguiente.
      final friday = DateTime(2024, 1, 5);
      final next = _task(
        recurrence: 'custom_weekdays',
        weekdays: const [1, 3, 5],
      ).computeNextDue(friday);
      expect(next, DateTime(2024, 1, 8)); // lunes siguiente
      expect(next!.weekday, DateTime.monday);
    });

    test('custom_weekdays: domingo a lunes (wrap de fin de semana)', () {
      // 2024-01-07 es domingo. Con solo el lunes marcado, el siguiente es el
      // dia posterior.
      final sunday = DateTime(2024, 1, 7);
      final next = _task(
        recurrence: 'custom_weekdays',
        weekdays: const [1],
      ).computeNextDue(sunday);
      expect(next, DateTime(2024, 1, 8));
      expect(next!.weekday, DateTime.monday);
    });

    test('custom_weekdays sin dias marcados devuelve null', () {
      final next = _task(
        recurrence: 'custom_weekdays',
        weekdays: const [],
      ).computeNextDue(monday);
      expect(next, isNull);
    });

    test('normaliza la hora: ignora horas/minutos de from', () {
      final withTime = DateTime(2024, 1, 1, 23, 59);
      final next = _task(recurrence: 'daily').computeNextDue(withTime);
      expect(next, DateTime(2024, 1, 2));
    });
  });
}
