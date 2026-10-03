import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/meal_plan_entry.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'services/household_servings.dart';
import 'services/meal_planner.dart';
import 'services/meal_prep_planner.dart';
import 'services/plan_adjuster.dart';
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
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  bool _generating = false;
  int _energyLevel = 1; // 0=cocinar poco, 1=normal, 2=cocinar mucho

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    final f = _load();
    setState(() {
      _future = f;
    });
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

    // Todos los perfiles del hogar, para calcular raciones por comida según
    // quién come en casa cada día. El usuario actual se muestra como "tú".
    final profilesRes = await _client
        .from('profiles')
        .select()
        .eq('home_id', homeId);
    final members = <HouseholdMember>[];
    // El plan de cocción (meal prep) solo se activa si ALGÚN perfil del hogar
    // cocina en modo 'mealprep'. En modo 'daily' no mostramos nada nuevo.
    var isMealPrep = myProfile.isMealPrep;
    for (final m in (profilesRes as List)) {
      final p = NutritionProfile.fromMap(m);
      if (p.isMealPrep) isMealPrep = true;
      final isMe = p.id == user.id;
      members.add(
        HouseholdMember(
          name: (p.fullName?.trim().isNotEmpty ?? false)
              ? p.fullName!.trim()
              : 'Alguien',
          isMe: isMe,
          mealsAtHome: p.mealsAtHome,
        ),
      );
    }
    // Garantizamos al menos al usuario actual (si profiles no lo devolviera).
    if (!members.any((m) => m.isMe)) {
      members.add(
        HouseholdMember(
          name: (myProfile.fullName?.trim().isNotEmpty ?? false)
              ? myProfile.fullName!.trim()
              : 'Alguien',
          isMe: true,
          mealsAtHome: myProfile.mealsAtHome,
        ),
      );
    }

    // Recetas del hogar
    final recRes = await _client.from('recipes').select().eq('home_id', homeId);
    final recipes = (recRes as List).map((m) => Recipe.fromMap(m)).toList();

    // Plan de esta semana
    final start = _weekStart;
    final end = start.add(const Duration(days: 7));
    final planRes = await _client
        .from('meal_plan_entries')
        .select()
        .eq('home_id', homeId)
        .gte('plan_date', start.toIso8601String().split('T').first)
        .lt('plan_date', end.toIso8601String().split('T').first);
    final entries = (planRes as List)
        .map((m) => MealPlanEntry.fromMap(m))
        .toList();

    return _PlanData(
      homeId: homeId,
      activeMeals: activeMeals.isEmpty ? ['lunch', 'dinner'] : activeMeals,
      recipes: recipes,
      recipesById: {for (final r in recipes) r.id: r},
      entries: entries,
      members: members,
      isMealPrep: isMealPrep,
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

      final frozenRecipeIds = freezerQueue.map((f) => f.recipeId).toSet();

      final planner = MealPlanner();
      final plan = planner.generate(
        startDate: _weekStart,
        days: 7,
        mealTypes: data.activeMeals,
        recipes: data.recipes,
        scoreByRecipe: scores,
        frozenRecipeIds: frozenRecipeIds,
        energyLevel: _energyLevel,
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
          // Raciones = personas que comen en casa ese día/comida.
          final servings = servingsCountForMeal(
            data.members,
            type,
            date.weekday,
          );
          rows.add(
            MealPlanEntry(
              homeId: data.homeId!,
              date: date,
              mealType: type,
              recipeId: recipeId,
              fromFreezer: frozen != null,
              inventoryItemId: frozen?.itemId,
              servings: servings,
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
  ///
  /// Al marcar "fuera" no se pierde el plato: el cerebro ([PlanAdjuster]) lo
  /// recoloca al primer hueco posterior libre del mismo tipo de comida y Miau
  /// explica qué hizo. Al reactivar simplemente se vuelve a dejar activo.
  Future<void> _toggleSkip(_PlanData data, MealPlanEntry e) async {
    if (e.id == null) return;
    final willSkip = !e.skipped;
    try {
      if (!willSkip) {
        // Reactivar: dejamos la comida de nuevo activa.
        await _client
            .from('meal_plan_entries')
            .update({'skipped': false})
            .eq('id', e.id!);
        if (mounted) {
          _showMiau('Vuelve a estar en casa, ¡qué bien!');
        }
        _reload();
        return;
      }

      // Marcar "fuera" + reajuste con la lógica pura del cerebro.
      final slots = _buildSlots(data);
      final before = {for (final s in slots) s.id: s};
      final adjustment = const PlanAdjuster().adjustForSkipped(slots, e.id!);

      // Metadatos del congelador del plato que se mueve (el del origen). Al
      // recolocarlo, deben VIAJAR al día destino y limpiarse en el origen, para
      // que no queden `from_freezer`/`inventory_item_id` huérfanos apuntando a
      // un plato que ya no está ahí. Las raciones NO viajan: cada día conserva
      // las suyas (calculadas para quién come en casa ese día).
      final movedToDate = adjustment.movedToDate;
      final movedFromFreezer = e.fromFreezer;
      final movedInventoryItemId = e.inventoryItemId;

      // Persistir solo las entradas que cambiaron (recipe_id/skipped y, si
      // procede, los metadatos del congelador).
      for (final slot in adjustment.slots) {
        final prev = before[slot.id];
        if (prev == null) continue;
        final recipeChanged = prev.recipeId != slot.recipeId;
        final skipChanged = prev.skipped != slot.skipped;
        final isOrigin = slot.id == e.id;
        final isDestination = movedToDate != null &&
            _isSameDay(slot.date, movedToDate) &&
            slot.mealType == e.mealType &&
            slot.recipeId == adjustment.movedRecipeId;
        if (!recipeChanged && !skipChanged && !isOrigin && !isDestination) {
          continue;
        }
        final update = <String, dynamic>{
          'recipe_id': slot.recipeId,
          'skipped': slot.skipped,
        };
        if (isOrigin) {
          // El plato deja de estar en el origen: limpiamos su vínculo con el
          // congelador/inventario para no dejar datos colgando.
          update['from_freezer'] = false;
          update['inventory_item_id'] = null;
        } else if (isDestination) {
          // El plato (y su posible origen congelado) viaja al destino.
          update['from_freezer'] = movedFromFreezer;
          update['inventory_item_id'] = movedInventoryItemId;
        }
        await _client
            .from('meal_plan_entries')
            .update(update)
            .eq('id', slot.id!);
      }

      if (mounted) {
        final title = data.recipesById[adjustment.movedRecipeId]?.title;
        _showMiau(miauMoveMessage(adjustment, recipeTitle: title));
      }
      _reload();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Convierte las entradas de la semana en huecos para el cerebro puro.
  /// Solo incluye las entradas reales (con id); el reajuste busca entre ellas
  /// el primer hueco posterior libre del mismo tipo de comida.
  List<PlanSlot> _buildSlots(_PlanData data) {
    return [
      for (final entry in data.entries)
        if (entry.id != null)
          PlanSlot(
            id: entry.id,
            date: entry.date,
            mealType: entry.mealType,
            recipeId: entry.recipeId,
            skipped: entry.skipped,
          ),
    ];
  }

  /// Muestra un mensaje cozy de Miau en un SnackBar.
  void _showMiau(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.wood,
        content: Row(
          children: [
            const MiauCharacter(mood: MiauMood.celebrating, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            heroTag: 'fab-meal-plan',
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

    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _energyCard(),
        const SizedBox(height: 12),
        if (data.isMealPrep) ...[
          _mealPrepCard(data),
          const SizedBox(height: 12),
        ],
        ...days.map((date) {
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
                                _servingsLine(data, e),
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
                            onPressed: () => _toggleSkip(data, e),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Construye el plan de cocción (meal prep) a partir de las entradas y las
  /// recetas ya cargadas en [_load]. No hace consultas: reutiliza todo.
  MealPrepPlan _buildMealPrepPlan(_PlanData data) {
    final prepRecipes = <String, PrepRecipe>{
      for (final r in data.recipes)
        r.id: PrepRecipe(
          id: r.id,
          title: r.title,
          freezable: r.freezable,
          freezerDays: r.freezerDays,
          prepTimeMinutes: r.prepTimeMinutes,
          cookTimeMinutes: r.cookTimeMinutes,
        ),
    };
    final meals = <PrepMeal>[
      for (final e in data.entries)
        // Solo entran comidas activas, con receta y con raciones > 0. Si una
        // entrada no tiene raciones (nulo o <=0) significa que no come nadie en
        // casa (o es un plan antiguo sin la columna): no la metemos en la
        // logística para no cocinar algo que no se va a comer.
        if (!e.skipped && e.recipeId != null && (e.servings ?? 0) > 0)
          PrepMeal(
            recipeId: e.recipeId!,
            date: e.date,
            mealType: e.mealType,
            servings: e.servings!,
          ),
    ];
    return const MealPrepPlanner().buildPlan(
      meals: meals,
      recipesById: prepRecipes,
      weekStart: _weekStart,
      energyLevel: _energyLevel,
    );
  }

  /// Tarjeta "Plan de cocción" con el resumen cozy de Miau. Solo se muestra en
  /// modo 'mealprep' (ver [_buildPlan]).
  Widget _mealPrepCard(_PlanData data) {
    final plan = _buildMealPrepPlan(data);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MiauCharacter(mood: MiauMood.cooking, size: 44),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Plan de cocción',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.isEmpty)
            Text(
              'Cuando tengas plan de la semana te digo qué cocinar en lote, '
              'qué guardar en la nevera y qué congelar.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            )
          else
            ...plan.cookingDays.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        Icons.outdoor_grill,
                        size: 16,
                        color: Color(0xFFB58A3C),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        resumenDiaCoccion(day),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _energyCard() {
    const labels = ['Cocinar poco', 'Normal', 'Cocinar mucho'];
    const subtitle = 'Con "cocinar poco" el plan tira más del congelador.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta semana',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final selected = _energyLevel == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: ChoiceChip(
                    label: Text(labels[i]),
                    selected: selected,
                    selectedColor: AppColors.wood,
                    backgroundColor: const Color(0xFFFDF8E1),
                    onSelected: (_) => setState(() => _energyLevel = i),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Línea de raciones por comida: "4 raciones: tú, Pablo". Si no hay miembros
  /// del hogar cargados, no mostramos nada.
  Widget _servingsLine(_PlanData data, MealPlanEntry e) {
    // Fuente de verdad: el nº de raciones PERSISTIDO en la entrada (e.servings),
    // que es el mismo que usa la logística de meal prep. Así la etiqueta visible
    // y el número almacenado no divergen. Solo si la entrada no trae raciones
    // (planes antiguos) caemos al cálculo en vivo según quién come en casa.
    final computed = data.members.isEmpty
        ? null
        : servingsForMeal(data.members, e.mealType, e.date.weekday);
    final persisted = e.servings;

    final String text;
    if (persisted != null) {
      if (persisted <= 0) return const SizedBox.shrink();
      // Mostramos el número persistido. Si el cálculo en vivo coincide, lo
      // acompañamos de los nombres ("tú, Pablo") para que quede cozy.
      if (computed != null &&
          computed.count == persisted &&
          computed.names.isNotEmpty) {
        text = computed.label;
      } else {
        final unit = persisted == 1 ? 'ración' : 'raciones';
        text = '$persisted $unit';
      }
    } else {
      // Sin raciones guardadas: fallback al cálculo en vivo.
      if (computed == null || computed.count == 0) {
        return const SizedBox.shrink();
      }
      text = computed.label;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline,
            size: 12,
            color: Color(0xFFB58A3C),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
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
  final List<HouseholdMember> members;

  /// true si algún perfil del hogar cocina en modo 'mealprep' (en lote). Solo
  /// entonces mostramos la sección "Plan de cocción".
  final bool isMealPrep;
  _PlanData({
    required this.homeId,
    this.activeMeals = const ['lunch', 'dinner'],
    this.recipes = const [],
    this.recipesById = const {},
    this.entries = const [],
    this.members = const [],
    this.isMealPrep = false,
  });
}
