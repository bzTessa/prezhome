import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/utils/task_kinds.dart';

HomeTask _every(int n, String unit) => HomeTask(
  id: 't',
  homeId: 'h',
  title: 'Prueba',
  recurrence: 'custom_interval',
  intervalCount: n,
  intervalUnit: unit,
);

void main() {
  group('Mantenimiento: cada N meses o años', () {
    test('cada 3 meses va por calendario', () {
      expect(
        _every(3, 'month').computeNextDue(DateTime(2026, 11, 21)),
        DateTime(2027, 2, 21),
      );
    });

    test('31 de enero + 1 mes = último día de febrero', () {
      expect(
        _every(1, 'month').computeNextDue(DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28),
      );
      expect(
        _every(1, 'month').computeNextDue(DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
    });

    test('cada año, también desde un 29 de febrero', () {
      expect(
        _every(1, 'year').computeNextDue(DateTime(2026, 11, 21, 18, 30)),
        DateTime(2027, 11, 21),
      );
      expect(
        _every(1, 'year').computeNextDue(DateTime(2028, 2, 29)),
        DateTime(2029, 2, 28),
      );
    });

    test('addMonths cruza de año', () {
      expect(addMonths(DateTime(2026, 12, 15), 2), DateTime(2027, 2, 15));
      expect(addMonths(DateTime(2026, 11, 30), 6), DateTime(2027, 5, 30));
    });

    test('isMaintenance: meses, años o intervalos largos', () {
      expect(_every(1, 'month').isMaintenance, isTrue);
      expect(_every(1, 'year').isMaintenance, isTrue);
      expect(_every(4, 'week').isMaintenance, isTrue);
      expect(_every(30, 'day').isMaintenance, isTrue);
      expect(_every(2, 'week').isMaintenance, isFalse);
      expect(_every(3, 'day').isMaintenance, isFalse);
      expect(
        HomeTask(
          id: 't',
          homeId: 'h',
          title: 'x',
          recurrence: 'weekly',
        ).isMaintenance,
        isFalse,
      );
    });
  });

  group('Tipo mantenimiento por el título', () {
    test('caldera, filtros, ITV y colchón', () {
      for (final t in [
        'Revisar la caldera',
        'Limpiar los filtros',
        'Pasar la ITV',
        'Girar el colchón',
        'Boiler service',
        'Car inspection',
      ]) {
        expect(taskKindFor(t), TaskKind.mantenimiento, reason: t);
      }
    });

    test('no roba otras tareas', () {
      expect(taskKindFor('Limpiar el baño'), TaskKind.bano);
      expect(taskKindFor('Limpiar la nevera'), TaskKind.limpieza);
      expect(taskKindFor('Cargar el móvil'), isNot(TaskKind.mantenimiento));
    });

    test('las sugerencias son todas de un mes o más', () {
      for (final p in maintenancePresets) {
        expect(_every(p.count, p.unit).isMaintenance, isTrue, reason: p.key);
      }
    });
  });
}
