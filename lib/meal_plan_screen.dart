import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/meal_plan_entry.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'services/meal_planner.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

/// Planificador semanal de comidas (v1).
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_PlanData> _future;

  static const _mealLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Snack',
    'dessert': 'Postre',
  };
  static const _dayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    final f = _load();
    setState(() => _future = f);
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    // Lunes de esta semana
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  Future<_PlanData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return _PlanData(homeId: null);

    final myProfile = NutritionProfile.fromMap(profile!);
    // Comidas activas (con % > 0)
    final activeMeals = NutritionProfile.splitOrder
        .where((k) => (myProfile.mealSplit[k] ?? 0) > 0)
        .toList();

    // Recetas del hogar
    final recRes = await _client.from('recipes').select().eq('home_id', homeId);
    final recipes =
        (recRes as List).map((m) => Recipe.fromMap(m)).toList();

    // Plan de esta semana
    final start = _weekStart;
    final end = start.add(const Duration(days: 7));
    final planRes = await _client
        .from('meal_plan_entries')
        .select()
        .eq('home_id', homeId)
        .gte('plan_date', start.toIso8601String().split('T').first)
        .lt('plan_date', end.toIso8601String().split('T').first);
    final entries =
        (planRes as List).map((m) => MealPlanEntry.fromMap(m)).toList();

    return _PlanData(
      homeId: homeId,
      activeMeals: activeMeals.isEmpty ? ['lunch', 'dinner'] : activeMeals,
      recipes: recipes,
      recipesById: {for (final r in recipes) r.id: r},
      entries: entries,
    );
  }

  Future<void> _generatePlan(_PlanData data) async {
    setState(() => _generating = true);
    try {
      // Peso por receta a partir del feedback histórico.
      final fbRes = await _client
          .from('meal_plan_feedback')
          .select('recipe_id, action')
          .eq('home_id', data.homeId!);
      final scores = <String, int>{};
      for (final f in (fbRes as List)) {
        final id = f['recipe_id'] as String;
        scores[id] = (scores[id] ?? 0) + (f['action'] == 'accepted' ? 1 : -1);
      }

      // Platos ya congelados disponibles (kind='dish' en Congelador con receta).
      // Cada uno da para 'quantity' comidas de hogar. Los priorizamos.
      final freezerRes = await _client
          .from('inventory_items')
          .select('id, recipe_id, quantity, best_before')
          .eq('home_id', data.homeId!)
          .eq('category', 'Congelador')
          .eq('kind', 'dish')
          .not('recipe_id', 'is', null)
          .order('best_before', ascending: true, nullsFirst: false);
      // Cola de "comidas congeladas" disponibles: {recipeId, itemId} por unidad.
      final freezerQueue = <_FrozenMeal>[];
      for (final f in (freezerRes as List)) {
        final recipeId = f['recipe_id'] as String?;
        final itemId = f['id'] as String;
        final qty = (f['quantity'] as num?)?.toDouble() ?? 0;
        if (recipeId == null) continue;
        for (var i = 0; i < qty.floor(); i++) {
          freezerQueue.add(_FrozenMeal(recipeId: recipeId, itemId: itemId));
        }
      }

      final planner = MealPlanner();
      final plan = planner.generate(
        startDate: _weekStart,
        days: 7,
        mealTypes: data.activeMeals,
        recipes: data.recipes,
        scoreByRecipe: scores,
      );

      // Borrar el plan anterior de la semana y guardar el nuevo.
      final start = _weekStart;
      final end = start.add(const Duration(days: 7));
      await _client
          .from('meal_plan_entries')
          .delete()
          .eq('home_id', data.homeId!)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);

      // Recetas que SÍ tienen platos congelados, para preferir usarlas primero.
      final frozenByRecipe = <String, List<_FrozenMeal>>{};
      for (final fm in freezerQueue) {
        frozenByRecipe.putIfAbsent(fm.recipeId, () => []).add(fm);
      }

      final rows = <Map<String, dynamic>>[];
      plan.forEach((date, meals) {
        meals.forEach((type, recipeId) {
          // Si hay una unidad congelada de esta receta, la usamos (del congelador).
          _FrozenMeal? frozen;
          final pool = frozenByRecipe[recipeId];
          if (pool != null && pool.isNotEmpty) {
            frozen = pool.removeAt(0);
          }
          rows.add(
            MealPlanEntry(
              homeId: data.homeId!,
              date: date,
              mealType: type,
              recipeId: recipeId,
              fromFreezer: frozen != null,
              inventoryItemId: frozen?.itemId,
            ).toMap(),
          );
        });
      });
      if (rows.isNotEmpty) {
        await _client.from('meal_plan_entries').insert(rows);
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Marca una comida como "hoy como fuera" (skip) o la reactiva.
  Future<void> _toggleSkip(MealPlanEntry e) async {
    if (e.id == null) return;
    await _client
        .from('meal_plan_entries')
        .update({'skipped': !e.skipped})
        .eq('id', e.id!);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Plan semanal')),
      body: FutureBuilder<_PlanData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return const Center(child: Text('No perteneces a ningún hogar.'));
          }
          if (data.recipes.isEmpty) {
            return _needRecipes();
          }
          return _buildPlan(data);
        },
      ),
      floatingActionButton: FutureBuilder<_PlanData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          if (data == null || data.homeId == null || data.recipes.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _generating ? null : () => _generatePlan(data),
            backgroundColor: AppColors.wood,
            foregroundColor: AppColors.ink,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              data.entries.isEmpty ? 'Generar plan' : 'Regenerar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _needRecipes() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 120),
            const SizedBox(height: 16),
            const Text(
              'Añade algunas recetas primero',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'El planificador reparte tus recetas por la semana. Guarda unas '
              'cuantas en la pestaña Comidas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlan(_PlanData data) {
    if (data.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiauCharacter(mood: MiauMood.greeting, size: 120),
              const SizedBox(height: 16),
              const Text(
                'Aún no hay plan para esta semana',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Pulsa "Generar plan" y la app repartirá tus recetas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Agrupar entries por fecha.
    final byDate = <String, List<MealPlanEntry>>{};
    for (final e in data.entries) {
      final key = e.date.toIso8601String().split('T').first;
      byDate.putIfAbsent(key, () => []).add(e);
    }

    final days = List.generate(
      7,
      (i) => _weekStart.add(Duration(days: i)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: days.map((date) {
        final key = date.toIso8601String().split('T').first;
        final dayEntries = byDate[key] ?? [];
        final isToday = _isSameDay(date, DateTime.now());

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _dayNames[date.weekday - 1],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isToday ? AppColors.woodDark : AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.wood,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Hoy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (dayEntries.isEmpty)
                Text(
                  'Sin comidas planificadas',
                  style: TextStyle(color: Colors.grey[500]),
                )
              else
                ...dayEntries.map((e) {
                  final recipe = data.recipesById[e.recipeId];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            _mealLabels[e.mealType] ?? e.mealType,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe?.title ?? 'Receta',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: e.skipped
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: e.skipped
                                      ? Colors.grey
                                      : AppColors.ink,
                                ),
                              ),
                              if (e.fromFreezer)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.ac_unit,
                                      size: 12,
                                      color: Color(0xFFB58A3C),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Del congelador',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Botón "como fuera" para reajuste dinámico
                        IconButton(
                          tooltip: e.skipped
                              ? 'Reactivar (como en casa)'
                              : 'Hoy como fuera',
                          icon: Icon(
                            e.skipped
                                ? Icons.restore
                                : Icons.no_meals_outlined,
                            size: 20,
                            color: e.skipped
                                ? AppColors.woodDark
                                : Colors.grey,
                          ),
                          onPressed: () => _toggleSkip(e),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _FrozenMeal {
  final String recipeId;
  final String itemId;
  _FrozenMeal({required this.recipeId, required this.itemId});
}

class _PlanData {
  final String? homeId;
  final List<String> activeMeals;
  final List<Recipe> recipes;
  final Map<String, Recipe> recipesById;
  final List<MealPlanEntry> entries;
  _PlanData({
    required this.homeId,
    this.activeMeals = const ['lunch', 'dinner'],
    this.recipes = const [],
    this.recipesById = const {},
    this.entries = const [],
  });
}
