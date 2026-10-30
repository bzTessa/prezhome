import 'dart:async';

import 'package:device_calendar_plus/device_calendar_plus.dart' show Calendar;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'batch_prep_timeline_screen.dart';
import 'models/dashboard_prefs.dart';
import 'models/inventory_item.dart';
import 'models/meal_plan_entry.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'month_calendar_screen.dart';
import 'services/calendar_sync.dart';
import 'services/household_servings.dart';
import 'services/meal_planner.dart';
import 'services/meal_prep_planner.dart';
import 'services/plan_adjuster.dart';
import 'services/plan_prefs.dart';
import 'services/plan_repeats.dart';
import 'services/plan_prep.dart';
import 'services/plan_shopping.dart';
import 'shopping_list_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/animations/press_scale.dart';
import 'widgets/miau_character.dart';
import 'widgets/tactile_button.dart';
import 'widgets/plan/plan_parts.dart';
import 'widgets/recipe_image.dart';
import 'widgets/segmented_pill.dart';
import 'utils/friendly_error.dart';
import 'widgets/skeleton.dart';
import 'l10n/l10n.dart';

/// Planificador semanal de comidas (v1).
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key, this.embedded = false});

  /// Dentro de la pestaña Comidas: sin barra propia.
  final bool embedded;

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_PlanData> _future;

  static const _mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
  ];

  String get _locale => Localizations.localeOf(context).toString();

  /// "Lunes 3" en el idioma de la app.
  String _dayLabel(DateTime d) {
    final name = DateFormat.EEEE(_locale).format(d);
    return '${name[0].toUpperCase()}${name.substring(1)} ${d.day}';
  }

  bool _generating = false;
  int get _energyLevel => PlanPrefs.current.value.energy;

  // Día elegido en la tira de la semana (0 = lunes). null = hoy.
  int? _selectedDay;

  // Semanas desde la actual (0 = esta, 1 = la próxima…).
  int _weekOffset = 0;

  // Vista de la semana entera en vez de un solo día.
  bool _weekView = false;

  void _moveWeek(int delta) {
    _weekOffset += delta;
    _selectedDay = null;
    _reload();
  }

  /// Lleva el plan a la semana y el día de [day] (p. ej. desde el calendario).
  void _goToDay(DateTime day) {
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    _weekOffset += (monday.difference(_weekStart).inHours / (24 * 7)).round();
    _selectedDay = day.weekday - 1;
    _weekView = false;
    _reload();
  }

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
    // Lunes de la semana mostrada
    return DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1) + 7 * _weekOffset,
    );
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
    unawaited(CalendarSync.sync(_client));

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

    // Plan de esta semana, con las comidas que se repiten ya puestas.
    final start = _weekStart;
    final end = start.add(const Duration(days: 7));
    await PlanRepeats.fill(
      _client,
      homeId,
      end,
      servingsFor: (type, d) => servingsCountForMeal(members, type, d.weekday),
    );
    final planRes = await _client
        .from('meal_plan_entries')
        .select()
        .eq('home_id', homeId)
        .gte('plan_date', start.toIso8601String().split('T').first)
        .lt('plan_date', end.toIso8601String().split('T').first);
    final entries = (planRes as List)
        .map((m) => MealPlanEntry.fromMap(m))
        .toList();
    // En tandas, las semanas siguientes pueden sacar del congelador lo que se
    // cocina en esta (planes de varias semanas).
    final later = !isMealPrep
        ? const <MealPlanEntry>[]
        : [
            for (final m
                in await _client
                        .from('meal_plan_entries')
                        .select()
                        .eq('home_id', homeId)
                        .gte(
                          'plan_date',
                          end.toIso8601String().split('T').first,
                        )
                        .lt(
                          'plan_date',
                          end
                              .add(const Duration(days: 63))
                              .toIso8601String()
                              .split('T')
                              .first,
                        )
                    as List)
              MealPlanEntry.fromMap(m),
          ];

    return _PlanData(
      homeId: homeId,
      activeMeals: activeMeals.isEmpty ? ['lunch', 'dinner'] : activeMeals,
      recipes: recipes,
      recipesById: {for (final r in recipes) r.id: r},
      entries: entries,
      laterEntries: later,
      members: members,
      isMealPrep: isMealPrep,
      prefs: switch (profile['dashboard_prefs']) {
        final Map m => DashboardPrefs.fromJson(Map<String, dynamic>.from(m)),
        _ => null,
      },
    );
  }

  /// ¿Para cuánto tiempo hacer el plan? Una semana, dos, un mes o las fechas
  /// que se elijan. Empieza en el lunes de la semana que se está viendo.
  Future<void> _askPlanRange(_PlanData data) async {
    final weeks = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                context.l.planHowLong,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            for (final (n, label) in [
              (1, context.l.thisWeek),
              (2, context.l.planWeeks(2)),
              (4, context.l.planMonth4),
            ])
              ListTile(
                leading: Icon(
                  Icons.date_range_rounded,
                  color: AppColors.woodDark,
                ),
                title: Text(label),
                onTap: () => Navigator.of(ctx).pop(n),
              ),
            ListTile(
              leading: Icon(
                Icons.edit_calendar_rounded,
                color: AppColors.woodDark,
              ),
              title: Text(context.l.planPickDates),
              onTap: () => Navigator.of(ctx).pop(0),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || weeks == null) return;
    if (weeks > 0) {
      return _generatePlan(data, _weekStart, weeks * 7);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: context.l.planDates,
    );
    if (range == null || !mounted) return;
    final days = range.end.difference(range.start).inDays + 1;
    if (days > 62) {
      _showMiau(context.l.planMaxTwoMonths);
      return;
    }
    await _generatePlan(data, range.start, days);
  }

  Future<void> _generatePlan(_PlanData data, DateTime start, int days) async {
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

      // Solo recetas que se pueden hacer con los aparatos que tiene.
      final cookable = data.recipes
          .where((r) => data.prefs.canCook(r.appliance))
          .toList();
      final planner = MealPlanner();
      final plan = planner.generate(
        startDate: start,
        days: days,
        mealTypes: PlanPrefs.current.value.planned(data.activeMeals),
        recipes: cookable.isEmpty ? data.recipes : cookable,
        scoreByRecipe: scores,
        frozenRecipeIds: frozenRecipeIds,
        energyLevel: _energyLevel,
        batch: data.isMealPrep,
      );

      // Borrar el plan anterior de esas fechas y guardar el nuevo.
      final end = start.add(Duration(days: days));
      // Las comidas que se repiten se quedan y el plan llena el resto.
      await _client
          .from('meal_plan_entries')
          .delete()
          .eq('home_id', data.homeId!)
          .isFilter('repeat_id', null)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);
      await PlanRepeats.fill(
        _client,
        data.homeId!,
        end,
        servingsFor: (type, d) =>
            servingsCountForMeal(data.members, type, d.weekday),
      );
      final keptRes = await _client
          .from('meal_plan_entries')
          .select('plan_date, meal_type')
          .eq('home_id', data.homeId!)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);
      final kept = {
        for (final k in keptRes as List) '${k['plan_date']}|${k['meal_type']}',
      };

      // Recetas que SÍ tienen platos congelados, para preferir usarlas primero.
      final frozenByRecipe = <String, List<_FrozenMeal>>{};
      for (final fm in freezerQueue) {
        frozenByRecipe.putIfAbsent(fm.recipeId, () => []).add(fm);
      }

      // Plan en tandas de varias semanas: lo que se congela bien se cocina la
      // primera semana que sale y las siguientes veces sale del congelador.
      final stockFreezer = data.isMealPrep && days > 7;
      final firstCookWeek = <String, DateTime>{};
      DateTime monday(DateTime d) =>
          DateTime(d.year, d.month, d.day - (d.weekday - 1));

      final rows = <Map<String, dynamic>>[];
      plan.forEach((date, meals) {
        meals.forEach((type, recipeId) {
          final day = date.toIso8601String().split('T').first;
          if (kept.contains('$day|$type')) return;
          // Si hay una unidad congelada de esta receta, la usamos (del congelador).
          _FrozenMeal? frozen;
          final pool = frozenByRecipe[recipeId];
          if (pool != null && pool.isNotEmpty) {
            frozen = pool.removeAt(0);
          }
          var fromFreezer = frozen != null;
          if (!fromFreezer &&
              stockFreezer &&
              (data.recipesById[recipeId]?.freezesWell ?? false)) {
            final week = firstCookWeek.putIfAbsent(
              recipeId,
              () => monday(date),
            );
            fromFreezer = monday(date).isAfter(week);
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
              fromFreezer: fromFreezer,
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
      if (rows.isNotEmpty) {
        await _fillShoppingFromPlan(data.homeId!, start, end);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// La lista de la compra se hace sola con el plan nuevo: lo que piden las
  /// recetas menos lo que ya hay en casa, con foto de cada producto.
  Future<void> _fillShoppingFromPlan(
    String homeId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final service = PlanShoppingService(_client);
      final added = await service.syncFromPlan(
        homeId: homeId,
        from: from,
        to: to,
      );
      if (added.isNotEmpty) {
        unawaited(service.fillMissingPhotos(homeId, added));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added.isEmpty
                ? context.l.planReadyAllHome
                : context.l.planListReady(added.length),
          ),
          persist: false,
          action: added.isEmpty
              ? null
              : SnackBarAction(
                  label: context.l.view,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ShoppingListScreen(),
                    ),
                  ),
                ),
        ),
      );
    } catch (e) {
      debugPrint('MealPlanScreen._fillShoppingFromPlan error: $e');
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
          _showMiau(context.l.planBackInPlan);
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
        final isDestination =
            movedToDate != null &&
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
          SnackBar(
            content: Text('Error: $err'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  // --- EDICIÓN MANUAL DEL PLAN ----------------------------------------------

  /// Menú de acciones al tocar una comida del plan: cambiar receta, quitarla
  /// del plan o marcarla como fuera/en casa.
  Future<void> _openEntryActions(_PlanData data, MealPlanEntry e) async {
    final recipe = data.recipesById[e.recipeId];
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                context.l.planEntryTitle(
                  context.l.mealType(e.mealType),
                  recipe?.title ?? context.l.planNoRecipe,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.woodDark,
              ),
              title: Text(context.l.planChangeRecipe),
              onTap: () => Navigator.of(ctx).pop('change'),
            ),
            if (data.members.length > 1 && !e.skipped)
              ListTile(
                leading: Icon(
                  Icons.people_outline_rounded,
                  color: AppColors.woodDark,
                ),
                title: Text(context.l.planWhoEats),
                onTap: () => Navigator.of(ctx).pop('who'),
              ),
            ListTile(
              leading: Icon(
                e.skipped ? Icons.restore : Icons.no_meals_outlined,
                color: AppColors.woodDark,
              ),
              title: Text(
                e.skipped ? context.l.planMarkHome : context.l.planMarkOut,
              ),
              onTap: () => Navigator.of(ctx).pop('skip'),
            ),
            if (e.repeatId != null)
              ListTile(
                leading: Icon(
                  Icons.repeat_on_rounded,
                  color: AppColors.woodDark,
                ),
                title: Text(context.l.planStopRepeat),
                subtitle: Text(context.l.planStopRepeatHint),
                onTap: () => Navigator.of(ctx).pop('unrepeat'),
              )
            else if (recipe != null && e.id != null)
              ListTile(
                leading: Icon(Icons.repeat_rounded, color: AppColors.woodDark),
                title: Text(context.l.planRepeat),
                subtitle: Text(context.l.planRepeatHint),
                onTap: () => Navigator.of(ctx).pop('repeat'),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.expired),
              title: Text(context.l.planRemove),
              onTap: () => Navigator.of(ctx).pop('remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'change':
        await _changeRecipe(data, e);
        break;
      case 'who':
        await _chooseDiners(data, e);
        break;
      case 'skip':
        await _toggleSkip(data, e);
        break;
      case 'remove':
        await _removeEntry(e);
        break;
      case 'repeat':
        await _repeatEntry(data, e);
        break;
      case 'unrepeat':
        try {
          await PlanRepeats.stop(_client, e.repeatId!);
          _reload();
        } catch (err) {
          _showError(err);
        }
        break;
    }
  }

  /// Repite esta comida cada N días, hasta una fecha o para siempre.
  Future<void> _repeatEntry(_PlanData data, MealPlanEntry e) async {
    var every = 1;
    int? months; // null = para siempre
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget chip(String label, bool selected, VoidCallback onTap) =>
              ChoiceChip(
                label: Text(label),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.wood,
                backgroundColor: AppColors.card,
                onSelected: (_) => setSheet(onTap),
              );
          Widget label(String text) => Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l.planRepeatTitle(context.l.mealType(e.mealType)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  label(context.l.planHowOften),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (n, text) in [
                        (1, context.l.planEveryDays(1)),
                        (2, context.l.planEveryDays(2)),
                        (3, context.l.planEveryDays(3)),
                        (7, context.l.planEveryWeeks(1)),
                        (14, context.l.planEveryWeeks(2)),
                      ])
                        chip(text, every == n, () => every = n),
                    ],
                  ),
                  label(context.l.planUntilWhen),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (n, text) in [
                        (null, context.l.planForever),
                        (1, context.l.planMonths(1)),
                        (3, context.l.planMonths(3)),
                      ])
                        chip(text, months == n, () => months = n),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TactileButton(
                      label: context.l.planRepeat,
                      icon: Icons.repeat_rounded,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await PlanRepeats.create(
        _client,
        homeId: data.homeId!,
        entryId: e.id!,
        recipeId: e.recipeId!,
        mealType: e.mealType,
        start: e.date,
        everyDays: every,
        end: months == null
            ? null
            : DateTime(e.date.year, e.date.month + months!, e.date.day),
      );
      if (mounted) _showMiau(context.l.planRepeatDone);
      _reload();
    } catch (err) {
      _showError(err);
    }
  }

  /// Quién come esta comida (p. ej. alguien come fuera ese día). Guarda las
  /// raciones y el plan de cocina en lote se recalcula con ellas. Si no come
  /// nadie, la comida pasa a "fuera" y se recoloca.
  Future<void> _chooseDiners(_PlanData data, MealPlanEntry e) async {
    final eating = [
      for (final m in data.members) m.eatsAtHome(e.mealType, e.date.weekday),
    ];
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  context.l.planWhoAtHome,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              for (var i = 0; i < data.members.length; i++)
                CheckboxListTile(
                  value: eating[i],
                  activeColor: AppColors.woodDark,
                  title: Text(_capitalize(data.members[i].label)),
                  onChanged: (v) => setSheet(() => eating[i] = v ?? false),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(context.l.save),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final count = eating.where((x) => x).length;
    if (count == 0) return _toggleSkip(data, e);
    try {
      await _client
          .from('meal_plan_entries')
          .update({'servings': count})
          .eq('id', e.id!);
      _reload();
    } catch (err) {
      _showError(err);
    }
  }

  /// Elige el calendario del móvil donde se pasan comidas y tareas.
  Future<Calendar?> _pickCalendar(BuildContext ctx) async {
    final cals = await CalendarSync.writableCalendars();
    if (!ctx.mounted) return null;
    if (cals.isEmpty) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(ctx.l.planCalendarPermission)));
      return null;
    }
    return showModalBottomSheet<Calendar>(
      context: ctx,
      backgroundColor: AppColors.cream,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final cal in cals)
              ListTile(
                leading: Icon(Icons.circle, color: cal.color, size: 14),
                title: Text(cal.name),
                onTap: () => Navigator.pop(c, cal),
              ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Ajustes del plan, a un toque pero fuera de la vista: qué comidas se ven,
  /// a qué hora, ayuno, calendario y si se cocina en tanda.
  Future<void> _openPlanSettings(_PlanData data) async {
    var prefs = PlanPrefs.current.value;
    final hidden = {...prefs.hidden};
    final times = {...prefs.times};
    var fast = prefs.fastHours;
    var calendarId = prefs.calendarId;
    String? calendarName;
    var batch = data.isMealPrep;
    const fasts = [null, 12, 14, 16];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final draft = prefs.copyWith(times: times, fastHours: () => fast);
          final window = draft.eatingWindow;
          Widget mealSwitch(String type) => SwitchListTile(
            value: !hidden.contains(type),
            activeThumbColor: AppColors.woodDark,
            title: Text(context.l.mealType(type)),
            onChanged: (v) =>
                setSheet(() => v ? hidden.remove(type) : hidden.add(type)),
          );
          Widget mealTime(String type) => ListTile(
            dense: true,
            title: Text(context.l.mealType(type)),
            trailing: Text(
              draft.timeOf(type),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: draft.inFast(type)
                    ? AppColors.inkMuted
                    : AppColors.woodDark,
              ),
            ),
            subtitle: draft.inFast(type) ? Text(context.l.planInFast) : null,
            onTap: () async {
              final m = draft.minutesOf(type);
              final t = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
              );
              if (t != null) {
                setSheet(() => times[type] = t.hour * 60 + t.minute);
              }
            },
          );
          Widget title(String text) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
          );
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title(context.l.planSettings),
                    mealSwitch('breakfast'),
                    mealSwitch('snack'),
                    SwitchListTile(
                      value: batch,
                      activeThumbColor: AppColors.woodDark,
                      title: Text(context.l.planBatchCook),
                      subtitle: Text(context.l.planBatchCookHint),
                      onChanged: (v) => setSheet(() => batch = v),
                    ),
                    title(context.l.planTimes),
                    for (final t in _mainMealTypes)
                      if (!hidden.contains(t)) mealTime(t),
                    title(context.l.planFasting),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SegmentedPill(
                        labels: [context.l.no, '12:12', '14:10', '16:8'],
                        selected: fasts.indexOf(fast),
                        onChanged: (i) => setSheet(() => fast = fasts[i]),
                      ),
                    ),
                    if (window != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(
                          context.l.planEatWindow(
                            PlanPrefs.formatMinutes(window.start),
                            PlanPrefs.formatMinutes(window.end),
                          ),
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
                      ),
                    // En web no hay calendario del dispositivo al que escribir.
                    if (!kIsWeb) title(context.l.planCalendar),
                    if (!kIsWeb)
                      ListTile(
                        leading: const Icon(Icons.event_rounded),
                        title: Text(
                          calendarId == null
                              ? context.l.planToCalendar
                              : (calendarName ?? context.l.planCalendarLinked),
                        ),
                        subtitle: Text(
                          calendarId == null
                              ? context.l.planCalendarHint
                              : context.l.planCalendarUpdates,
                        ),
                        trailing: calendarId == null
                            ? null
                            : TextButton(
                                onPressed: () =>
                                    setSheet(() => calendarId = null),
                                child: Text(context.l.remove),
                              ),
                        onTap: () async {
                          final cal = await _pickCalendar(ctx);
                          if (cal != null) {
                            setSheet(() {
                              calendarId = cal.id;
                              calendarName = cal.name;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    prefs = prefs.copyWith(
      hidden: hidden,
      times: times,
      fastHours: () => fast,
      calendarId: () => calendarId,
    );
    await PlanPrefs.save(prefs);
    if (calendarId != null) {
      CalendarSync.sync(_client, force: true);
    }
    if (batch != data.isMealPrep) {
      try {
        await _client
            .from('profiles')
            .update({'cooking_mode': batch ? 'mealprep' : 'daily'})
            .eq('id', _client.auth.currentUser!.id);
      } catch (err) {
        _showError(err);
      }
      _reload();
    } else if (mounted) {
      setState(() {});
    }
  }

  /// Abre un selector de recetas y asigna la elegida a la comida [e]. Al cambiar
  /// la receta a mano, limpiamos el vínculo con el congelador (deja de ser "del
  /// congelador") porque el plato ya no es el mismo.
  Future<void> _changeRecipe(_PlanData data, MealPlanEntry e) async {
    if (e.id == null) return;
    final chosen = await _pickRecipe(data, title: context.l.planPickRecipe);
    if (chosen == null) return;
    try {
      await _client
          .from('meal_plan_entries')
          .update({
            'recipe_id': chosen.id,
            'from_freezer': false,
            'inventory_item_id': null,
            // Al reasignar, la comida vuelve a estar "en casa".
            'skipped': false,
          })
          .eq('id', e.id!);
      _reload();
    } catch (err) {
      _showError(err);
    }
  }

  /// Elimina una comida del plan.
  Future<void> _removeEntry(MealPlanEntry e) async {
    if (e.id == null) return;
    try {
      await _client.from('meal_plan_entries').delete().eq('id', e.id!);
      _reload();
    } catch (err) {
      _showError(err);
    }
  }

  /// Añade una comida nueva a un día concreto. Pide tipo de comida (solo entre
  /// los que no existen ya ese día, por el UNIQUE home/día/tipo) y una receta.
  Future<void> _addEntryToDay(
    _PlanData data,
    DateTime date,
    List<MealPlanEntry> dayEntries, {
    String? presetMealType,
  }) async {
    final usados = dayEntries.map((e) => e.mealType).toSet();
    final disponibles = _mealTypes.where((t) => !usados.contains(t)).toList();
    if (disponibles.isEmpty) {
      _showMiau(context.l.planDayFull);
      return;
    }

    // Desde un hueco concreto (p. ej. "Cena") ya sabemos el tipo.
    final mealType =
        presetMealType ??
        await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppColors.cream,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    context.l.planWhichMeal,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                for (final t in disponibles)
                  ListTile(
                    title: Text(context.l.mealType(t)),
                    onTap: () => Navigator.of(ctx).pop(t),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
    if (!mounted || mealType == null) return;

    final chosen = await _pickRecipe(data, title: context.l.planPickRecipe);
    if (chosen == null) return;

    try {
      final servings = servingsCountForMeal(
        data.members,
        mealType,
        date.weekday,
      );
      await _client
          .from('meal_plan_entries')
          .insert(
            MealPlanEntry(
              homeId: data.homeId!,
              date: date,
              mealType: mealType,
              recipeId: chosen.id,
              servings: servings,
            ).toMap(),
          );
      _reload();
    } catch (err) {
      _showError(err);
    }
  }

  /// Bottom sheet con buscador para elegir una receta del hogar. Devuelve la
  /// receta elegida o null si se cancela.
  Future<Recipe?> _pickRecipe(_PlanData data, {required String title}) {
    return showModalBottomSheet<Recipe>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RecipePickerSheet(title: title, recipes: data.recipes),
    );
  }

  void _showError(Object err) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $err'),
        backgroundColor: AppColors.expired,
      ),
    );
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
                style: TextStyle(
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
      appBar: widget.embedded ? null : AppBar(title: Text(context.l.planTitle)),
      body: FutureBuilder<_PlanData>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          // Al cambiar de semana se queda lo anterior con una barrita, sin
          // parpadeo de pantalla en blanco.
          if (loading && !snapshot.hasData) {
            return const PlanSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return Center(child: Text(context.l.planNoHome));
          }
          if (data.recipes.isEmpty) {
            return _needRecipes();
          }
          return Stack(
            children: [
              _buildPlan(data, loading: loading),
              if (loading) const LinearProgressIndicator(minHeight: 2),
            ],
          );
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
            onPressed: _generating ? null : () => _askPlanRange(data),
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_available_rounded),
            label: Text(
              data.entries.isEmpty ? context.l.planMake : context.l.planRemake,
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
            Text(
              context.l.planNeedRecipes,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              context.l.planNeedRecipesHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// Tipos de comida que siempre se ven como huecos del día.
  static const _mainMealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];

  /// Huecos de comida que se ven en un día: los principales (salvo los
  /// ocultos en ajustes, si están vacíos) y cualquier otro ya planificado.
  List<String> _slotTypes(Map<String, MealPlanEntry> byType) {
    final prefs = PlanPrefs.current.value;
    return [
      ..._mainMealTypes.where(
        (t) => !prefs.hidden.contains(t) || byType.containsKey(t),
      ),
      ...byType.keys.where((t) => !_mainMealTypes.contains(t)),
    ];
  }

  Future<void> _openCalendar() async {
    final day = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => const MonthCalendarScreen()),
    );
    if (day != null && mounted) _goToDay(day);
  }

  Widget _buildPlan(_PlanData data, {bool loading = false}) {
    // Agrupar entries por fecha.
    String keyOf(DateTime d) => d.toIso8601String().split('T').first;
    final byDate = <String, List<MealPlanEntry>>{};
    for (final e in data.entries) {
      byDate.putIfAbsent(keyOf(e.date), () => []).add(e);
    }

    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final now = DateTime.now();
    final todayIndex = days.indexWhere((d) => _isSameDay(d, now));
    final sel = (_selectedDay ?? (todayIndex < 0 ? 0 : todayIndex)).clamp(0, 6);
    final last = days.last;
    final range = days.first.month == last.month
        ? '${days.first.day} – ${DateFormat.MMMMd(_locale).format(last)}'
        : '${DateFormat.MMMMd(_locale).format(days.first)} – '
              '${DateFormat.MMMMd(_locale).format(last)}';
    final date = days[sel];
    final dayEntries = byDate[keyOf(date)] ?? const <MealPlanEntry>[];
    final byType = {for (final e in dayEntries) e.mealType: e};
    final prefs = PlanPrefs.current.value;
    final types = _slotTypes(byType);
    final prepPlan = data.isMealPrep ? _buildMealPrepPlan(data) : null;
    final agenda = prepPlan == null
        ? const <PrepEvent>[]
        : prepAgenda(prepPlan, earliest: _today);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: context.l.planPrevWeek,
              onPressed: () => _moveWeek(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: _weekOffset == 0 ? null : () => _goToDay(now),
                child: Column(
                  children: [
                    Text(
                      switch (_weekOffset) {
                        0 => context.l.thisWeek,
                        1 => context.l.planNextWeekLabel,
                        -1 => context.l.planLastWeek,
                        _ => context.l.planWeek,
                      },
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.woodDark,
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (_weekOffset != 0)
                      Text(
                        context.l.planBackToToday,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: context.l.planNextWeek,
              onPressed: () => _moveWeek(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedPill(
                labels: [context.l.planDay, context.l.planWeek],
                selected: _weekView ? 1 : 0,
                onChanged: (i) => setState(() => _weekView = i == 1),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: context.l.planMonthCalendar,
              icon: Icon(
                Icons.calendar_month_outlined,
                color: AppColors.inkMuted,
              ),
              onPressed: _openCalendar,
            ),
            IconButton(
              tooltip: context.l.planSettings,
              icon: Icon(Icons.tune_rounded, color: AppColors.inkMuted),
              onPressed: () => _openPlanSettings(data),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_weekView)
          for (var i = 0; i < 7; i++)
            _weekDayCard(
              data,
              days[i],
              byDate[keyOf(days[i])] ?? const [],
              i,
              isToday: i == todayIndex,
            ),
        if (!_weekView) ...[
          WeekDayStrip(
            days: days,
            selected: sel,
            today: now,
            mealsPerDay: [
              for (final d in days)
                (byDate[keyOf(d)] ?? const []).where((e) => !e.skipped).length,
            ],
            onSelect: (i) => setState(() => _selectedDay = i),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _dayLabel(date),
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              if (sel == todayIndex) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.wood,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.l.today,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (final ev in agenda)
            if (_isSameDay(ev.date, date))
              PrepEventTile(event: ev, batches: _batchesFor(prepPlan, ev)),
          if (data.entries.isEmpty && !loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                context.l.planNoPlanYet,
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ),
          for (final t in types)
            () {
              final e = byType[t];
              final recipe = e == null ? null : data.recipesById[e.recipeId];
              return MealSlotCard(
                mealType: t,
                time: prefs.timeOf(t),
                inFast: prefs.inFast(t),
                title: e == null ? null : (recipe?.title ?? context.l.recipe),
                image: recipe == null
                    ? null
                    : RecipeImage(
                        recipe: recipe,
                        width: 64,
                        height: 64,
                        radius: 18,
                      ),
                detail: e == null ? null : _servingsLine(data, e),
                skipped: e?.skipped ?? false,
                fromFreezer: e?.fromFreezer ?? false,
                onTap: e == null
                    ? () => _addEntryToDay(
                        data,
                        date,
                        dayEntries,
                        presetMealType: t,
                      )
                    : () => _openEntryActions(data, e),
              );
            }(),
        ],
        const SizedBox(height: 12),
        Text(
          context.l.thisWeek,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        _energyCard(),
        const SizedBox(height: 12),
        if (data.isMealPrep) ...[
          _mealPrepCard(data, prepPlan!, agenda),
          const SizedBox(height: 12),
        ],
        if (_plannedRecipes(data).isNotEmpty) _cookModeCard(data),
      ],
    );
  }

  /// Un día en la vista de semana: sus comidas en una línea cada una. Tocar
  /// una comida abre sus acciones (o añade si está vacía); tocar el día lo abre.
  Widget _weekDayCard(
    _PlanData data,
    DateTime date,
    List<MealPlanEntry> dayEntries,
    int index, {
    required bool isToday,
  }) {
    final byType = {for (final e in dayEntries) e.mealType: e};
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: AppTheme.cardDecoration(radius: AppRadius.lg),
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => setState(() {
                _selectedDay = index;
                _weekView = false;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _dayLabel(date),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.l.today,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.inkMuted),
                  ],
                ),
              ),
            ),
            for (final t in _slotTypes(byType))
              () {
                final e = byType[t];
                final s = mealStyle(t);
                final title = e == null
                    ? null
                    : (data.recipesById[e.recipeId]?.title ?? context.l.recipe);
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: e == null
                      ? () => _addEntryToDay(
                          data,
                          date,
                          dayEntries,
                          presetMealType: t,
                        )
                      : () => _openEntryActions(data, e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(s.icon, size: 16, color: s.fg),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 76,
                          child: Text(
                            context.l.mealType(t),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: s.fg,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title ?? context.l.add,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: title == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: title == null || e!.skipped
                                  ? AppColors.inkMuted
                                  : AppColors.ink,
                              decoration: e?.skipped ?? false
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (e?.fromFreezer ?? false)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.ac_unit_rounded,
                              size: 14,
                              color: AppColors.frost,
                            ),
                          ),
                        if (e == null)
                          Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.inkMuted,
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }

  /// Construye el plan de cocción (meal prep) a partir de las entradas y las
  /// recetas ya cargadas en [_load]. No hace consultas: reutiliza todo.
  /// Recetas con comidas planificadas esta semana (no "fuera", con receta),
  /// resueltas vía [_PlanData.recipesById] y DEDUPLICADAS por id. Es lo que
  /// alimenta el "Modo cocina" (orquestador de batch cooking). Determinista:
  /// recorre [data.entries] en orden y conserva la primera aparición de cada
  /// receta.
  List<Recipe> _plannedRecipes(_PlanData data) {
    final seen = <String>{};
    final result = <Recipe>[];
    for (final e in data.entries) {
      if (e.skipped) continue;
      final id = e.recipeId;
      if (id == null || !seen.add(id)) continue;
      final recipe = data.recipesById[id];
      if (recipe != null) result.add(recipe);
    }
    return result;
  }

  /// Acceso cozy al "Modo cocina": abre [BatchPrepTimelineScreen] con las
  /// recetas planificadas de la semana para cocinarlas en lote con una línea de
  /// tiempo unificada y temporizadores en vivo. Solo se muestra cuando hay
  /// recetas planificadas (ver [_buildPlan]); la pantalla destino tiene su
  /// propio empty state de todos modos.
  ///
  /// Cuando el Paso 2 (HomeModule.batchCooking) esté en main, además de este
  /// acceso se podrá exponer como pestaña en main_shell.dart gateada por
  /// prefs.isModuleEnabled(HomeModule.batchCooking). En este paso no se toca
  /// main_shell.dart para evitar colisión con el Paso 2.
  Widget _cookModeCard(_PlanData data) {
    return PressScale(
      onTap: () {
        // Con plan de cocción se cocina lo del próximo día de tanda, con su
        // reparto en tápers; si no, todo lo planificado de la semana.
        final today = DateUtils.dateOnly(DateTime.now());
        final day = data.isMealPrep
            ? _buildMealPrepPlan(
                data,
              ).cookingDays.where((d) => !d.date.isBefore(today)).firstOrNull
            : null;
        final ids = day?.batches.map((b) => b.recipeId).toSet();
        final recipes = [
          for (final r in _plannedRecipes(data))
            if (ids == null || ids.contains(r.id)) r,
        ];
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BatchPrepTimelineScreen(
              recipes: recipes,
              batches: day?.batches ?? const [],
              cookDay: day?.date,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(radius: 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sageBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.outdoor_grill, color: AppColors.woodDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l.planCookMode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l.planCookWeek,
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }

  MealPrepPlan _buildMealPrepPlan(_PlanData data) => prepPlanForWeek(
    entries: [...data.entries, ...data.laterEntries],
    recipesById: data.recipesById,
    weekStart: _weekStart,
    energyLevel: _energyLevel,
  );

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Tarjeta "Cocina en lote": la agenda de la semana (compra, día de cocina
  /// con nevera/congelador por táper y qué pasar a la nevera cada víspera).
  /// Solo en modo tanda (ver [_buildPlan]).
  Widget _mealPrepCard(
    _PlanData data,
    MealPrepPlan plan,
    List<PrepEvent> agenda,
  ) {
    final cookDays = agenda.where((e) => e.kind == PrepEventKind.cocina);
    final recipes = {
      for (final d in plan.cookingDays)
        if (cookDays.any((e) => _isSameDay(e.date, d.date)))
          for (final b in d.batches) b.recipeId,
    }.length;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l.planBatch,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (recipes > 0)
                      Text(
                        context.l.planCookDays(cookDays.length, recipes),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (agenda.isEmpty)
            Text(
              context.l.planBatchEmpty,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            )
          else
            for (final ev in agenda) ...[
              PrepEventTile(
                event: ev,
                showDate: true,
                batches: _batchesFor(plan, ev),
              ),
              if (ev.kind == PrepEventKind.cocina)
                () {
                  final toFreeze = [
                    for (final d in plan.cookingDays)
                      if (_isSameDay(d.date, ev.date))
                        ...d.batches.where((b) => b.freezerServings > 0),
                  ];
                  if (toFreeze.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 48, bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => _freezeBatches(data, toFreeze),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.woodDark,
                        side: BorderSide(color: AppColors.wood, width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.ac_unit, size: 16),
                      label: Text(
                        context.l.planCookedToFreezer,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }(),
            ],
        ],
      ),
    );
  }

  /// Tandas del día de cocina de [ev] (vacío si no es un día de cocina).
  List<PrepBatch> _batchesFor(MealPrepPlan? plan, PrepEvent ev) => [
    if (plan != null && ev.kind == PrepEventKind.cocina)
      for (final d in plan.cookingDays)
        if (_isSameDay(d.date, ev.date)) ...d.batches,
  ];

  /// Pasa a 'Congelados' las tandas indicadas: por cada receta congelable
  /// inserta un plato listo en el congelador con su FOTO y nombre de receta,
  /// las raciones calculadas y el consumo preferente (freezerDays). Deduplica
  /// contra platos ya congelados de la misma receta sumando raciones.
  Future<void> _freezeBatches(_PlanData data, List<PrepBatch> batches) async {
    try {
      final now = DateTime.now();
      // Platos ya congelados de estas recetas (para no duplicar).
      final existing = await _client
          .from('inventory_items')
          .select('id, recipe_id, quantity, servings')
          .eq('home_id', data.homeId!)
          .eq('category', 'Congelador')
          .eq('kind', 'dish');

      var count = 0;
      for (final b in batches) {
        final recipe = data.recipesById[b.recipeId];
        if (recipe == null) continue;
        final days = recipe.freezerDays ?? 90;
        final bestBefore = days > 0
            ? DateTime(now.year, now.month, now.day + days)
            : null;

        // ¿Ya hay un plato congelado de esta receta? Sumamos sus raciones.
        Map<String, dynamic>? found;
        for (final row in (existing as List)) {
          final m = row as Map<String, dynamic>;
          if (m['recipe_id'] == recipe.id) {
            found = m;
            break;
          }
        }

        if (found != null) {
          final prevQty = (found['quantity'] as num?)?.toDouble() ?? 0;
          final prevServ = (found['servings'] as num?)?.toDouble() ?? 0;
          await _client
              .from('inventory_items')
              .update({
                'quantity': prevQty + 1,
                'servings': prevServ + b.freezerServings,
              })
              .eq('id', found['id']);
        } else {
          final inv = InventoryItem(
            id: '',
            homeId: data.homeId!,
            name: recipe.title,
            category: 'Congelador',
            quantity: 1,
            unit: 'comidas',
            kind: 'dish',
            recipeId: recipe.id,
            servings: b.freezerServings.toDouble(),
            frozenOn: now,
            bestBefore: bestBefore,
            imageUrl: recipe.imageUrl,
          );
          await _client.from('inventory_items').insert(inv.toMap());
        }
        count++;
      }

      _reload();
      if (!mounted) return;
      _showMiau(context.l.planFrozen(count));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  Widget _energyCard() {
    final labels = [
      context.l.planEnergyLow,
      context.l.planEnergyNormal,
      context.l.planEnergyHigh,
    ];
    final subtitle = context.l.planEnergyHint;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.planHowMuchCook,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
                    backgroundColor: AppColors.cream,
                    onSelected: (_) async {
                      await PlanPrefs.save(
                        PlanPrefs.current.value.copyWith(energy: i),
                      );
                      if (mounted) setState(() {});
                    },
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
        text = context.l.planServings(persisted);
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
          Icon(Icons.people_outline, size: 12, color: AppColors.woodDark),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
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
  final List<MealPlanEntry> laterEntries;
  final List<HouseholdMember> members;

  /// true si algún perfil del hogar cocina en modo 'mealprep' (en lote). Solo
  /// entonces mostramos la sección "Plan de cocción".
  final bool isMealPrep;
  final DashboardPrefs prefs;
  _PlanData({
    required this.homeId,
    this.activeMeals = const ['lunch', 'dinner'],
    this.recipes = const [],
    this.recipesById = const {},
    this.entries = const [],
    this.laterEntries = const [],
    this.members = const [],
    this.isMealPrep = false,
    DashboardPrefs? prefs,
  }) : prefs = prefs ?? DashboardPrefs.defaults();
}

/// Bottom sheet para elegir una receta del hogar, con buscador por nombre.
/// Devuelve la receta elegida (Navigator.pop) o null si se cierra.
class _RecipePickerSheet extends StatefulWidget {
  final String title;
  final List<Recipe> recipes;
  const _RecipePickerSheet({required this.title, required this.recipes});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.recipes
        : widget.recipes
              .where((r) => r.title.toLowerCase().contains(q))
              .toList();

    return Padding(
      // Deja espacio para el teclado al buscar.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.l.planSearchRecipe,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.woodDark,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.wood, width: 1.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.woodDark,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        context.l.planNoMatch,
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final r = visible[i];
                        return Card(
                          color: AppColors.card,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.restaurant_menu,
                              color: AppColors.woodDark,
                            ),
                            title: Text(
                              r.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: r.calories != null
                                ? Text('${r.calories} kcal')
                                : null,
                            onTap: () => Navigator.of(context).pop(r),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
