import '../models/task.dart';

/// Tipos de línea de "Tu día" en Inicio.
enum DayLineKind {
  defrost,
  defrostTomorrow,
  expiring,
  task,
  overdue,
  moreTasks,
  expired,
  shopping,
}

/// Una línea accionable de "Tu día": lo que toca hoy, ya decidido.
class DayLine {
  const DayLine(
    this.kind, {
    this.names = const [],
    this.count = 0,
    this.task,
    this.tasks = const [],
  });

  final DayLineKind kind;

  /// Nombres a mostrar (platos que descongelar, productos que caducan).
  final List<String> names;

  /// Cantidad a la que se refiere la línea (tareas de más, productos…).
  final int count;

  /// La tarea, en las líneas de tipo [DayLineKind.task].
  final HomeTask? task;

  /// Las tareas atrasadas, en la línea [DayLineKind.overdue].
  final List<HomeTask> tasks;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monta "Tu día" por urgencia: descongelar (y, por la noche, lo de mañana),
/// lo que caduca, las tareas de hoy y sin fecha (hasta [maxTasks]), las
/// atrasadas, lo ya caducado y la compra pendiente. Dos o más atrasadas van
/// juntas en una línea para ponerse al día de golpe, no una pared de tareas.
/// Lista vacía = la casa está al día.
List<DayLine> buildDayBrief({
  required DateTime today,
  List<String> defrost = const [],
  List<String> defrostTomorrow = const [],
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

  final overdue = [
    for (final t in tasks)
      if (rank(t) == 1) t,
  ];
  final collapse = overdue.length >= 2;
  final sorted =
      [
        for (final t in tasks)
          if (!collapse || rank(t) != 1) t,
      ]..sort((a, b) {
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
    if (defrostTomorrow.isNotEmpty)
      DayLine(DayLineKind.defrostTomorrow, names: defrostTomorrow),
    if (expiring.isNotEmpty)
      DayLine(
        DayLineKind.expiring,
        names: expiring.take(2).toList(),
        count: expiring.length,
      ),
    for (final t in sorted.take(maxTasks)) DayLine(DayLineKind.task, task: t),
    if (sorted.length > maxTasks)
      DayLine(DayLineKind.moreTasks, count: sorted.length - maxTasks),
    if (collapse)
      DayLine(DayLineKind.overdue, count: overdue.length, tasks: overdue),
    if (expired > 0) DayLine(DayLineKind.expired, count: expired),
    if (shopping > 0) DayLine(DayLineKind.shopping, count: shopping),
  ];
}

/// "Ponerme al día": nuevas fechas para las tareas atrasadas, repartidas
/// [perDay] por día desde hoy, las más antiguas primero. Las que se repiten
/// siguen su ritmo desde que se hagan.
Map<String, DateTime> spreadOverdue(
  List<HomeTask> overdue,
  DateTime today, {
  int perDay = 2,
}) {
  final sorted = [...overdue]
    ..sort((a, b) {
      final da = a.nextDue ?? a.dueDate ?? today;
      final db = b.nextDue ?? b.dueDate ?? today;
      return da.compareTo(db);
    });
  final t0 = _day(today);
  return {
    for (final (i, t) in sorted.indexed)
      t.id: DateTime(t0.year, t0.month, t0.day + i ~/ perDay),
  };
}
