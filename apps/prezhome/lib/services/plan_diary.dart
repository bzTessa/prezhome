import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_prefs.dart';
import '../models/food_log_entry.dart';
import '../models/meal_plan_entry.dart';
import '../models/nutrition_profile.dart';
import 'file_local_store.dart';
import 'plan_prefs.dart';

/// Apunta en el diario de calorías las comidas del plan que ya han pasado.
///
/// Cada comida se apunta una sola vez: se recuerda en el dispositivo hasta
/// cuándo se ha apuntado, así lo que la persona borre del diario no vuelve.
class PlanDiary {
  /// Cada comida se da por comida dos horas y media después de su hora.
  static const _doneAfter = 150;

  /// Comidas de [entries] que pasaron entre [since] (excluido) y [now], con
  /// receta, sin saltar y que [me] come en casa.
  static List<MealPlanEntry> passed(
    List<MealPlanEntry> entries,
    NutritionProfile me,
    DateTime since,
    DateTime now, {
    PlanPrefs prefs = const PlanPrefs(),
  }) {
    bool due(MealPlanEntry e) {
      final at = DateTime(
        e.date.year,
        e.date.month,
        e.date.day,
        0,
        prefs.minutesOf(e.mealType) + _doneAfter,
      );
      return at.isAfter(since) && !at.isAfter(now);
    }

    return [
      for (final e in entries)
        if (!e.skipped &&
            e.recipeId != null &&
            me.eatsAtHome(e.mealType, e.date.weekday) &&
            due(e))
          e,
    ];
  }

  static final _store = FileLocalStore(folderName: 'settings');
  static Future<int>? _running;

  /// Apunta lo que falte. Devuelve cuántas comidas se apuntaron. No lanza.
  static Future<int> sync(SupabaseClient client) =>
      _running ??= _sync(client).whenComplete(() => _running = null);

  static Future<int> _sync(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final key = 'plan_diary_until:${user.id}';
    final now = DateTime.now();
    String day(DateTime d) => d.toIso8601String().split('T').first;
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final homeId = row?['home_id'] as String?;
      final rawPrefs = row?['dashboard_prefs'];
      final prefs = rawPrefs is Map
          ? DashboardPrefs.fromJson(Map<String, dynamic>.from(rawPrefs))
          : DashboardPrefs.defaults();
      var added = 0;
      if (homeId != null && prefs.trackCalories) {
        // La primera vez se empieza por hoy; nunca más de una semana atrás.
        final today = DateTime(now.year, now.month, now.day);
        final weekAgo = today.subtract(const Duration(days: 7));
        var since = DateTime.tryParse(await _store.read(key) ?? '') ?? today;
        if (since.isBefore(weekAgo)) since = weekAgo;

        final planRes = await client
            .from('meal_plan_entries')
            .select()
            .eq('home_id', homeId)
            .gte('plan_date', day(since))
            .lte('plan_date', day(now));
        final due = passed(
          [for (final m in planRes as List) MealPlanEntry.fromMap(m)],
          NutritionProfile.fromMap(row!),
          since,
          now,
          prefs: PlanPrefs.current.value,
        );
        if (due.isNotEmpty) added = await _log(client, user.id, due, since);
      }
      await _store.write(key, now.toIso8601String());
      return added;
    } catch (e) {
      debugPrint('PlanDiary.sync error: $e');
      return 0;
    }
  }

  static Future<int> _log(
    SupabaseClient client,
    String userId,
    List<MealPlanEntry> due,
    DateTime since,
  ) async {
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final recRes = await client
        .from('recipes')
        .select('id, title, calories, protein, carbs, fat')
        .inFilter('id', due.map((e) => e.recipeId!).toSet().toList());
    final recipes = {for (final r in recRes as List) r['id'] as String: r};
    // Lo que ya está en el diario (otro móvil, o apuntado a mano).
    final logged = await client
        .from('food_log_entries')
        .select('log_date, meal_type, recipe_id')
        .eq('user_id', userId)
        .gte('log_date', day(since));
    final seen = {
      for (final l in logged as List)
        '${l['log_date']}|${l['meal_type']}|${l['recipe_id']}',
    };
    double? n(Object? v) => (v as num?)?.toDouble();
    final rows = <Map<String, dynamic>>[];
    for (final e in due) {
      final r = recipes[e.recipeId];
      if (r == null || r['calories'] == null) continue;
      if (seen.contains('${day(e.date)}|${e.mealType}|${e.recipeId}')) continue;
      rows.add(
        FoodLogEntry(
          userId: userId,
          logDate: e.date,
          mealType: e.mealType,
          name: r['title'] as String? ?? '',
          calories: n(r['calories']),
          protein: n(r['protein']),
          carbs: n(r['carbs']),
          fat: n(r['fat']),
          source: 'receta',
          recipeId: e.recipeId,
        ).toInsertMap(),
      );
    }
    if (rows.isNotEmpty) await client.from('food_log_entries').insert(rows);
    return rows.length;
  }
}
