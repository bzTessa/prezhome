import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Comidas que se repiten (p. ej. el mismo desayuno cada 2 días, para
/// siempre). Cada regla de `meal_plan_repeats` se convierte en comidas del
/// plan hacia delante, sin pisar lo que ya está puesto. `filled_until`
/// recuerda hasta dónde se rellenó, así lo que se quita a mano no vuelve.
class PlanRepeats {
  /// Hasta cuántos días por delante de hoy se rellena.
  static const maxDaysAhead = 120;

  static String _day(DateTime d) => d.toIso8601String().split('T').first;

  /// Días de la regla después de [after] y hasta [until] (incluido).
  static List<DateTime> dueDates({
    required DateTime start,
    required int everyDays,
    DateTime? end,
    required DateTime after,
    required DateTime until,
  }) {
    final last = end != null && end.isBefore(until) ? end : until;
    final out = <DateTime>[];
    for (var i = 0; ; i += everyDays) {
      final d = DateTime(start.year, start.month, start.day + i);
      if (d.isAfter(last)) break;
      if (d.isAfter(after)) out.add(d);
    }
    return out;
  }

  /// Rellena el plan hasta [until] (no incluido) con las reglas del hogar.
  /// [servingsFor] da las raciones de cada comida; sin él quedan sin fijar.
  /// Devuelve cuántas comidas intentó añadir. No lanza.
  static Future<int> fill(
    SupabaseClient client,
    String homeId,
    DateTime until, {
    int? Function(String mealType, DateTime date)? servingsFor,
  }) async {
    final now = DateTime.now();
    final cap = DateTime(now.year, now.month, now.day + maxDaysAhead);
    final to = until.isAfter(cap) ? cap : until;
    final lastDay = DateTime(to.year, to.month, to.day - 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    try {
      final rules = await client
          .from('meal_plan_repeats')
          .select()
          .eq('home_id', homeId)
          .lt('filled_until', _day(lastDay));
      var added = 0;
      for (final r in rules as List) {
        final dates = dueDates(
          start: DateTime.parse(r['start_date'] as String),
          everyDays: r['every_days'] as int,
          end: r['end_date'] == null
              ? null
              : DateTime.parse(r['end_date'] as String),
          // Nunca hacia atrás: el pasado ya cuenta en diario y despensa.
          after: [
            DateTime.parse(r['filled_until'] as String),
            yesterday,
          ].reduce((a, b) => a.isAfter(b) ? a : b),
          until: lastDay,
        );
        if (dates.isNotEmpty) {
          // Lo que ya hay en ese hueco se respeta (UNIQUE hogar/día/comida).
          await client
              .from('meal_plan_entries')
              .upsert(
                [
                  for (final d in dates)
                    {
                      'home_id': homeId,
                      'plan_date': _day(d),
                      'meal_type': r['meal_type'],
                      'recipe_id': r['recipe_id'],
                      'repeat_id': r['id'],
                      'servings': servingsFor?.call(
                        r['meal_type'] as String,
                        d,
                      ),
                    },
                ],
                onConflict: 'home_id,plan_date,meal_type',
                ignoreDuplicates: true,
              );
          added += dates.length;
        }
        await client
            .from('meal_plan_repeats')
            .update({'filled_until': _day(lastDay)})
            .eq('id', r['id']);
      }
      return added;
    } catch (e) {
      debugPrint('PlanRepeats.fill error: $e');
      return 0;
    }
  }

  /// Crea la regla desde la comida [entryId] (que pasa a ser la primera).
  static Future<void> create(
    SupabaseClient client, {
    required String homeId,
    required String entryId,
    required String recipeId,
    required String mealType,
    required DateTime start,
    required int everyDays,
    DateTime? end,
  }) async {
    final rule = await client
        .from('meal_plan_repeats')
        .insert({
          'home_id': homeId,
          'recipe_id': recipeId,
          'meal_type': mealType,
          'start_date': _day(start),
          'every_days': everyDays,
          'end_date': end == null ? null : _day(end),
          'filled_until': _day(start),
        })
        .select('id')
        .single();
    await client
        .from('meal_plan_entries')
        .update({'repeat_id': rule['id']})
        .eq('id', entryId);
  }

  /// Deja de repetir: quita las comidas futuras de la regla y la regla.
  static Future<void> stop(SupabaseClient client, String repeatId) async {
    await client
        .from('meal_plan_entries')
        .delete()
        .eq('repeat_id', repeatId)
        .gt('plan_date', _day(DateTime.now()));
    await client.from('meal_plan_repeats').delete().eq('id', repeatId);
  }
}
