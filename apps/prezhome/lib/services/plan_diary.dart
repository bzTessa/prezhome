import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_prefs.dart';
import '../models/food_log_entry.dart';
import '../models/meal_plan_entry.dart';
import '../models/nutrition_profile.dart';
import 'file_local_store.dart';
import 'plan_prefs.dart';

/// Apunta en el diario de calorías las comidas del plan que ya han pasado,
/// o pregunta antes si la persona lo prefiere ([DashboardPrefs.askMeals]).
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

  /// Con "preguntarme" activo: comidas pasadas esperando un sí o un no.
  static final asked = ValueNotifier<List<FoodLogEntry>>(const []);

  static String _day(DateTime d) => d.toIso8601String().split('T').first;
  static String _keyOf(FoodLogEntry e) =>
      '${_day(e.logDate)}|${e.mealType}|${e.recipeId}';

  /// Apunta lo que falte (o lo deja en [asked]). Devuelve cuántas comidas se
  /// apuntaron. No lanza.
  static Future<int> sync(SupabaseClient client) =>
      _running ??= _sync(client).whenComplete(() => _running = null);

  static Future<int> _sync(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final key = 'plan_diary_until:${user.id}';
    final now = DateTime.now();
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
      var pending = const <FoodLogEntry>[];
      if (homeId != null && prefs.trackCalories) {
        // La primera vez se empieza por hoy; nunca más de una semana atrás.
        final today = DateTime(now.year, now.month, now.day);
        final weekAgo = today.subtract(const Duration(days: 7));
        var since = DateTime.tryParse(await _store.read(key) ?? '') ?? today;
        if (since.isBefore(weekAgo)) since = weekAgo;
        // Al preguntar, lo de ayer y hoy sigue en pie hasta que responda.
        if (prefs.askMeals) since = today.subtract(const Duration(days: 1));

        final planRes = await client
            .from('meal_plan_entries')
            .select()
            .eq('home_id', homeId)
            .gte('plan_date', _day(since))
            .lte('plan_date', _day(now));
        final due = passed(
          [for (final m in planRes as List) MealPlanEntry.fromMap(m)],
          NutritionProfile.fromMap(row!),
          since,
          now,
          prefs: PlanPrefs.current.value,
        );
        final rows = due.isEmpty
            ? const <FoodLogEntry>[]
            : await _missing(client, user.id, due, since);
        if (prefs.askMeals) {
          final no = await _answeredNo(user.id);
          pending = [
            for (final e in rows)
              if (!no.contains(_keyOf(e))) e,
          ];
        } else if (rows.isNotEmpty) {
          await client.from('food_log_entries').insert([
            for (final e in rows) e.toInsertMap(),
          ]);
          added = rows.length;
        }
      }
      asked.value = pending;
      await _store.write(key, now.toIso8601String());
      return added;
    } catch (e) {
      debugPrint('PlanDiary.sync error: $e');
      return 0;
    }
  }

  /// Respuesta a "¿Has comido X?": sí lo apunta, no lo recuerda para no
  /// volver a preguntar.
  static Future<void> answer(
    SupabaseClient client,
    FoodLogEntry e, {
    required bool ate,
  }) async {
    if (ate) {
      await client.from('food_log_entries').insert(e.toInsertMap());
    } else {
      final no = await _answeredNo(e.userId)
        ..add(_keyOf(e));
      // shortcut: la lista crece sin podar; podar por fecha si llega a pesar.
      await _store.write('plan_diary_no:${e.userId}', jsonEncode(no.toList()));
    }
    asked.value = [
      for (final p in asked.value)
        if (_keyOf(p) != _keyOf(e)) p,
    ];
  }

  static Future<Set<String>> _answeredNo(String userId) async {
    final raw = await _store.read('plan_diary_no:$userId');
    return raw == null ? <String>{} : {...(jsonDecode(raw) as List).cast()};
  }

  /// Entradas del diario para [due] que aún no están apuntadas.
  static Future<List<FoodLogEntry>> _missing(
    SupabaseClient client,
    String userId,
    List<MealPlanEntry> due,
    DateTime since,
  ) async {
    final recRes = await client
        .from('recipes')
        .select(
          'id, title, calories_per_serving, protein_grams, carbs_grams, '
          'fat_grams',
        )
        .inFilter('id', due.map((e) => e.recipeId!).toSet().toList());
    final recipes = {for (final r in recRes as List) r['id'] as String: r};
    // Lo que ya está en el diario (otro móvil, o apuntado a mano).
    final logged = await client
        .from('food_log_entries')
        .select('log_date, meal_type, recipe_id')
        .eq('user_id', userId)
        .gte('log_date', _day(since));
    final seen = {
      for (final l in logged as List)
        '${l['log_date']}|${l['meal_type']}|${l['recipe_id']}',
    };
    double? n(Object? v) => (v as num?)?.toDouble();
    return [
      for (final e in due)
        if (recipes[e.recipeId] case final r?
            when r['calories_per_serving'] != null &&
                !seen.contains('${_day(e.date)}|${e.mealType}|${e.recipeId}'))
          FoodLogEntry(
            userId: userId,
            logDate: e.date,
            mealType: e.mealType,
            name: r['title'] as String? ?? '',
            calories: n(r['calories_per_serving']),
            protein: n(r['protein_grams']),
            carbs: n(r['carbs_grams']),
            fat: n(r['fat_grams']),
            source: 'receta',
            recipeId: e.recipeId,
          ),
    ];
  }
}
