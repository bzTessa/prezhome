import '../models/task.dart';

/// Tipos de línea de "Tu día" en Inicio.
enum DayLineKind { defrost, expiring, task, moreTasks, expired, shopping }

/// Una línea accionable de "Tu día": lo que toca hoy, ya decidido.
class DayLine {
  const DayLine(this.kind, {this.names = const [], this.count = 0, this.task});

  final DayLineKind kind;

  /// Nombres a mostrar (platos que descongelar, productos que caducan).
  final List<String> names;

  /// Cantidad a la que se refiere la línea (tareas de más, productos…).
  final int count;

  /// La tarea, en las líneas de tipo [DayLineKind.task].
  final HomeTask? task;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monta "Tu día" por urgencia: descongelar, lo que caduca, hasta [maxTasks]
/// tareas (las de hoy antes que las atrasadas, las atrasadas más recientes
/// primero, las sin fecha al final), lo ya caducado y la compra pendiente.
/// Lista vacía = la casa está al día.
List<DayLine> buildDayBrief({
  required DateTime today,
  List<String> defrost = const [],
  List<String> expiring = const [],
  int expired = 0,
  List<HomeTask> tasks = const [],
  int shopping = 0,
  int maxTasks = 3,
}) {
  final t0 = _day(today);
  int rank(HomeTask t) {
    final due = t.nextDue ?? t.dueDate;
    if (due == null) return 2;
    return _day(due) == t0 ? 0 : 1;
  }

  final sorted = [...tasks]
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final da = a.nextDue ?? a.dueDate;
      final db = b.nextDue ?? b.dueDate;
      if (da == null || db == null) return 0;
      // Hoy: por hora de la fecha; atrasadas: la más reciente primero.
      return rank(a) == 0 ? da.compareTo(db) : db.compareTo(da);
    });
  return [
    if (defrost.isNotEmpty) DayLine(DayLineKind.defrost, names: defrost),
    if (expiring.isNotEmpty)
      DayLine(
        DayLineKind.expiring,
        names: expiring.take(2).toList(),
        count: expiring.length,
      ),
    for (final t in sorted.take(maxTasks)) DayLine(DayLineKind.task, task: t),
    if (sorted.length > maxTasks)
      DayLine(DayLineKind.moreTasks, count: sorted.length - maxTasks),
    if (expired > 0) DayLine(DayLineKind.expired, count: expired),
    if (shopping > 0) DayLine(DayLineKind.shopping, count: shopping),
  ];
}
