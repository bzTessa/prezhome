import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

/// Logica compartida de completar/reprogramar tareas, reutilizada por la
/// pantalla de Tareas y por el Dashboard de Inicio para no duplicar el flujo:
///   1. Registra los puntos ganados en task_points (historial del marcador).
///   2. Si la tarea es 'once' (o recurrente sin proxima fecha calculable) la
///      marca como hecha (is_done=true).
///   3. Si es recurrente, avanza due_date/next_due a la proxima ocurrencia
///      (computeNextDue) y la deja is_done=false, de modo que DESAPARECE de hoy
///      y REAPARECE cuando toque.
///
/// Puro en terminos de UI (no toca context ni setState): quien lo llama se
/// encarga de refrescar su vista despues.
class TaskScheduler {
  final SupabaseClient _client;
  TaskScheduler(this._client);

  /// Completa [task] a nombre del usuario actual. Lanza si no hay sesion para
  /// que quien llama lo capture en su propio try/catch.
  Future<void> complete(HomeTask task) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';

    // 1. Puntos ganados (igual que antes).
    await _client.from('task_points').insert({
      'home_id': task.homeId,
      'user_id': user.id,
      'points': task.points,
      'task_id': task.id,
    });

    // 2/3. Reprogramacion segun recurrencia.
    if (task.recurrence == 'once') {
      await _client
          .from('tasks')
          .update(HomeTask.completeOnceMap(completedBy: user.id))
          .eq('id', task.id);
      return;
    }

    final next = task.computeNextDue(DateTime.now());
    if (next == null) {
      await _client
          .from('tasks')
          .update(HomeTask.completeOnceMap(completedBy: user.id))
          .eq('id', task.id);
    } else {
      await _client
          .from('tasks')
          .update(HomeTask.rescheduleMap(next: next, completedBy: user.id))
          .eq('id', task.id);
    }
  }
}

/// Proyeccion EN CLIENTE de las ocurrencias de una tarea dentro de un rango de
/// fechas [from, to] (ambos inclusive, normalizados a dia). No materializa nada
/// en la base de datos: calcula las apariciones futuras de las recurrentes a
/// partir de su proxima fecha (next_due/due_date) aplicando computeNextDue en
/// cadena. Lo usa el calendario mensual para pintar las tareas por dia.
class TaskOccurrences {
  /// Devuelve las fechas (normalizadas) en las que [task] aparece dentro de
  /// [from]..[to]. Para 'once' es como mucho una fecha; para recurrentes puede
  /// ser varias. Las tareas ya completadas puntuales (is_done) no aparecen.
  static List<DateTime> inRange(HomeTask task, DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final result = <DateTime>[];

    // Fecha base de la que parte la tarea: su proxima aparicion conocida.
    final anchor = task.nextDue ?? task.dueDate;

    if (task.recurrence == 'once') {
      if (task.isDone || anchor == null) return result;
      final d = DateTime(anchor.year, anchor.month, anchor.day);
      if (!d.isBefore(start) && !d.isAfter(end)) result.add(d);
      return result;
    }

    // Recurrentes: partimos del anchor (o de start si no hay) y encadenamos
    // computeNextDue hasta pasar el final del rango. Tope de seguridad para no
    // iterar sin fin ante datos raros.
    var cursor = anchor == null
        ? start
        : DateTime(anchor.year, anchor.month, anchor.day);

    // Si el anchor es anterior al rango, avanzamos hasta entrar en el.
    var guard = 0;
    while (cursor.isBefore(start) && guard < 1000) {
      final nxt = task.computeNextDue(cursor);
      if (nxt == null) break;
      cursor = nxt;
      guard++;
    }

    guard = 0;
    while (!cursor.isAfter(end) && guard < 1000) {
      if (!cursor.isBefore(start)) result.add(cursor);
      final nxt = task.computeNextDue(cursor);
      if (nxt == null) break;
      cursor = nxt;
      guard++;
    }
    return result;
  }
}
