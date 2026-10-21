import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Racha de "casa al día": días seguidos en los que la persona hizo algo útil
/// (tachar una tarea o apuntar una comida, también las del plan que se
/// apuntan solas al abrir la app). Abrir la app sin más no cuenta.
///
/// Se calcula con lo que ya hay en task_points y food_log_entries, sin tabla
/// propia.
class Streak {
  const Streak({required this.days, required this.doneToday});

  /// Días seguidos, contando los de descanso que la guardaron.
  final int days;

  /// Si hoy ya cuenta (si no, la racha sigue viva hasta que acabe el día).
  final bool doneToday;

  static const milestones = [3, 7, 14, 30, 100];

  /// Hoy se alcanza un hito.
  bool get milestoneToday => doneToday && milestones.contains(days);

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Racha a partir de los días con actividad. Un día sin nada por semana
  /// (lunes a domingo) se perdona solo, para que un mal día no la rompa.
  static Streak count(Set<DateTime> active, DateTime now) {
    final days = {for (final d in active) _date(d)};
    final today = _date(now);
    final doneToday = days.contains(today);
    // Hoy aún no se ha acabado: si falta, se empieza a contar por ayer.
    var day = doneToday ? today : today.subtract(const Duration(days: 1));
    var count = 0;
    final forgivenWeeks = <DateTime>{};
    while (true) {
      if (days.contains(day)) {
        count++;
      } else {
        final monday = day.subtract(Duration(days: day.weekday - 1));
        final before = day.subtract(const Duration(days: 1));
        // Solo se perdona un hueco entre días con actividad.
        if (count == 0 ||
            !days.contains(before) ||
            !forgivenWeeks.add(monday)) {
          break;
        }
        count++;
      }
      day = day.subtract(const Duration(days: 1));
    }
    return Streak(days: count, doneToday: doneToday);
  }

  /// Lee la actividad de los últimos 120 días. Null si falla o no hay sesión.
  static Future<Streak?> load(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final since = DateTime.now()
        .subtract(const Duration(days: 120))
        .toUtc()
        .toIso8601String();
    try {
      final tasks = await client
          .from('task_points')
          .select('created_at')
          .eq('user_id', user.id)
          .gte('created_at', since);
      final meals = await client
          .from('food_log_entries')
          .select('created_at')
          .eq('user_id', user.id)
          .gte('created_at', since);
      return count({
        for (final r in [...tasks as List, ...meals as List])
          DateTime.parse(r['created_at'] as String).toLocal(),
      }, DateTime.now());
    } catch (e) {
      debugPrint('Streak.load error: $e');
      return null;
    }
  }
}
