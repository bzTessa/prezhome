import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lo que la casa ha conseguido este mes con la app: comida aprovechada antes
/// de caducar, lo que se ha tirado (y si es menos que el mes pasado), comidas
/// hechas en casa según el plan y tareas hechas.
class MonthWins {
  const MonthWins({
    this.rescued = 0,
    this.thrown = 0,
    this.thrownLastMonth = 0,
    this.mealsAtHome = 0,
    this.tasksDone = 0,
  });

  final int rescued;
  final int thrown;
  final int thrownLastMonth;
  final int mealsAtHome;
  final int tasksDone;

  bool get isEmpty =>
      rescued == 0 && thrown == 0 && mealsAtHome == 0 && tasksDone == 0;

  /// Cuántos productos menos se han tirado que el mes pasado (0 si no hay
  /// mejora).
  int get thrownLess => thrownLastMonth > thrown ? thrownLastMonth - thrown : 0;

  /// Cuenta a partir de las filas de `pantry_log` (reason, rescued, used_on)
  /// de este mes y el anterior, las fechas de comidas no saltadas del plan
  /// hasta hoy y las tareas hechas este mes.
  factory MonthWins.fromRows({
    required Iterable<Map<String, dynamic>> pantryLog,
    required Iterable<Map<String, dynamic>> meals,
    required int tasksDone,
    required DateTime now,
  }) {
    final monthStart = DateTime(now.year, now.month);
    var rescued = 0, thrown = 0, thrownBefore = 0;
    for (final r in pantryLog) {
      final day = DateTime.tryParse('${r['used_on']}');
      if (day == null) continue;
      final thisMonth = !day.isBefore(monthStart);
      if (r['reason'] == 'tirado') {
        thisMonth ? thrown++ : thrownBefore++;
      } else if (thisMonth && r['rescued'] == true) {
        rescued++;
      }
    }
    final today = DateTime(now.year, now.month, now.day);
    var mealsAtHome = 0;
    for (final m in meals) {
      final day = DateTime.tryParse('${m['plan_date']}');
      if (day == null || m['skipped'] == true) continue;
      if (!day.isBefore(monthStart) && !day.isAfter(today)) mealsAtHome++;
    }
    return MonthWins(
      rescued: rescued,
      thrown: thrown,
      thrownLastMonth: thrownBefore,
      mealsAtHome: mealsAtHome,
      tasksDone: tasksDone,
    );
  }

  /// Lo de este hogar (el RLS ya limita cada tabla al hogar de la persona).
  /// Si algo falla devuelve vacío: es un resumen, no debe romper la pantalla.
  static Future<MonthWins> load(SupabaseClient client, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final monthStart = DateTime(n.year, n.month);
    final lastMonth = DateTime(n.year, n.month - 1);
    try {
      final user = client.auth.currentUser;
      if (user == null) return const MonthWins();
      final profile = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return const MonthWins();
      final res = await Future.wait<List<Map<String, dynamic>>>([
        client
            .from('pantry_log')
            .select('reason, rescued, used_on')
            .eq('home_id', homeId)
            .gte('used_on', day(lastMonth)),
        client
            .from('meal_plan_entries')
            .select('plan_date, skipped')
            .eq('home_id', homeId)
            .gte('plan_date', day(monthStart))
            .lte('plan_date', day(n)),
        client
            .from('task_points')
            .select('id')
            .eq('home_id', homeId)
            .gt('points', 0)
            .gte('created_at', day(monthStart)),
      ]);
      return MonthWins.fromRows(
        pantryLog: res[0],
        meals: res[1],
        tasksDone: res[2].length,
        now: n,
      );
    } catch (e) {
      debugPrint('month_wins: $e');
      return const MonthWins();
    }
  }
}
