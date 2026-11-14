import '../models/task.dart';

/// Lunes a las 00:00 de la semana de [now], en hora local.
DateTime startOfWeek(DateTime now) {
  final d = DateTime(now.year, now.month, now.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Suma los puntos de cada persona desde [since]. Cada fila trae user_id,
/// points y created_at, como las de task_points.
Map<String, int> pointsSince(List<Map<String, dynamic>> rows, DateTime since) {
  final out = <String, int>{};
  for (final r in rows) {
    final at = DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal();
    if (at == null || at.isBefore(since)) continue;
    final uid = r['user_id'] as String;
    out[uid] = (out[uid] ?? 0) + (r['points'] as int);
  }
  return out;
}

/// Agrupa las tareas por persona: primero las de [me], luego las del resto
/// de miembros en el orden de [members] y al final las sin asignar (clave
/// null). Solo devuelve grupos con tareas.
List<MapEntry<String?, List<HomeTask>>> groupByPerson(
  List<HomeTask> tasks,
  String? me,
  Map<String, String> members,
) {
  final order = <String?>[?me, ...members.keys.where((id) => id != me), null];
  final groups = <String?, List<HomeTask>>{for (final id in order) id: []};
  for (final t in tasks) {
    final key = members.containsKey(t.assignedTo) ? t.assignedTo : null;
    groups[key]!.add(t);
  }
  return [
    for (final id in order)
      if (groups[id]!.isNotEmpty) MapEntry(id, groups[id]!),
  ];
}

/// "Ponerme al día": nueva fecha para cada tarea atrasada, sin marcarla como
/// hecha ni dar puntos. Las que se repiten saltan a su próxima vez desde hoy
/// (una diaria vuelve a hoy) y las puntuales pasan a hoy.
Map<String, DateTime> catchUpDates(List<HomeTask> overdue, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  return {
    for (final t in overdue)
      t.id: t.recurrence == 'once'
          ? today
          : (t.computeNextDue(yesterday) ?? today),
  };
}
