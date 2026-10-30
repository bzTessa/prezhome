import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../models/shopping_list_item.dart';
import '../utils/practical_quantity.dart';
import '../utils/shopping_categories.dart';
import '../widgets/food_category_icon.dart';
import 'food_photo_service.dart';
import 'meal_prep_planner.dart';
import 'product_photo_resolver.dart';

/// Lo que hay en casa de un producto (para descontarlo del plan).
class PantryStock {
  const PantryStock({
    required this.name,
    this.quantity,
    this.unit,
    this.isStaple = false,
  });

  final String name;
  final double? quantity;
  final String? unit;

  /// "Siempre en casa": nunca se añade a la compra.
  final bool isStaple;
}

/// Producto que hay que comprar para el plan.
class PlanNeed {
  const PlanNeed({required this.name, this.quantity, this.unit});

  final String name;
  final double? quantity;
  final String? unit;
}

/// Lógica PURA: suma los ingredientes del plan por nombre y unidad, quita los
/// básicos "siempre en casa" y descuenta lo que ya hay cuando la unidad
/// coincide. Ante la duda se compra (mejor de más que quedarse corto).
List<PlanNeed> planShoppingNeeds(
  List<Ingredient> ingredients,
  List<PantryStock> pantry,
) {
  final agg = <String, ({String name, String? unit, double? qty})>{};
  for (final ing in ingredients) {
    final name = ing.name.trim();
    if (name.isEmpty) continue;
    final key =
        '${name.toLowerCase()}|${(ing.unit ?? '').trim().toLowerCase()}';
    final prev = agg[key];
    if (prev == null) {
      agg[key] = (name: name, unit: ing.unit, qty: ing.quantity);
    } else {
      // Si alguna no tiene cantidad no se puede sumar de forma fiable.
      final q = prev.qty == null || ing.quantity == null
          ? null
          : prev.qty! + ing.quantity!;
      agg[key] = (name: prev.name, unit: prev.unit, qty: q);
    }
  }

  final staples = <String>{};
  final stock = <String, PantryStock>{};
  for (final p in pantry) {
    final k = CategoryIcons.normalize(p.name.trim());
    if (k.isEmpty) continue;
    if (p.isStaple) staples.add(k);
    stock.putIfAbsent(k, () => p);
  }

  final needs = <PlanNeed>[];
  for (final item in agg.values) {
    final k = CategoryIcons.normalize(item.name);
    if (staples.contains(k)) continue;
    final inv = stock[k];
    final sameUnit =
        (item.unit ?? '').trim().toLowerCase() ==
        (inv?.unit ?? '').trim().toLowerCase();
    if (inv != null && item.qty != null && inv.quantity != null && sameUnit) {
      final left = item.qty! - inv.quantity!;
      if (left <= 0) continue;
      needs.add(PlanNeed(name: item.name, quantity: left, unit: item.unit));
    } else {
      needs.add(PlanNeed(name: item.name, quantity: item.qty, unit: item.unit));
    }
  }
  return needs;
}

/// Lógica PURA: lo que hace falta para cocinar las [batches] de una tanda.
/// Cada ingrediente de [rows] (filas de recipe_ingredients) se multiplica por
/// las raciones de su tanda entre las que da la receta ([servingsByRecipe]) y
/// se suma con los iguales. Devuelve líneas como "1,5 kg pollo".
List<String> batchIngredientLines(
  List<Map<String, dynamic>> rows,
  List<PrepBatch> batches,
  Map<String, int> servingsByRecipe,
) {
  final factor = {
    for (final b in batches)
      b.recipeId: b.totalServings / max(1, servingsByRecipe[b.recipeId] ?? 1),
  };
  final scaled = <Ingredient>[];
  for (final row in rows) {
    final ing = Ingredient.fromMap(row);
    final f = factor[row['recipe_id']];
    if (f == null) continue;
    final q = ing.quantity == null ? null : ing.quantity! * f;
    scaled.add(
      Ingredient(
        name: ing.name,
        unit: ing.unit,
        quantity: q == null
            ? null
            : q >= 10
            ? q.roundToDouble()
            : (q * 10).round() / 10,
      ),
    );
  }
  return [
    for (final n in planShoppingNeeds(scaled, const []))
      Ingredient(name: n.name, quantity: n.quantity, unit: n.unit).display,
  ];
}

/// Pasa las necesidades a cantidades de súper ("1 ud" de pimienta) y junta
/// en una sola línea lo que coincide en nombre y unidad.
List<({String name, double? qty, String? unit})> shoppingLines(
  List<PlanNeed> needs,
) {
  final merged = <String, ({String name, double? qty, String? unit})>{};
  for (final need in needs) {
    final practical = makePracticalForShopping(
      need.name,
      need.quantity,
      need.unit,
    );
    final key =
        '${CategoryIcons.normalize(need.name)}|'
        '${practical.unit.trim().toLowerCase()}';
    final prev = merged[key];
    if (prev == null) {
      merged[key] = (
        name: need.name,
        qty: practical.quantity,
        unit: practical.unit,
      );
    } else {
      final isUnit = (prev.unit ?? '').toLowerCase().startsWith('ud');
      // Las unidades sueltas (1 ud de especia) no se suman: con una basta.
      final q = isUnit || prev.qty == null || practical.quantity == null
          ? prev.qty
          : prev.qty! + practical.quantity!;
      merged[key] = (name: prev.name, qty: q, unit: prev.unit);
    }
  }
  return merged.values.toList();
}

/// Rellena la lista de la compra con lo que pide el plan de comidas y le
/// pone foto a cada producto (las fotos se guardan por hogar, así que un
/// producto que ya tuvo foto la reutiliza al instante).
class PlanShoppingService {
  PlanShoppingService(this._client);

  final SupabaseClient _client;

  /// Regenera los productos automáticos de la lista [listId] (null = lista
  /// principal) con el plan entre [from] (incluido) y [to] (excluido). Los
  /// productos añadidos a mano y los ya comprados no se tocan. Devuelve los
  /// productos añadidos. Necesita conexión.
  Future<List<ShoppingListItem>> syncFromPlan({
    required String homeId,
    required DateTime from,
    required DateTime to,
    String? listId,
  }) async {
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final planRes = await _client
        .from('meal_plan_entries')
        .select('recipe_id, skipped, inventory_item_id')
        .eq('home_id', homeId)
        .gte('plan_date', day(from))
        .lt('plan_date', day(to));
    final recipeIds = <String>[];
    for (final row in planRes as List) {
      final id = row['recipe_id'] as String?;
      // Un plato que ya está en el congelador no se compra otra vez.
      if (id != null &&
          row['skipped'] != true &&
          row['inventory_item_id'] == null) {
        recipeIds.add(id);
      }
    }
    if (recipeIds.isEmpty) return const [];

    // Una receta que se repite en el plan se compra tantas veces como salga.
    final ingRes = await _client
        .from('recipe_ingredients')
        .select()
        .inFilter('recipe_id', recipeIds.toSet().toList());
    final byRecipe = <String, List<Ingredient>>{};
    for (final m in ingRes as List) {
      final map = Map<String, dynamic>.from(m as Map);
      byRecipe
          .putIfAbsent(map['recipe_id'] as String, () => [])
          .add(Ingredient.fromMap(map));
    }
    final ingredients = [for (final id in recipeIds) ...?byRecipe[id]];

    final invRes = await _client
        .from('inventory_items')
        .select('name, quantity, unit, is_staple')
        .eq('home_id', homeId);
    final pantry = [
      for (final m in invRes as List)
        PantryStock(
          name: (m['name'] ?? '').toString(),
          quantity: (m['quantity'] as num?)?.toDouble(),
          unit: m['unit'] as String?,
          isStaple: m['is_staple'] == true,
        ),
    ];

    final catRes = await _client
        .from('shopping_categories')
        .select('id, name')
        .eq('home_id', homeId);
    final catIds = {
      for (final c in catRes as List)
        normalizeCategoryText(c['name'].toString()): c['id'] as String,
    };

    // Las fotos que ya se usaron se reutilizan sin esperar.
    final photoRes = await _client
        .from('food_photo_cache')
        .select('name_normalized, url')
        .eq('home_id', homeId);
    final photos = {
      for (final p in photoRes as List)
        if (p['url'] != null && !isStockPhoto(p['url'] as String))
          p['name_normalized'] as String: p['url'] as String,
    };

    final merged = shoppingLines(planShoppingNeeds(ingredients, pantry));

    final items = <ShoppingListItem>[];
    for (final m in merged) {
      final cat = defaultCategoryFor(m.name);
      items.add(
        ShoppingListItem(
          homeId: homeId,
          name: m.name,
          quantity: m.qty,
          unit: m.unit,
          source: 'auto',
          category: cat,
          categoryId: catIds[normalizeCategoryText(cat)],
          listId: listId,
          imageUrl: photos[FoodPhotoService.cacheKey(m.name)],
        ),
      );
    }

    final delete = _client
        .from('shopping_list_items')
        .delete()
        .eq('home_id', homeId)
        .eq('source', 'auto')
        .eq('checked', false);
    if (listId == null) {
      await delete.filter('list_id', 'is', null);
    } else {
      await delete.eq('list_id', listId);
    }
    if (items.isEmpty) return const [];
    final inserted = await _client.from('shopping_list_items').insert([
      for (final i in items) i.toInsertMap(),
    ]).select();
    return [
      for (final m in inserted as List)
        ShoppingListItem.fromMap(Map<String, dynamic>.from(m as Map)),
    ];
  }

  /// Pone la foto del envase (Open Food Facts) a los productos sin foto, con
  /// foto de banco de imágenes o con una de OFF que no es ese producto. Se puede lanzar sin esperar: cada foto se
  /// guarda en cuanto se encuentra.
  Future<int> fillMissingPhotos(
    String homeId,
    List<ShoppingListItem> items, {
    String? supermarketKey,
  }) async {
    var found = 0;
    final resolver = ProductPhotoResolver(_client);
    // Sin súper indicado se usa el principal del hogar.
    var store = supermarketKey;
    if (store == null) {
      try {
        final home = await _client
            .from('homes')
            .select('supermarkets')
            .eq('id', homeId)
            .maybeSingle();
        final raw = home?['supermarkets'];
        if (raw is List && raw.isNotEmpty) store = raw.first.toString();
      } catch (_) {}
    }
    for (final item in items) {
      final current = item.imageUrl ?? '';
      if (item.id == null) continue;
      // Una foto ya puesta se deja si es de verdad ese producto.
      final wrong =
          current.isNotEmpty &&
          !isStockPhoto(current) &&
          await resolver.photoMatches(item.name, current) == false;
      if (current.isNotEmpty && !isStockPhoto(current) && !wrong) continue;
      try {
        final url = await resolver.photoFor(
          homeId: homeId,
          name: item.name,
          supermarketKey: store,
        );
        // Sin producto claro, mejor la ilustración que una foto que no es.
        if (url == null && !wrong) continue;
        if (url == current) continue;
        await _client
            .from('shopping_list_items')
            .update({'image_url': url})
            .eq('id', item.id!);
        found++;
      } catch (_) {
        // Sin foto se ve la ilustración del producto.
      }
    }
    return found;
  }
}
