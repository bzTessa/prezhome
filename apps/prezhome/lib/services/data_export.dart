import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// "Descargar mis datos": todo lo del hogar y lo tuyo en un JSON legible,
/// para guardarlo o llevarlo a otra app. Solo lee; RLS limita lo que llega.
class DataExport {
  DataExport(this._client);
  final SupabaseClient _client;

  /// Tablas del hogar (filtradas por home_id).
  static const homeTables = [
    'recipes',
    'recipe_ingredients',
    'meal_plan_entries',
    'meal_plan_repeats',
    'ready_meals',
    'inventory_items',
    'pantry_log',
    'shopping_lists',
    'shopping_list_items',
    'tickets',
    'ticket_items',
    'budgets',
    'home_expenses',
    'tasks',
    'task_points',
    'home_people',
    'home_info',
    'inbox_notes',
  ];

  /// Tablas personales: RLS solo deja ver las propias.
  static const personalTables = ['food_log_entries', 'weight_entries'];

  static const _page = 1000;

  Future<List<Map<String, dynamic>>> _all(
    String table, {
    String? homeId,
  }) async {
    final out = <Map<String, dynamic>>[];
    for (var from = 0; ; from += _page) {
      var q = _client.from(table).select();
      if (homeId != null) q = q.eq('home_id', homeId);
      final rows = await q.range(from, from + _page - 1);
      out.addAll([for (final r in rows) Map<String, dynamic>.from(r)]);
      if (rows.length < _page) break;
    }
    return out;
  }

  /// Lee todo. Una tabla que falla queda como lista vacía y se apunta en
  /// "errors", así una sola no impide descargar el resto.
  Future<Map<String, dynamic>> collect(String homeId) async {
    final data = <String, dynamic>{};
    final errors = <String>[];
    Future<void> grab(String t, {String? homeId}) async {
      try {
        data[t] = await _all(t, homeId: homeId);
      } catch (_) {
        data[t] = const [];
        errors.add(t);
      }
    }

    await Future.wait([
      for (final t in homeTables) grab(t, homeId: homeId),
      for (final t in personalTables) grab(t),
    ]);
    final uid = _client.auth.currentUser?.id;
    try {
      data['home'] = await _client
          .from('homes')
          .select()
          .eq('id', homeId)
          .maybeSingle();
      if (uid != null) {
        data['profile'] = await _client
            .from('profiles')
            .select()
            .eq('id', uid)
            .maybeSingle();
      }
    } catch (_) {
      errors.add('profile');
    }
    return buildExport(data, exportedAt: DateTime.now(), errors: errors);
  }

  /// Arma el documento final con fecha, recuento por tabla y los datos.
  static Map<String, dynamic> buildExport(
    Map<String, dynamic> data, {
    required DateTime exportedAt,
    List<String> errors = const [],
  }) => {
    'app': 'PrezHome',
    'format': 1,
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'counts': {
      for (final e in data.entries)
        if (e.value is List) e.key: (e.value as List).length,
    },
    if (errors.isNotEmpty) 'errors': errors,
    ...data,
  };

  static String encode(Map<String, dynamic> export) =>
      const JsonEncoder.withIndent('  ').convert(export);

  static String fileName(DateTime d) =>
      'prezhome-datos-${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}.json';
}
