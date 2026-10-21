import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../utils/offline_actions.dart';
import '../utils/pantry_ideas.dart';
import '../utils/practical_quantity.dart';
import 'offline_provider.dart';
import 'plan_prefs.dart';

/// Cuánto se gasta de un producto de la despensa.
class PantryUse {
  const PantryUse(this.item, this.used);

  final InventoryItem item;
  final double used;

  double get left => (item.quantity - used).clamp(0, double.infinity);
}

const _toBase = <String, (String, double)>{
  'g': ('g', 1),
  'gr': ('g', 1),
  'gramo': ('g', 1),
  'gramos': ('g', 1),
  'kg': ('g', 1000),
  'kilo': ('g', 1000),
  'kilos': ('g', 1000),
  'ml': ('ml', 1),
  'cl': ('ml', 10),
  'l': ('ml', 1000),
  'litro': ('ml', 1000),
  'litros': ('ml', 1000),
  'ud': ('ud', 1),
  'uds': ('ud', 1),
  'u': ('ud', 1),
  'unidad': ('ud', 1),
  'unidades': ('ud', 1),
  'pieza': ('ud', 1),
  'piezas': ('ud', 1),
};

/// Envases: si la receta pide otra medida, se gasta uno.
const _packs = {
  'ud',
  'uds',
  'unidad',
  'unidades',
  'botes',
  'bote',
  'bolsas',
  'bolsa',
  'latas',
  'lata',
  'paquetes',
  'paquete',
};

/// Lógica PURA: qué se gasta de [pantry] al cocinar [ingredients] (ya
/// multiplicados por [factor] raciones). No toca básicos, condimentos ni lo
/// marcado "siempre en casa". Cada ingrediente sale del producto que antes
/// caduca. Misma medida (g/kg, ml/l, unidades) se resta; si no se puede
/// convertir y el producto va por envases, se gasta un envase.
List<PantryUse> pantryUsesFor(
  List<Ingredient> ingredients,
  List<InventoryItem> pantry, {
  double factor = 1,
}) {
  final used = <String, double>{};
  final byId = {for (final p in pantry) p.id: p};
  for (final ing in ingredients) {
    final q = ing.quantity;
    if (q == null || q <= 0) continue;
    if (isPantryBasic(ing.name) || isCondiment(ing.name)) continue;
    final candidates =
        pantry
            .where(
              (p) =>
                  p.itemType != 'hogar' &&
                  !p.isStaple &&
                  p.category != 'Especias' &&
                  p.kind == 'ingredient' &&
                  p.quantity - (used[p.id] ?? 0) > 0 &&
                  pantryNameMatches(ing.name, p.name),
            )
            .toList()
          ..sort((a, b) {
            final da = a.daysUntilExpiry, db = b.daysUntilExpiry;
            if (da == null) return db == null ? 0 : 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
    if (candidates.isEmpty) continue;
    final item = candidates.first;
    final amount = _amountIn(q * factor, ing.unit, item.unit);
    if (amount == null) continue;
    final left = item.quantity - (used[item.id] ?? 0);
    used[item.id] = (used[item.id] ?? 0) + amount.clamp(0, left);
  }
  return [
    for (final e in used.entries)
      if (e.value > 0) PantryUse(byId[e.key]!, e.value),
  ];
}

/// [qty] en [from] pasado a [to]. Null si no hay forma razonable.
double? _amountIn(double qty, String? from, String to) {
  final f = _toBase[(from ?? 'ud').trim().toLowerCase()];
  final t = _toBase[to.trim().toLowerCase()];
  if (f != null && t != null && f.$1 == t.$1) return qty * f.$2 / t.$2;
  // shortcut: un envase por ingrediente sin medida convertible; afinar si
  // se guarda el peso de cada envase.
  if (_packs.contains(to.trim().toLowerCase())) return 1;
  return null;
}

/// Descuenta de la despensa los ingredientes de las comidas del plan cuya
/// hora ya ha pasado. Cada comida se descuenta una sola vez para todo el
/// hogar (`meal_plan_entries.pantry_used_at`).
class PantryUsage {
  static Future<List<String>>? _running;

  /// Devuelve los títulos de las recetas descontadas. No lanza.
  static Future<List<String>> syncPlan(SupabaseClient client) =>
      _running ??= _sync(client).whenComplete(() => _running = null);

  static Future<List<String>> _sync(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return const [];
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final now = DateTime.now();
    final done = <String>[];
    try {
      final profile = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return const [];
      final rows = await client
          .from('meal_plan_entries')
          .select()
          .eq('home_id', homeId)
          .isFilter('pantry_used_at', null)
          .gte('plan_date', day(now.subtract(const Duration(days: 6))))
          .lte('plan_date', day(now));
      final prefs = PlanPrefs.current.value;
      final due =
          [
            for (final m in rows as List)
              MealPlanEntry.fromMap(Map<String, dynamic>.from(m)),
          ].where((e) {
            if (e.id == null || e.recipeId == null) return false;
            // Lo que sale del congelador ya se cocinó (y se descontó) antes.
            if (e.skipped || e.fromFreezer) return false;
            final at = DateTime(
              e.date.year,
              e.date.month,
              e.date.day,
              0,
              prefs.minutesOf(e.mealType),
            );
            return !at.isAfter(now);
          }).toList();
      if (due.isEmpty) return const [];

      final recipeIds = due.map((e) => e.recipeId!).toSet().toList();
      final recRes = await client
          .from('recipes')
          .select('id, title, servings')
          .inFilter('id', recipeIds);
      final recipes = {
        for (final r in recRes as List) r['id'] as String: r as Map,
      };
      final ingRes = await client
          .from('recipe_ingredients')
          .select()
          .inFilter('recipe_id', recipeIds);
      final ingsByRecipe = <String, List<Ingredient>>{};
      for (final m in ingRes as List) {
        final map = Map<String, dynamic>.from(m as Map);
        ingsByRecipe
            .putIfAbsent(map['recipe_id'] as String, () => [])
            .add(Ingredient.fromMap(map));
      }

      final repo = OfflineProvider.instance.inventory;
      var pantry = [
        for (final r in await repo.readCached())
          if ((r['name'] ?? '').toString().trim().isNotEmpty)
            InventoryItem.fromMap(r),
      ];
      var seq = 0;
      for (final e in due) {
        // Reclamar la comida: si otro móvil ya la descontó, no vuelve nada.
        final claimed = await client
            .from('meal_plan_entries')
            .update({
              'pantry_used_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', e.id!)
            .isFilter('pantry_used_at', null)
            .select('id');
        if ((claimed as List).isEmpty) continue;
        final recipe = recipes[e.recipeId];
        final base = (recipe?['servings'] as num?)?.toDouble() ?? 0;
        final factor = base > 0 && (e.servings ?? 0) > 0
            ? e.servings! / base
            : 1.0;
        final uses = pantryUsesFor(
          ingsByRecipe[e.recipeId] ?? const [],
          pantry,
          factor: factor,
        );
        if (uses.isEmpty) continue;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        for (final u in uses) {
          await repo.applyLocalWrite(
            u.left <= 0
                ? buildDeleteOp(
                    table: kInventoryTable,
                    id: u.item.id,
                    nowMillis: nowMs,
                    seq: seq++,
                  )
                : buildUpdateOp(
                    table: kInventoryTable,
                    id: u.item.id,
                    changes: {'quantity': u.left},
                    nowMillis: nowMs,
                    seq: seq++,
                  ),
          );
        }
        final left = {for (final u in uses) u.item.id: u.left};
        pantry = [
          for (final p in pantry)
            if (!left.containsKey(p.id))
              p
            else if (left[p.id]! > 0)
              InventoryItem.fromMap({
                ...p.toCacheMap(),
                'quantity': left[p.id],
              }),
        ];
        await client.from('pantry_log').insert([
          for (final u in uses)
            {
              'home_id': homeId,
              'name': u.item.name,
              'quantity': u.used,
              'unit': u.item.unit,
              'reason': 'receta',
              'recipe_id': e.recipeId,
              'used_on': day(e.date),
            },
        ]);
        done.add((recipe?['title'] ?? '').toString());
      }
    } catch (e) {
      debugPrint('PantryUsage.syncPlan error: $e');
    }
    return done;
  }
}
