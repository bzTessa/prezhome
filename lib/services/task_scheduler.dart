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
  ///
  /// Comportamiento OBSERVABLE sin cambios respecto a versiones anteriores: el
  /// Dashboard de Inicio depende de este flujo (inserta en task_points y
  /// reprograma/completa la tarea).
  Future<void> complete(HomeTask task) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';
    await _awardAndReschedule(task, user.id);
  }

  /// Flujo "Yo me encargo" de la Bolsa Comun: el usuario reclama una tarea sin
  /// asignar y la completa en el mismo gesto. Primero fija assigned_to al
  /// usuario actual (la tarea deja de estar en el pool y pasa a ser suya) y
  /// despues reutiliza EXACTAMENTE la misma logica de puntos + reprogramacion
  /// que complete(), sin duplicarla.
  Future<void> claimAndComplete(HomeTask task) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';

    // La tarea deja de estar en la Bolsa Comun: queda asignada al que la
    // reclama antes de registrar los puntos.
    await _client
        .from('tasks')
        .update({'assigned_to': user.id})
        .eq('id', task.id);

    await _awardAndReschedule(task, user.id);
  }

  /// Paso compartido por complete() y claimAndComplete(): registra los puntos
  /// ganados y reprograma/completa la tarea segun su recurrencia. Se mantiene
  /// como helper privado para no duplicar el flujo y para que complete()
  /// conserve su comportamiento exacto.
  ///
  /// Los puntos del marcador salen de [HomeTask.points] (puntuacion existente,
  /// sin cambios). El campo effort_points es solo informativo por ahora y no
  /// participa en el calculo del marcador.
  Future<void> _awardAndReschedule(HomeTask task, String userId) async {
    // 1. Puntos ganados (igual que antes).
    await _client.from('task_points').insert({
      'home_id': task.homeId,
      'user_id': userId,
      'points': task.points,
      'task_id': task.id,
    });

    // 2/3. Reprogramacion segun recurrencia.
    if (task.recurrence == 'once') {
      await _client
          .from('tasks')
          .update(HomeTask.completeOnceMap(completedBy: userId))
          .eq('id', task.id);
      return;
    }

    final next = task.computeNextDue(DateTime.now());
    if (next == null) {
      await _client
          .from('tasks')
          .update(HomeTask.completeOnceMap(completedBy: userId))
          .eq('id', task.id);
    } else {
      await _client
          .from('tasks')
          .update(HomeTask.rescheduleMap(next: next, completedBy: userId))
          .eq('id', task.id);
    }
  }
}

/// Calculo PURO del saldo de puntos de un miembro para el Marketplace de
/// Recompensas. Sin dependencias de Supabase ni Flutter para que la UI y los
/// tests compartan la misma formula y sea trivialmente testeable.
///
/// - earned   = suma de task_points.points del usuario en el hogar.
/// - redeemed = suma de reward_redemptions.cost_points del usuario en el hogar.
///
/// El saldo disponible es earned - redeemed, con un suelo en 0 para no mostrar
/// nunca saldos negativos en la balanza.
class PointsBalance {
  const PointsBalance._();

  /// Saldo disponible = ganados - canjeados, nunca por debajo de 0.
  static int forUser({required int earned, required int redeemed}) {
    final balance = earned - redeemed;
    return balance < 0 ? 0 : balance;
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
