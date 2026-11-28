import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../models/ready_meal.dart';
import '../models/recipe.dart';

/// Lo que hay para comer sin cocinar: tápers hechos, preparados del súper y
/// recetas rápidas que no piden fuego.
class NotCookingOptions {
  const NotCookingOptions({
    this.dishes = const [],
    this.ready = const [],
    this.quick = const [],
  });

  /// Tápers y platos ya hechos de Mi cocina (nevera primero).
  final List<InventoryItem> dishes;

  /// Preparados de confianza; los que hay en casa, primero.
  final List<({ReadyMeal meal, bool atHome})> ready;

  /// Recetas de un momento (sin cocinar o de 15 minutos como mucho).
  final List<Recipe> quick;

  bool get isEmpty => dishes.isEmpty && ready.isEmpty && quick.isEmpty;
}

/// "Hoy no me apetece cocinar": cambia la comida de hoy por algo ya hecho y
/// pasa la receta al siguiente hueco libre de la semana.
class NotCooking {
  static String _day(DateTime d) => d.toIso8601String().split('T').first;

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  /// El preparado está en casa si algún producto de Mi cocina lleva su
  /// nombre (o al revés: "Pizza" y "Pizza barbacoa Hacendado").
  static bool atHome(ReadyMeal m, Iterable<InventoryItem> pantry) {
    final name = _fold(m.name.trim());
    if (name.isEmpty) return false;
    return pantry.any((i) {
      if (i.quantity <= 0) return false;
      final n = _fold(i.name.trim());
      return n.isNotEmpty && (n.contains(name) || name.contains(n));
    });
  }

  /// Ordena y filtra lo que se ofrece. Puro, para poder probarlo.
  static NotCookingOptions pick({
    required Iterable<InventoryItem> pantry,
    required Iterable<ReadyMeal> readyMeals,
    required Iterable<Recipe> recipes,
    String? currentRecipeId,
  }) {
    final dishes =
        [
          for (final i in pantry)
            if (i.kind == 'dish' && i.recipeId != null && i.quantity > 0) i,
        ]..sort((a, b) {
          int rank(InventoryItem i) => i.category == 'Congelador' ? 1 : 0;
          return rank(a).compareTo(rank(b));
        });
    final ready = [
      for (final m in readyMeals)
        if (m.trusted && !m.isDessert) (meal: m, atHome: atHome(m, pantry)),
    ]..sort((a, b) => (a.atHome ? 0 : 1).compareTo(b.atHome ? 0 : 1));
    bool mainMeal(Recipe r) =>
        r.mealTypes.isEmpty ||
        r.mealTypes.any((t) => t == 'lunch' || t == 'dinner');
    final quick =
        [
          for (final r in recipes)
            if (r.id != currentRecipeId &&
                mainMeal(r) &&
                (!r.needsCooking || (r.totalTimeMinutes ?? 99) <= 15))
              r,
        ]..sort((a, b) {
          if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
          return (a.totalTimeMinutes ?? 99).compareTo(b.totalTimeMinutes ?? 99);
        });
    return NotCookingOptions(
      dishes: dishes.take(4).toList(),
      ready: ready.take(6).toList(),
      quick: quick.take(4).toList(),
    );
  }

  /// Primer día después de [from], en los próximos [days], sin nada puesto en
  /// esa comida. null si la semana está llena.
  static DateTime? nextFreeDay({
    required DateTime from,
    required String mealType,
    required Iterable<MealPlanEntry> entries,
    int days = 7,
  }) {
    final taken = {
      for (final e in entries)
        if (e.mealType == mealType) _day(e.date),
    };
    for (var i = 1; i <= days; i++) {
      final d = DateTime(from.year, from.month, from.day + i);
      if (!taken.contains(_day(d))) return d;
    }
    return null;
  }

  static Future<NotCookingOptions> load(
    SupabaseClient client, {
    required String homeId,
    String? currentRecipeId,
  }) async {
    final (inv, ready, recipes) = await (
      client.from('inventory_items').select().eq('home_id', homeId),
      client.from('ready_meals').select().eq('home_id', homeId),
      client.from('recipes').select().eq('home_id', homeId),
    ).wait;
    return pick(
      pantry: [
        for (final r in inv as List)
          InventoryItem.fromMap(Map<String, dynamic>.from(r)),
      ],
      readyMeals: [
        for (final r in ready as List)
          ReadyMeal.fromMap(Map<String, dynamic>.from(r)),
      ],
      recipes: [
        for (final r in recipes as List)
          Recipe.fromMap(Map<String, dynamic>.from(r)),
      ],
      currentRecipeId: currentRecipeId,
    );
  }

  /// Cambia la comida [entry] por lo elegido (un táper, un preparado, otra
  /// receta o, con [out], comer fuera). La receta que tocaba pasa al primer
  /// hueco libre de la semana; devuelve ese día, o null si no cabía.
  static Future<DateTime?> swap(
    SupabaseClient client, {
    required MealPlanEntry entry,
    InventoryItem? dish,
    ReadyMeal? ready,
    Recipe? recipe,
    bool out = false,
  }) async {
    final id = entry.id;
    if (id == null) return null;
    await client
        .from('meal_plan_entries')
        .update({
          'skipped': out,
          'from_freezer': dish != null,
          'inventory_item_id': dish?.id,
          'ready_meal_id': ready?.id,
          'recipe_id': out ? entry.recipeId : (dish?.recipeId ?? recipe?.id),
        })
        .eq('id', id);

    final moved = entry.recipeId;
    if (moved == null || entry.fromFreezer) return null;
    final week = await client
        .from('meal_plan_entries')
        .select('plan_date, meal_type')
        .eq('home_id', entry.homeId)
        .eq('meal_type', entry.mealType)
        .gt('plan_date', _day(entry.date))
        .lte('plan_date', _day(entry.date.add(const Duration(days: 7))));
    final free = nextFreeDay(
      from: entry.date,
      mealType: entry.mealType,
      entries: [
        for (final r in week as List)
          MealPlanEntry.fromMap(Map<String, dynamic>.from(r)),
      ],
    );
    if (free == null) return null;
    await client
        .from('meal_plan_entries')
        .insert(
          MealPlanEntry(
            homeId: entry.homeId,
            date: free,
            mealType: entry.mealType,
            recipeId: moved,
            servings: entry.servings,
          ).toMap(),
        );
    return free;
  }
}
