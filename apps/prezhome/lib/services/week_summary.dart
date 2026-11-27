import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/ticket_date.dart';
import 'file_local_store.dart';

/// Resumen de la semana en casa (lunes a domingo): comidas hechas en casa,
/// gasto en tickets, comida aprovechada y tirada (con la semana anterior para
/// comparar) y tareas hechas. Se enseña en Hoy el domingo y el lunes.
class WeekSummary {
  const WeekSummary({
    required this.weekStart,
    this.mealsAtHome = 0,
    this.spent = 0,
    this.rescued = 0,
    this.thrown = 0,
    this.thrownBefore = 0,
    this.tasksDone = 0,
  });

  final DateTime weekStart;
  final int mealsAtHome;
  final double spent;
  final int rescued;
  final int thrown;
  final int thrownBefore;
  final int tasksDone;

  bool get isEmpty =>
      mealsAtHome == 0 &&
      spent == 0 &&
      rescued == 0 &&
      thrown == 0 &&
      tasksDone == 0;

  /// Cuántas cosas menos se han tirado que la semana anterior (0 si no).
  int get thrownLess => thrownBefore > thrown ? thrownBefore - thrown : 0;

  /// El domingo, esta semana; el lunes, la que acaba de terminar; el resto
  /// de días no hay resumen.
  static DateTime? weekFor(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (now.weekday == DateTime.sunday) {
      return today.subtract(const Duration(days: 6));
    }
    if (now.weekday == DateTime.monday) {
      return today.subtract(const Duration(days: 7));
    }
    return null;
  }

  factory WeekSummary.fromRows({
    required DateTime weekStart,
    required DateTime now,
    required Iterable<Map<String, dynamic>> meals,
    required Iterable<Map<String, dynamic>> tickets,
    required Iterable<Map<String, dynamic>> pantryLog,
    required int tasksDone,
  }) {
    final end = weekStart.add(const Duration(days: 7));
    final prevStart = weekStart.subtract(const Duration(days: 7));
    final today = DateTime(now.year, now.month, now.day);
    bool inWeek(DateTime d) => !d.isBefore(weekStart) && d.isBefore(end);
    var meals0 = 0;
    for (final m in meals) {
      final d = DateTime.tryParse('${m['plan_date']}');
      if (d == null || m['skipped'] == true || d.isAfter(today)) continue;
      if (inWeek(d)) meals0++;
    }
    var spent = 0.0;
    for (final t in tickets) {
      spent += (t['total_amount'] as num?)?.toDouble() ?? 0;
    }
    var rescued = 0, thrown = 0, thrownBefore = 0;
    for (final r in pantryLog) {
      final d = DateTime.tryParse('${r['used_on']}');
      if (d == null) continue;
      if (r['reason'] == 'tirado') {
        if (inWeek(d)) {
          thrown++;
        } else if (!d.isBefore(prevStart) && d.isBefore(weekStart)) {
          thrownBefore++;
        }
      } else if (inWeek(d) && r['rescued'] == true) {
        rescued++;
      }
    }
    return WeekSummary(
      weekStart: weekStart,
      mealsAtHome: meals0,
      spent: spent,
      rescued: rescued,
      thrown: thrown,
      thrownBefore: thrownBefore,
      tasksDone: tasksDone,
    );
  }

  static final _settings = FileLocalStore(folderName: 'settings');
  static const _dismissKey = 'week_summary_dismissed';
  static String _day(DateTime d) => d.toIso8601String().split('T').first;

  static Future<void> dismiss(DateTime weekStart) async {
    try {
      await _settings.write(_dismissKey, _day(weekStart));
    } catch (_) {}
  }

  /// null si hoy no toca, si ya se cerró esta semana o si falla algo: es un
  /// resumen y no debe romper Hoy.
  static Future<WeekSummary?> load(
    SupabaseClient client,
    String homeId, {
    DateTime? now,
  }) async {
    final n = now ?? DateTime.now();
    final start = weekFor(n);
    if (start == null) return null;
    try {
      if (await _settings.read(_dismissKey) == _day(start)) return null;
    } catch (_) {}
    final end = start.add(const Duration(days: 7));
    final prev = start.subtract(const Duration(days: 7));
    try {
      final res = await Future.wait<List<Map<String, dynamic>>>([
        client
            .from('meal_plan_entries')
            .select('plan_date, skipped')
            .eq('home_id', homeId)
            .gte('plan_date', _day(start))
            .lt('plan_date', _day(end)),
        client
            .from('tickets')
            .select('total_amount')
            .eq('home_id', homeId)
            .or(ticketRangeFilter(start, end)),
        client
            .from('pantry_log')
            .select('reason, rescued, used_on')
            .eq('home_id', homeId)
            .gte('used_on', _day(prev))
            .lt('used_on', _day(end)),
        client
            .from('task_points')
            .select('id')
            .eq('home_id', homeId)
            .gt('points', 0)
            .gte('created_at', _day(start))
            .lt('created_at', _day(end)),
      ]);
      final s = WeekSummary.fromRows(
        weekStart: start,
        now: n,
        meals: res[0],
        tickets: res[1],
        pantryLog: res[2],
        tasksDone: res[3].length,
      );
      return s.isEmpty ? null : s;
    } catch (e) {
      debugPrint('week_summary: $e');
      return null;
    }
  }
}
