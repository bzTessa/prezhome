import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../models/shopping_list_item.dart';
import '../utils/practical_quantity.dart';
import '../utils/shopping_categories.dart';
import '../widgets/food_category_icon.dart';
import 'food_photo_service.dart';

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
        .select('recipe_id, skipped')
        .eq('home_id', homeId)
        .gte('plan_date', day(from))
        .lt('plan_date', day(to));
    final recipeIds = <String>[];
    for (final row in planRes as List) {
      final id = row['recipe_id'] as String?;
      if (id != null && row['skipped'] != true) recipeIds.add(id);
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
        if (p['url'] != null)
          p['name_normalized'] as String: p['url'] as String,
    };

    final items = <ShoppingListItem>[];
    for (final need in planShoppingNeeds(ingredients, pantry)) {
      final practical = makePracticalForShopping(
        need.name,
        need.quantity,
        need.unit,
      );
      final cat = defaultCategoryFor(need.name);
      items.add(
        ShoppingListItem(
          homeId: homeId,
          name: need.name,
          quantity: practical.quantity,
          unit: practical.unit,
          source: 'auto',
          category: cat,
          categoryId: catIds[normalizeCategoryText(cat)],
          listId: listId,
          imageUrl: photos[FoodPhotoService.cacheKey(need.name)],
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

  /// Busca foto para los productos que aún no tienen y la guarda. Se puede
  /// lanzar sin esperar: cada foto se guarda en cuanto se encuentra.
  Future<int> fillMissingPhotos(
    String homeId,
    List<ShoppingListItem> items,
  ) async {
    var found = 0;
    final photos = FoodPhotoService(_client);
    for (final item in items) {
      if (item.id == null || (item.imageUrl ?? '').isNotEmpty) continue;
      try {
        final url = await photos.resolveProductPhotoUrl(
          homeId: homeId,
          name: item.name,
          mode: item.itemType == 'comida' ? 'ingredient' : 'dish',
        );
        if (url == null) continue;
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
