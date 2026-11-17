import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../utils/offline_actions.dart';
import '../utils/pantry_ideas.dart';
import '../utils/practical_quantity.dart';
import 'count_prefs.dart';
import 'offline_provider.dart';
import 'plan_prefs.dart';
import 'plan_shopping.dart';

/// Cuánto se gasta de un producto de la despensa.
class PantryUse {
  const PantryUse(this.item, this.used, {this.total, this.unit});

  final InventoryItem item;
  final double used;

  /// Si la despensa contaba envases ("1 bote") y la receta pide gramos, la
  /// fila pasa a contarse en [unit] ("g") con [total] = envases × peso.
  final double? total;
  final String? unit;

  String get unitOut => unit ?? item.unit;

  double get left =>
      ((total ?? item.quantity) - used).clamp(0, double.infinity);
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

/// Envases: si la receta pide otra medida y no se sabe lo que trae, se gasta
/// uno.
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

/// Unidad base ('g', 'ml' o 'ud') de [unit], o null si no es una medida.
String? measureBase(String? unit) =>
    _toBase[(unit ?? '').trim().toLowerCase()]?.$1;

/// ¿[unit] cuenta envases (botes, latas, paquetes, unidades)?
bool isPackUnit(String? unit) =>
    _packs.contains((unit ?? '').trim().toLowerCase());

/// [qty] en [from] pasado a [to] cuando son la misma magnitud (g y kg, ml y
/// L, unidades). Null si no se puede.
double? convertMeasure(double qty, String? from, String? to) {
  final a = (from ?? '').trim().toLowerCase();
  final b = (to ?? '').trim().toLowerCase();
  if (a == b) return qty;
  final f = _toBase[a];
  final t = _toBase[b];
  if (f != null && t != null && f.$1 == t.$1) return qty * f.$2 / t.$2;
  return null;
}

/// Lógica PURA: qué se gasta de [pantry] al cocinar [ingredients] (ya
/// multiplicados por [factor] raciones). No toca básicos, condimentos ni lo
/// marcado "siempre en casa". Cada ingrediente sale del producto que antes
/// caduca. Misma medida (g/kg, ml/l, unidades) se resta. Si la despensa
/// cuenta envases y la receta pide peso, con lo que trae cada envase
/// ([packSizes], por id del producto) se resta solo lo usado y la fila pasa
/// a gramos ("1 bote" de 570 g − 200 g = 370 g); sin ese dato se gasta un
/// envase.
List<PantryUse> pantryUsesFor(
  List<Ingredient> ingredients,
  List<InventoryItem> pantry, {
  double factor = 1,
  Map<String, PackMeasure> packSizes = const {},
}) {
  final used = <String, double>{};
  final total = <String, double>{};
  final unitOf = <String, String>{};
  final byId = {for (final p in pantry) p.id: p};
  double have(InventoryItem p) =>
      (total[p.id] ?? p.quantity) - (used[p.id] ?? 0);
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
                  have(p) > 0 &&
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
    final unit = unitOf[item.id] ?? item.unit;
    var amount = convertMeasure(q * factor, ing.unit, unit);
    if (amount == null && isPackUnit(unit)) {
      final pack = packSizes[item.id];
      final inPack = pack == null
          ? null
          : convertMeasure(q * factor, ing.unit, pack.unit);
      if (pack != null && pack.size > 0 && inPack != null) {
        // De envases a peso: lo ya gastado también.
        total[item.id] = item.quantity * pack.size;
        used[item.id] = (used[item.id] ?? 0) * pack.size;
        unitOf[item.id] = pack.unit;
        amount = inPack;
      } else {
        // shortcut: sin saber lo que trae el envase, se gasta uno entero.
        amount = 1;
      }
    }
    if (amount == null) continue;
    final left = have(item);
    used[item.id] = (used[item.id] ?? 0) + amount.clamp(0, left);
  }
  return [
    for (final e in used.entries)
      if (e.value > 0)
        PantryUse(
          byId[e.key]!,
          e.value,
          total: total[e.key],
          unit: unitOf[e.key],
        ),
  ];
}

/// Lógica PURA: suma [add] [addUnit] comprado a lo que ya hay en la despensa
/// ([have] [haveUnit]). Convierte g/kg y ml/L; si la despensa cuenta envases
/// y se compró a peso, lo pasa a envases con [packSize] (en [addUnit]) o
/// suma uno. Null si no se puede sumar sin inventar (mejor otra fila).
({double quantity, String unit})? mergePantryQuantity(
  double have,
  String haveUnit,
  double add,
  String? addUnit, {
  double? packSize,
}) {
  final same = convertMeasure(add, addUnit, haveUnit);
  if (same != null) return (quantity: have + same, unit: haveUnit);
  if (isPackUnit(haveUnit) && measureBase(addUnit) != null) {
    final packs = packSize != null && packSize > 0
        ? (add / packSize - 1e-6).ceil().clamp(1, 1 << 20).toDouble()
        : 1.0;
    return (quantity: have + packs, unit: haveUnit);
  }
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
      final packSizes = await _packSizes(
        client,
        homeId,
        pantry,
        ingsByRecipe.values.expand((l) => l),
      );
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
          packSizes: packSizes,
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
                    changes: {
                      'quantity': u.left,
                      if (u.unit != null) 'unit': u.unit,
                    },
                    nowMillis: nowMs,
                    seq: seq++,
                  ),
          );
        }
        final after = {for (final u in uses) u.item.id: u};
        pantry = [
          for (final p in pantry)
            if (!after.containsKey(p.id))
              p
            else if (after[p.id]!.left > 0)
              InventoryItem.fromMap({
                ...p.toCacheMap(),
                'quantity': after[p.id]!.left,
                'unit': after[p.id]!.unitOut,
              }),
        ];
        await client.from('pantry_log').insert([
          for (final u in uses)
            {
              'home_id': homeId,
              'name': u.item.name,
              'quantity': u.used,
              'unit': u.unitOut,
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

  /// Lo que trae cada envase de lo que la despensa cuenta en envases y las
  /// recetas piden a peso: el envase que puso el hogar o, si no, el del
  /// catálogo del súper de casa. Por id del producto. No lanza.
  static Future<Map<String, PackMeasure>> _packSizes(
    SupabaseClient client,
    String homeId,
    List<InventoryItem> pantry,
    Iterable<Ingredient> ingredients,
  ) async {
    final out = <String, PackMeasure>{};
    try {
      await CountPrefs(client).load(homeId);
      String? store;
      try {
        final home = await client
            .from('homes')
            .select('supermarkets')
            .eq('id', homeId)
            .maybeSingle();
        final raw = home?['supermarkets'];
        if (raw is List && raw.isNotEmpty) store = raw.first.toString();
      } catch (_) {}
      final shop = PlanShoppingService(client);
      var lookups = 0;
      for (final p in pantry) {
        if (!isPackUnit(p.unit) || p.kind != 'ingredient') continue;
        String? base;
        for (final ing in ingredients) {
          final b = measureBase(ing.unit);
          if ((b == 'g' || b == 'ml') && pantryNameMatches(ing.name, p.name)) {
            base = b;
            break;
          }
        }
        if (base == null) continue;
        final own = CountPrefs.customPackOf(p.name);
        if (own != null) {
          out[p.id] = own;
          continue;
        }
        // Pocas búsquedas por pasada: el catálogo va por red.
        if (store == null || lookups++ >= 12) continue;
        final size = await shop.packSizeFor(
          p.name,
          base,
          supermarketKey: store,
        );
        if (size != null && size > 0) out[p.id] = (size: size, unit: base);
      }
    } catch (e) {
      debugPrint('PantryUsage._packSizes error: $e');
    }
    return out;
  }
}
