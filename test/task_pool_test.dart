import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/services/task_scheduler.dart';

/// Mapa minimo de una fila de tareas tal cual la devuelve Supabase, al que
/// podemos ir anadiendo/quitando claves por caso de prueba.
Map<String, dynamic> _row({int? points, Object? effortPoints = _absent}) {
  final map = <String, dynamic>{
    'id': 't',
    'home_id': 'h',
    'title': 'Prueba',
    'points': points ?? 10,
    'recurrence': 'once',
  };
  // Solo incluimos effort_points cuando el caso lo pide, para simular filas
  // antiguas que no tienen la columna.
  if (!identical(effortPoints, _absent)) {
    map['effort_points'] = effortPoints;
  }
  return map;
}

/// Centinela para distinguir "clave ausente" de "clave con valor null".
const Object _absent = Object();

void main() {
  group('HomeTask.effortPoints', () {
    test('fromMap cae a points cuando falta la columna effort_points', () {
      // Fila antigua: no trae 'effort_points'.
      final task = HomeTask.fromMap(_row(points: 25));
      expect(task.effortPoints, 25);
    });

    test('fromMap cae a 10 cuando faltan effort_points y points', () {
      final map = _row()..remove('points');
      final task = HomeTask.fromMap(map);
      expect(task.points, 10);
      expect(task.effortPoints, 10);
    });

    test('fromMap lee un effort_points explicito', () {
      final task = HomeTask.fromMap(_row(points: 10, effortPoints: 40));
      expect(task.effortPoints, 40);
    });

    test('toInsertMap incluye effort_points', () {
      final task = HomeTask(
        id: 't',
        homeId: 'h',
        title: 'Prueba',
        effortPoints: 30,
      );
      final map = task.toInsertMap(createdBy: 'u');
      expect(map['effort_points'], 30);
    });

    test('constructor usa 10 por defecto en effortPoints', () {
      final task = HomeTask(id: 't', homeId: 'h', title: 'Prueba');
      expect(task.effortPoints, 10);
    });
  });

  group('HomeTask.rescheduleMap (recurrentes)', () {
    final next = DateTime(2026, 1, 15);

    test('avanza la fecha y deja la tarea pendiente, con quien la hizo', () {
      // Al completar una recurrente se reprograma a la proxima fecha, se marca
      // quien la hizo (completed_by) y queda is_done=false para reaparecer.
      final map = HomeTask.rescheduleMap(next: next, completedBy: 'u1');
      expect(map['is_done'], isFalse);
      expect(map['completed_by'], 'u1');
      expect(map['next_due'], '2026-01-15');
    });

    test('NO toca assigned_to al reprogramar', () {
      // El rediseno elimina la Bolsa Comun; reprogramar nunca reasigna.
      final map = HomeTask.rescheduleMap(next: next, completedBy: 'u1');
      expect(map.containsKey('assigned_to'), isFalse);
    });

    test('completeOnceMap marca hecha y atribuye a quien la hizo', () {
      final map = HomeTask.completeOnceMap(completedBy: 'u1');
      expect(map.containsKey('assigned_to'), isFalse);
      expect(map['is_done'], isTrue);
      expect(map['completed_by'], 'u1');
    });
  });

  group('PointsBalance.forUser', () {
    test('saldo = ganados - canjeados', () {
      expect(PointsBalance.forUser(earned: 100, redeemed: 30), 70);
    });

    test('saldo cero cuando ganados == canjeados', () {
      expect(PointsBalance.forUser(earned: 50, redeemed: 50), 0);
    });

    test('clampa a 0 cuando lo canjeado supera lo ganado', () {
      expect(PointsBalance.forUser(earned: 20, redeemed: 80), 0);
    });

    test('saldo igual a lo ganado cuando no hay canjes', () {
      expect(PointsBalance.forUser(earned: 45, redeemed: 0), 45);
    });
  });
}
