import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../models/recipe.dart';
import 'file_local_store.dart';
import 'meal_prep_planner.dart';
import 'plan_prefs.dart';
import 'plan_prep.dart';

/// Pone solos en Mi cocina los tápers de la cocina en lote: el día de cocina
/// van a la nevera o al congelador, la víspera pasan a la nevera y, una vez
/// comidos, se quitan.
///
/// Cada paso se hace una vez: se recuerda en el dispositivo hasta cuándo se
/// ha hecho. Se busca el táper por su nombre para no duplicarlo si otro móvil
/// del hogar ya lo hizo.
class TaperSync {
  static final _store = FileLocalStore(folderName: 'settings');
  static Future<int>? _running;

  /// Hace los pasos pendientes. Devuelve cuántos hizo. No lanza.
  static Future<int> sync(SupabaseClient client) =>
      _running ??= _sync(client).whenComplete(() => _running = null);

  static Future<int> _sync(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final key = 'taper_sync_until:${user.id}';
    final now = DateTime.now();
    String day(DateTime d) => d.toIso8601String().split('T').first;
    try {
      final me = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = me?['home_id'] as String?;
      if (homeId == null) return 0;
      final modes = await client
          .from('profiles')
          .select('cooking_mode')
          .eq('home_id', homeId);
      final batch = (modes as List).any((m) => m['cooking_mode'] == 'mealprep');

      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      var since = DateTime.tryParse(await _store.read(key) ?? '') ?? today;
      if (since.isBefore(weekAgo)) since = weekAgo;

      var done = 0;
      if (batch) {
        // Semanas (lunes) desde la víspera de [since] hasta hoy: un táper se
        // da por comido a las 00:00 del día siguiente, que puede ser lunes.
        final from = since.subtract(const Duration(days: 1));
        final firstWeek = DateTime(
          from.year,
          from.month,
          from.day - (from.weekday - 1),
        );
        final lastWeek = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - 1),
        );
        final planRes = await client
            .from('meal_plan_entries')
            .select()
            .eq('home_id', homeId)
            .gte('plan_date', day(firstWeek))
            .lt('plan_date', day(lastWeek.add(const Duration(days: 7))));
        final entries = [
          for (final m in planRes as List) MealPlanEntry.fromMap(m),
        ];
        if (entries.isNotEmpty) {
          final recRes = await client
              .from('recipes')
              .select()
              .eq('home_id', homeId);
          final recipes = {
            for (final m in recRes as List)
              m['id'] as String: Recipe.fromMap(m),
          };
          final prefs = PlanPrefs.current.value;
          final moves = <TaperMove>[];
          for (
            var w = firstWeek;
            !w.isAfter(lastWeek);
            w = DateTime(w.year, w.month, w.day + 7)
          ) {
            final plan = prepPlanForWeek(
              entries: entries,
              recipesById: recipes,
              weekStart: w,
              energyLevel: prefs.energy,
            );
            moves.addAll(
              taperMoves(
                plan,
                cookMinute: prefs.minutesOf('lunch'),
                thawMinute: prefs.minutesOf('dinner'),
              ),
            );
          }
          moves.sort((a, b) => a.at.compareTo(b.at));
          for (final m in moves) {
            if (!m.at.isAfter(since) || m.at.isAfter(now)) continue;
            await _apply(client, homeId, m, recipes[m.recipeId]);
            done++;
          }
        }
      }
      await _store.write(key, now.toIso8601String());
      return done;
    } catch (e) {
      debugPrint('TaperSync.sync error: $e');
      return 0;
    }
  }

  static Future<void> _apply(
    SupabaseClient client,
    String homeId,
    TaperMove m,
    Recipe? recipe,
  ) async {
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final rows = await client
        .from('inventory_items')
        .select('id')
        .eq('home_id', homeId)
        .eq('kind', 'dish')
        .eq('name', m.name);
    final ids = [for (final r in rows as List) r['id'] as String];
    switch (m.step) {
      case TaperStep.guardar:
        if (ids.isNotEmpty) return;
        final item = InventoryItem(
          id: '',
          homeId: homeId,
          name: m.name,
          category: m.frozen ? 'Congelador' : 'Nevera',
          quantity: 1,
          unit: 'comidas',
          kind: 'dish',
          recipeId: m.recipeId,
          servings: m.servings.toDouble(),
          frozenOn: m.frozen ? m.cookDay : null,
          // En la nevera, se come su día; congelado, aguanta lo de la receta.
          bestBefore: m.frozen
              ? m.cookDay.add(
                  Duration(
                    days: recipe?.freezerDays ?? kDiasCongeladorPorDefecto,
                  ),
                )
              : m.eatDay,
          imageUrl: recipe?.imageUrl,
        );
        await client.from('inventory_items').insert(item.toMap());
      case TaperStep.descongelar:
        if (ids.isEmpty) return;
        await client
            .from('inventory_items')
            .update({'category': 'Nevera', 'best_before': day(m.eatDay)})
            .inFilter('id', ids);
      case TaperStep.comido:
        if (ids.isEmpty) return;
        await client.from('inventory_items').delete().inFilter('id', ids);
    }
  }
}
