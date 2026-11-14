import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../add_inventory_item_screen.dart';
import '../add_recipe_chooser.dart';
import '../discover_recipes_screen.dart';
import '../food_diary_screen.dart';
import '../household_screen.dart';
import '../main_shell.dart';
import '../profile_wizard_screen.dart';
import '../scan_ticket_screen.dart';
import '../shopping_list_screen.dart';
import '../stats_screen.dart';
import '../models/dashboard_prefs.dart';
import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../models/recipe.dart';
import '../models/nutrition_profile.dart';
import '../models/task.dart';
import '../services/pantry_usage.dart';
import '../services/plan_diary.dart';
import '../services/plan_repeats.dart';
import '../services/recipe_photo_audit.dart';
import '../services/taper_sync.dart';
import '../services/plan_prefs.dart';
import '../services/shopping_checkout.dart';
import '../services/task_scheduler.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_card.dart';
import '../widgets/fasting_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/miau_character.dart';
import '../widgets/plan/plan_parts.dart';
import '../widgets/recipe_image.dart';
import '../widgets/animations/animated_counter.dart';
import '../widgets/animations/celebrate.dart';
import '../widgets/animations/press_scale.dart';
import '../widgets/animations/staggered_entrance.dart';
import '../utils/day_brief.dart';
import '../utils/friendly_error.dart';
import '../utils/pantry_ideas.dart' show formatEuros;
import '../utils/ticket_date.dart';
import '../l10n/l10n.dart';

/// Pestaña de Inicio: dashboard con el resumen del día del hogar (comidas de
/// hoy, calorías, tareas y gasto). El plan semanal/mensual vive ahora en la
/// pestaña Comidas > Plan, así que Inicio solo muestra el resumen.
class HomeTab extends StatefulWidget {
  /// Petición de cambiar a la pestaña Despensa (sub-tab Inventario). La inyecta
  /// MainShell para que la tarjeta de caducidades aterrice donde el inventario
  /// vive de verdad, en lugar de abrir una InventoryScreen suelta.
  final VoidCallback? onNavigateToDespensa;

  /// Saltos a las pestañas Compra y Tareas desde los accesos de un vistazo.
  final VoidCallback? onNavigateToShopping;
  final VoidCallback? onNavigateToTasks;

  /// Lleva a Comidas > Plan, el único plan semanal.
  final VoidCallback? onNavigateToPlan;
  const HomeTab({
    super.key,
    this.onNavigateToDespensa,
    this.onNavigateToShopping,
    this.onNavigateToTasks,
    this.onNavigateToPlan,
  });

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final SupabaseClient _client = Supabase.instance.client;

  // Comidas planificadas para HOY (mismo patrón de consulta que el plan).
  List<_PlanItem> _todayItems = [];

  // Resumen de tareas pendientes del hogar (is_done == false).
  List<HomeTask> _pendingTasks = [];

  // Resumen de economía del mes en curso.
  double _monthSpent = 0;
  double _monthBudget = 0;

  // Resumen de calorías de hoy (diario de consumo personal).
  double _todayCalories = 0;
  int? _targetCalories;

  // ¿El perfil nutricional está completo? Si no lo está, invitamos a calcular
  // el objetivo de calorías con el cuestionario guiado.
  bool _profileComplete = true;

  // Resumen de caducidades del inventario de comida del hogar: cuántos
  // alimentos caducan pronto y cuántos ya han caducado.
  int _expired = 0;

  // Nombres de lo que caduca pronto, lo más urgente primero.
  List<String> _expiringNames = [];

  // Productos pendientes en la lista de la compra (para el acceso de un
  // vistazo).
  int _pendingShopping = 0;

  // Preferencias de personalización del dashboard (orden/visibilidad de
  // tarjetas y accesos rápidos). Por usuario, en profiles.dashboard_prefs.
  DashboardPrefs _prefs = DashboardPrefs.defaults();

  // Hasta la primera carga completa se ven esqueletos, no tarjetas a cero.
  bool _loaded = false;

  static const _mealOrder = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  /// Recarga los datos del dashboard. Lo llama MainShell cuando la pestaña
  /// Inicio vuelve a estar en primer plano, para reflejar un plan recién
  /// generado o un cuestionario completado sin recargar toda la app.
  void refreshActiveView() => _loadDashboard();

  /// Carga todas las secciones del dashboard. Cada carga tiene su propio
  /// try/catch, de modo que un fallo en una no impide ver las demás.
  // Nueva clave en cada recarga para que la racha se vuelva a leer.
  Key _streakKey = UniqueKey();

  Future<void> _loadDashboard() async {
    _profileFuture = null; // perfil fresco en cada recarga
    _streakKey = UniqueKey();
    await Future.wait([
      _loadPrefs(),
      _loadTodayPlan(),
      _loadTasksSummary(),
      _loadEconomySummary(),
      _loadCaloriesSummary(),
      _loadExpirySummary(),
      _loadPendingShopping(),
    ]);
    if (mounted && !_loaded) setState(() => _loaded = true);
  }

  // Todas las tarjetas leen la misma fila de perfil: una sola petición en vez
  // de una por tarjeta.
  Future<Map<String, dynamic>?>? _profileFuture;
  Future<Map<String, dynamic>?> _profile() => _profileFuture ??= _client
      .from('profiles')
      .select()
      .eq('id', _client.auth.currentUser!.id)
      .maybeSingle();

  /// Carga las preferencias del dashboard del usuario (orden/visibilidad de
  /// tarjetas y accesos rápidos). Si no hay, usa las por defecto.
  Future<void> _loadPrefs() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final row = await _profile();
      final raw = row?['dashboard_prefs'];
      final prefs = raw is Map
          ? DashboardPrefs.fromJson(Map<String, dynamic>.from(raw))
          : DashboardPrefs.defaults();
      if (mounted) setState(() => _prefs = prefs);
    } catch (e) {
      debugPrint('HomeTab._loadPrefs error: $e');
    }
  }

  /// Guarda las preferencias del dashboard en el perfil del usuario.
  Future<void> _savePrefs(DashboardPrefs prefs) async {
    setState(() => _prefs = prefs);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      await _client
          .from('profiles')
          .update({'dashboard_prefs': prefs.toJson()})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('HomeTab._savePrefs error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.couldNotSave)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  Future<void> _loadTodayPlan() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _profile();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      final todayKey = DateTime.now().toIso8601String().split('T').first;
      final res = await _client
          .from('meal_plan_entries')
          .select(
            'plan_date, meal_type, skipped, position, recipes(*), ready_meals(name)',
          )
          .eq('home_id', homeId)
          .eq('plan_date', todayKey);

      final items = <_PlanItem>[];
      final position = <_PlanItem, int>{}; // plato principal antes que postre
      for (final row in (res as List)) {
        final e = MealPlanEntry.fromMap(row);
        final rec = row['recipes'];
        Recipe? recipe;
        if (rec is Map<String, dynamic>) {
          try {
            recipe = Recipe.fromMap(rec);
          } catch (_) {}
        }
        final ready = row['ready_meals'];
        final title =
            (rec is Map ? rec['title'] : null) as String? ??
            (ready is Map ? ready['name'] : null) as String?;
        final item = _PlanItem(
          mealType: e.mealType,
          title: title ?? appL10n.recipe,
          skipped: e.skipped,
          fromFreezer: e.fromFreezer,
          recipe: recipe,
        );
        items.add(item);
        position[item] = e.position;
      }
      items.sort((a, b) {
        final byMeal = _mealOrder
            .indexOf(a.mealType)
            .compareTo(_mealOrder.indexOf(b.mealType));
        return byMeal != 0 ? byMeal : position[a]!.compareTo(position[b]!);
      });
      if (mounted) {
        setState(() => _todayItems = items);
      }
    } catch (e) {
      // No rompemos la UI (el resumen se ve sin plan), pero dejamos traza del
      // error para no confundir un fallo de carga con un dia sin plan.
      debugPrint('HomeTab._loadTodayPlan error: $e');
    }
  }

  /// Carga las tareas pendientes del hogar (mismo patrón de consulta que
  /// lib/tasks_screen.dart) y las guarda ordenadas por su proxima aparicion
  /// (next_due ?? due_date) ascendente; las que no tienen fecha van al final.
  Future<void> _loadTasksSummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _profile();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      final tasksRes = await _client
          .from('tasks')
          .select()
          .eq('home_id', homeId)
          .eq('is_done', false);
      final pending = (tasksRes as List)
          .map((m) => HomeTask.fromMap(m))
          .toList();

      // Ordenar por la proxima aparicion real (next_due o, por
      // compatibilidad, due_date), igual que _todayTasks/_taskWhen; las tareas
      // sin fecha van al final. Esto alinea el orden con el resto del flujo:
      // las filas backfilled por 0030 (con next_due adelantado y due_date
      // antiguo) se ordenan por cuando toca de verdad, no por la fecha vieja.
      pending.sort((a, b) {
        final da = a.nextDue ?? a.dueDate;
        final db = b.nextDue ?? b.dueDate;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      if (mounted) {
        setState(() {
          _pendingTasks = pending;
        });
      }
    } catch (e) {
      // No rompemos la UI (la tarjeta se ve vacía), pero dejamos traza del
      // error para no confundir un fallo de carga con un hogar sin tareas.
      debugPrint('HomeTab._loadTasksSummary error: $e');
    }
  }

  /// Tareas pendientes cuya proxima fecha (next_due o, por compatibilidad,
  /// due_date) es HOY o ya pasada, mas las que no tienen fecha (toca cuando se
  /// pueda). Son las que la usuaria puede marcar directamente desde el
  /// Dashboard.
  List<HomeTask> get _todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _pendingTasks.where((t) {
      final due = t.nextDue ?? t.dueDate;
      if (due == null) return true; // sin fecha: siempre a mano
      final d = DateTime(due.year, due.month, due.day);
      return !d.isAfter(today); // hoy o atrasada
    }).toList();
  }

  /// Completa una tarea directamente desde el Dashboard reutilizando la misma
  /// logica (puntos + reprogramacion) que la pantalla de Tareas, y refresca el
  /// resumen sin reiniciar la app.
  Future<void> _completeTaskFromDashboard(HomeTask task) async {
    try {
      HapticFeedback.lightImpact();
      await TaskScheduler(_client).complete(task);
      if (isShoppingTask(task.title)) {
        await ShoppingCheckout().markAllBoughtForCurrentUser();
      }
      if (mounted) {
        // Micro-celebración reutilizable (respeta reduce-motion: no hace nada
        // visible aparatoso) además del SnackBar de puntos existente.
        Celebrate.show(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l.homePointsSnack(task.points))),
        );
      }
      await _loadTasksSummary();
    } catch (e) {
      debugPrint('HomeTab._completeTaskFromDashboard error: $e');
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

  /// Calcula el gasto del mes en curso y el presupuesto, con la MISMA
  /// lógica de rango de mes y suma de tickets que lib/economy_screen.dart.
  Future<void> _loadEconomySummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _profile();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      final (budgetRow, ticketsRes) = await (
        _client
            .from('budgets')
            .select('monthly_amount')
            .eq('home_id', homeId)
            .maybeSingle(),
        _client
            .from('tickets')
            .select('total_amount')
            .eq('home_id', homeId)
            .or(ticketRangeFilter(monthStart, monthEnd)),
      ).wait;
      final budget = (budgetRow?['monthly_amount'] as num?)?.toDouble() ?? 0;
      final spent = (ticketsRes as List).fold<double>(
        0,
        (a, t) => a + ((t['total_amount'] as num?)?.toDouble() ?? 0),
      );

      if (mounted) {
        setState(() {
          _monthBudget = budget;
          _monthSpent = spent;
        });
      }
    } catch (e) {
      // No rompemos la UI (la tarjeta se ve a 0), pero dejamos traza del
      // error para no confundir un fallo de carga con un mes sin gastos.
      debugPrint('HomeTab._loadEconomySummary error: $e');
    }
  }

  /// Suma las calorías del diario de consumo personal de HOY y lee el objetivo
  /// diario del perfil. Es personal (va por user_id), a diferencia del resto
  /// de resúmenes del dashboard que son por hogar.
  Future<void> _loadCaloriesSummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      await PlanDiary.sync(_client);
      // Lo usado en las comidas del plan sale también de la despensa.
      unawaited(PantryUsage.syncPlan(_client));
      unawaited(TaperSync.sync(_client));
      // Fotos automáticas antiguas que no son del plato: se cambian o se quitan.
      unawaited(RecipePhotoAudit.run(_client));

      final profileRow = await _profile();
      // Las comidas que se repiten, puestas en el plan de las 2 próximas semanas.
      if (profileRow?['home_id'] case final String homeId) {
        final now = DateTime.now();
        unawaited(
          PlanRepeats.fill(
            _client,
            homeId,
            DateTime(now.year, now.month, now.day + 15),
          ),
        );
      }
      final profile = profileRow != null
          ? NutritionProfile.fromMap(profileRow)
          : null;
      final target = profile?.targetCalories;
      final complete = profile?.isComplete ?? false;

      final todayKey = DateTime.now().toIso8601String().split('T').first;
      final res = await _client
          .from('food_log_entries')
          .select('calories')
          .eq('user_id', user.id)
          .eq('log_date', todayKey);
      final total = (res as List).fold<double>(
        0,
        (a, e) => a + ((e['calories'] as num?)?.toDouble() ?? 0),
      );

      if (mounted) {
        setState(() {
          _targetCalories = target;
          _todayCalories = total;
          _profileComplete = complete;
        });
      }
    } catch (e) {
      // No rompemos la UI (la tarjeta se ve a 0), pero dejamos traza del
      // error para no confundir un fallo de carga con un día sin comidas.
      debugPrint('HomeTab._loadCaloriesSummary error: $e');
    }
  }

  /// Cuenta los alimentos del inventario del hogar que caducan pronto y los que
  /// ya han caducado, usando la misma semántica de [InventoryItem.expiryStatus]
  /// que la pantalla de Despensa. Solo cuenta comida (itemType == 'comida'),
  /// no productos de hogar/limpieza.
  Future<void> _loadExpirySummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _profile();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      // RLS ya filtra por hogar; filtramos también por home_id por claridad.
      final res = await _client
          .from('inventory_items')
          .select()
          .eq('home_id', homeId);
      final items = (res as List)
          .map((m) => InventoryItem.fromMap(m as Map<String, dynamic>))
          .where((it) => it.itemType == 'comida');

      final soon = <InventoryItem>[];
      var expired = 0;
      for (final it in items) {
        switch (it.expiryStatus) {
          case ExpiryStatus.pronto:
            soon.add(it);
          case ExpiryStatus.caducado:
            expired++;
          case ExpiryStatus.fresco:
          case ExpiryStatus.sinFecha:
            break;
        }
      }
      soon.sort(
        (a, b) => (a.daysUntilExpiry ?? 0).compareTo(b.daysUntilExpiry ?? 0),
      );

      if (mounted) {
        setState(() {
          _expiringNames = [for (final it in soon) it.name];
          _expired = expired;
        });
      }
    } catch (e) {
      // No rompemos la UI (la tarjeta muestra el estado tranquilizador), pero
      // dejamos traza del error para no confundir un fallo de carga con una
      // despensa sin caducidades.
      debugPrint('HomeTab._loadExpirySummary error: $e');
    }
  }

  /// Cuenta lo pendiente en la lista de la compra para el acceso rápido.
  Future<void> _loadPendingShopping() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _profile();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      final shopRes = await _client
          .from('shopping_list_items')
          .select('id')
          .eq('home_id', homeId)
          .eq('checked', false);
      if (mounted) setState(() => _pendingShopping = (shopRes as List).length);
    } catch (e) {
      debugPrint('HomeTab._loadPendingShopping error: $e');
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    return context.l.homeGreeting(
      h >= 6 && h < 14
          ? 'morning'
          : h >= 14 && h < 21
          ? 'afternoon'
          : 'night',
    );
  }

  /// "Jueves, 30 de octubre" en el idioma de la app.
  String _todayLabel() => DateFormat.MMMMEEEEd(
    Localizations.localeOf(context).toString(),
  ).format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    // Las tareas van dentro de "Tu día"; aquí quedan solo las cifras.
    final numbers = _prefs.visibleCards
        .where(
          (c) => c == DashboardCard.calories || c == DashboardCard.spending,
        )
        .toList();
    final allLines = _loaded ? _dayLines() : const <DayLine>[];
    final next = _nextLine(allLines);
    final restLines = [
      for (final l in allLines)
        if (!identical(l, next)) l,
    ];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.woodDark,
          onRefresh: _loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl * 2,
            ),
            children: [
              StaggeredEntrance(index: 0, child: _header()),
              const SizedBox(height: AppSpacing.xl),

              if (!_loaded)
                const HomeSkeleton()
              else ...[
                if (next != null) ...[
                  StaggeredEntrance(index: 1, child: _nextUpCard(next)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ValueListenableBuilder(
                  valueListenable: PlanPrefs.current,
                  builder: (_, p, _) => p.fastHours == null
                      ? const SizedBox.shrink()
                      : const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: FastingCard(),
                        ),
                ),

                // Lo primero: qué se come hoy, con la foto de la receta.
                if (_prefs.visibleCards.contains(DashboardCard.meals)) ...[
                  StaggeredEntrance(index: 1, child: _todayMealHero()),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // De un vistazo: caducidades, tareas y compra. Tocar lleva a
                // su pestaña.
                if (restLines.isNotEmpty || next == null) ...[
                  StaggeredEntrance(index: 2, child: _dayCard(restLines)),
                  const SizedBox(height: AppSpacing.lg),
                ],

                StaggeredEntrance(index: 3, child: StreakCard(key: _streakKey)),
                const SizedBox(height: AppSpacing.md),

                if (_prefs.visibleCards.contains(DashboardCard.calories) &&
                    (!_profileComplete ||
                        _targetCalories == null ||
                        _targetCalories! <= 0)) ...[
                  StaggeredEntrance(index: 3, child: _calorieGoalPrompt()),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (numbers.isNotEmpty) ...[
                  StaggeredEntrance(index: 4, child: _numbersCard(numbers)),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (_prefs.quick.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  StaggeredEntrance(index: 5, child: _quickAccessRow()),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Cabecera: fecha, saludo y accesos a personalizar y a tu hogar (miembros,
  /// supermercados, ajustes), que antes era una pestaña.
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _todayLabel().toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _greeting(),
                style: AppTextStyles.display.copyWith(height: 1.1),
              ),
            ],
          ),
        ),
        _roundButton(
          icon: Icons.tune_rounded,
          tooltip: context.l.homeCustomize,
          onTap: _openCustomize,
        ),
        const SizedBox(width: AppSpacing.sm),
        _roundButton(
          icon: Icons.home_rounded,
          tooltip: context.l.homeYourHome,
          filled: true,
          onTap: _openHousehold,
        ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.ink : AppColors.card,
        shape: CircleBorder(side: BorderSide.none),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              size: 22,
              color: filled ? AppColors.cream : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStats() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
    if (mounted) _loadDashboard();
  }

  Future<void> _openHousehold() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HouseholdScreen()));
    if (mounted) _loadDashboard();
  }

  /// El plan semanal vive solo en Comidas > Plan: no se abre otra copia.
  void _openMealPlan() => widget.onNavigateToPlan?.call();

  /// La comida que toca ahora según la hora (desayuno por la mañana, comida a
  /// mediodía…). Si ya pasó todo, la última del día.
  _PlanItem? _nextMeal() {
    final active = _todayItems.where((i) => !i.skipped).toList();
    if (active.isEmpty) return null;
    final h = DateTime.now().hour;
    final now = h < 11
        ? 'breakfast'
        : h < 16
        ? 'lunch'
        : h < 19
        ? 'snack'
        : 'dinner';
    const order = ['breakfast', 'lunch', 'snack', 'dinner', 'dessert'];
    final from = order.indexOf(now);
    for (final it in active) {
      if (order.indexOf(it.mealType) >= from) return it;
    }
    return active.last;
  }

  /// Tarjeta grande "Hoy comemos": foto de la receta que toca y, debajo, el
  /// resto de comidas del día. Sin plan, invita a planificar o a cocinar con
  /// lo que hay en casa.
  Widget _todayMealHero() {
    final next = _nextMeal();
    if (next == null) return _emptyMealHero();
    final style = mealStyle(next.mealType);
    final others = _todayItems.where((i) => !identical(i, next)).toList();
    return Container(
      // El relleno deja ver el borde por encima de la foto.
      padding: const EdgeInsets.all(1.5),
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg - 1.5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openMealPlan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  if (next.recipe != null)
                    RecipeImage(recipe: next.recipe!, height: 190, radius: 0)
                  else
                    Container(
                      height: 190,
                      color: style.bg,
                      child: Icon(style.icon, size: 64, color: style.fg),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.62),
                          ],
                          stops: const [0.35, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, size: 14, color: style.fg),
                          const SizedBox(width: 4),
                          Text(
                            context.l
                                .homeTodayTag(context.l.mealType(next.mealType))
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: style.fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Text(
                      next.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (others.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [for (final o in others) _otherMealRow(o)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otherMealRow(_PlanItem it) {
    final s = mealStyle(it.mealType);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
            child: Icon(s.icon, size: 16, color: s.fg),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 74,
            child: Text(
              context.l.mealType(it.mealType),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              it.skipped ? context.l.homeEatingOut : it.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: it.skipped ? AppColors.inkMuted : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMealHero() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        color: AppColors.peachBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l.homeWhatToEat,
                  style: AppTextStyles.headline,
                ),
              ),
              const MiauCharacter(
                mood: MiauMood.greeting,
                size: 56,
                interactive: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(context.l.homeNothingPlanned, style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: _openMealPlan,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(context.l.homePlan),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.cream,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const DiscoverRecipesScreen(pantryMode: true),
                  ),
                ),
                icon: const Icon(Icons.kitchen_rounded, size: 18),
                label: Text(context.l.homeWithWhatIHave),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Tu día": lo que toca hoy, ya decidido y en orden (descongelar, lo que
  /// caduca, hasta tres tareas, la compra). Cada línea se resuelve de un
  /// toque. Sin nada pendiente, la casa está al día.
  /// Líneas de "Tu día" por urgencia (ver [buildDayBrief]).
  List<DayLine> _dayLines() {
    final tasksOn =
        _prefs.isModuleEnabled(HomeModule.tasks) &&
        _prefs.visibleCards.contains(DashboardCard.tasks);
    return buildDayBrief(
      today: DateTime.now(),
      defrost: [
        for (final i in _todayItems)
          if (i.fromFreezer && !i.skipped) i.title,
      ],
      expiring: _expiringNames,
      expired: _expired,
      tasks: tasksOn ? _todayTasks : const [],
      shopping: _pendingShopping,
    );
  }

  /// Cuántas veces se ha pulsado "Más tarde": pasa a la siguiente línea.
  int _nextSkips = 0;

  /// La línea que va arriba como "Lo siguiente" (null si no hay nada).
  DayLine? _nextLine(List<DayLine> lines) {
    final candidates = lines
        .where((l) => l.kind != DayLineKind.moreTasks)
        .toList();
    if (candidates.isEmpty) return null;
    return candidates[_nextSkips % candidates.length];
  }

  Widget _dayCard(List<DayLine> lines) {
    if (lines.isEmpty) {
      return Semantics(
        label: '${context.l.homeAllDone}. ${context.l.homeAllDoneSub}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppTheme.surfaceDecoration(
            elevation: 0,
            color: AppColors.sageBg,
          ),
          child: Row(
            children: [
              const MiauCharacter(
                mood: MiauMood.celebrating,
                size: 64,
                float: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l.homeAllDone, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      context.l.homeAllDoneSub,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardLabel(
            icon: Icons.wb_sunny_outlined,
            color: AppColors.gold,
            text: context.l.homeYourDay,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in lines) _dayLine(line),
        ],
      ),
    );
  }

  /// "Lo siguiente": lo más urgente del día, en grande y con su acción.
  /// "Más tarde" pasa a la siguiente cosa sin cambiar nada.
  Widget _nextUpCard(DayLine line) {
    final (
      IconData icon,
      String title,
      String? sub,
      VoidCallback? open,
    ) = switch (line.kind) {
      DayLineKind.task => (
        Icons.check_circle_outline_rounded,
        line.task!.title,
        [
          ?_taskWhen(line.task!),
          context.l.homePoints(line.task!.points),
        ].join(' · '),
        widget.onNavigateToTasks,
      ),
      DayLineKind.defrost => (
        Icons.ac_unit_rounded,
        context.l.homeDefrost(line.names.join(', ')),
        null,
        _openMealPlan,
      ),
      DayLineKind.expiring => (
        Icons.hourglass_bottom_rounded,
        context.l.homeExpiringLine(line.names.join(', ')),
        null,
        widget.onNavigateToDespensa,
      ),
      DayLineKind.expired => (
        Icons.delete_outline_rounded,
        context.l.homeExpiredLine(line.count),
        null,
        widget.onNavigateToDespensa,
      ),
      DayLineKind.shopping => (
        Icons.shopping_cart_outlined,
        context.l.homeShoppingLine(line.count),
        null,
        widget.onNavigateToShopping,
      ),
      DayLineKind.moreTasks => (
        Icons.more_horiz_rounded,
        context.l.homeMoreTasks(line.count),
        null,
        widget.onNavigateToTasks,
      ),
    };
    final onBrand = AppColors.onBrand;
    final isTask = line.kind == DayLineKind.task;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.circular(AppRadius.lg + 6),
        boxShadow: AppElevation.level1,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onBrand.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            child: Icon(icon, size: 56, color: onBrand.withValues(alpha: 0.9)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l.homeNextUp.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: onBrand.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: 76),
                  child: Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline.copyWith(
                      color: onBrand,
                      fontSize: 24,
                      height: 1.15,
                    ),
                  ),
                ),
                if (sub != null && sub.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sub,
                    style: AppTextStyles.body.copyWith(
                      color: onBrand.withValues(alpha: 0.9),
                      fontSize: 15,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: isTask
                          ? () => _completeTaskFromDashboard(line.task!)
                          : open,
                      icon: Icon(
                        isTask
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                      label: Text(
                        isTask
                            ? context.l.homeNextDone
                            : context.l.homeNextOpen,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: onBrand,
                        foregroundColor: AppColors.card,
                        minimumSize: const Size(64, 48),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _nextSkips++),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onBrand,
                        side: BorderSide(
                          color: onBrand.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(context.l.homeNextLater),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayLine(DayLine line) {
    String names() => line.count > line.names.length
        ? '${line.names.join(', ')} +${line.count - line.names.length}'
        : line.names.join(', ');
    return switch (line.kind) {
      DayLineKind.task => _todayTaskRow(line.task!),
      DayLineKind.defrost => _dayAction(
        icon: Icons.ac_unit_rounded,
        color: AppColors.frost,
        text: context.l.homeDefrost(line.names.join(', ')),
        onTap: _openMealPlan,
      ),
      DayLineKind.expiring => _dayAction(
        icon: Icons.hourglass_bottom_rounded,
        color: AppColors.soon,
        text: context.l.homeExpiringLine(names()),
        onTap: widget.onNavigateToDespensa,
      ),
      DayLineKind.expired => _dayAction(
        icon: Icons.delete_outline_rounded,
        color: AppColors.expired,
        text: context.l.homeExpiredLine(line.count),
        onTap: widget.onNavigateToDespensa,
      ),
      DayLineKind.moreTasks => _dayAction(
        icon: Icons.more_horiz_rounded,
        color: AppColors.sage,
        text: context.l.homeMoreTasks(line.count),
        onTap: widget.onNavigateToTasks,
      ),
      DayLineKind.shopping => _dayAction(
        icon: Icons.shopping_cart_outlined,
        color: AppColors.frost,
        text: context.l.homeShoppingLine(line.count),
        onTap: widget.onNavigateToShopping,
      ),
    };
  }

  /// Línea de "Tu día" que lleva a donde se resuelve.
  Widget _dayAction({
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              SizedBox(width: 26, child: Icon(icon, size: 22, color: color)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }

  /// Atajos elegidos por el usuario como pastillas compactas (icono +
  /// texto) que caben en una o dos líneas, con feedback táctil (PressScale).
  Widget _quickAccessRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardLabel(
          icon: Icons.bolt_rounded,
          color: AppColors.gold,
          text: context.l.homeShortcuts,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final q in _prefs.quick) _quickAccessButton(q)],
        ),
      ],
    );
  }

  Widget _quickAccessButton(QuickAction action) {
    return PressScale(
      onTap: () => _runQuickAction(action),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: AppElevation.border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 18, color: AppColors.woodDark),
            const SizedBox(width: 6),
            Text(
              context.l.quickAction(action.id),
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ejecuta la navegación de un acceso rápido y refresca al volver.
  Future<void> _runQuickAction(QuickAction action) async {
    switch (action) {
      case QuickAction.addInventory:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
        );
        break;
      case QuickAction.scanTicket:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ScanTicketScreen()));
        break;
      case QuickAction.shopping:
        final goShopping = widget.onNavigateToShopping;
        if (goShopping != null) {
          goShopping();
          return;
        }
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
        break;
      case QuickAction.addRecipe:
        if (!mounted) return;
        await AddRecipeChooser.show(context);
        break;
      case QuickAction.mealPlan:
        _openMealPlan();
        break;
      case QuickAction.diary:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FoodDiaryScreen()));
        break;
    }
    if (mounted) _loadDashboard();
  }

  /// Abre el editor de personalización del dashboard y guarda al volver.
  Future<void> _openCustomize() async {
    final result = await Navigator.of(context).push<DashboardPrefs>(
      MaterialPageRoute(
        builder: (_) => _CustomizeDashboardScreen(initial: _prefs),
      ),
    );
    if (result != null) await _savePrefs(result);
  }

  /// Cabecera pequeña común a las tarjetas: icono de color, etiqueta en
  /// versalitas y, si se puede ir a la pantalla completa, "Ver todo".
  Widget _cardLabel({
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onMore,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        if (onMore != null)
          InkWell(
            onTap: onMore,
            borderRadius: AppRadius.smRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                context.l.homeSeeAll,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.woodDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Fila de una tarea de hoy con boton circular para marcarla hecha, con el
  /// mismo aspecto que _TaskCard de la pantalla de Tareas.
  Widget _todayTaskRow(HomeTask t) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          PressScale(
            onTap: () => _completeTaskFromDashboard(t),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: AppColors.inkMuted, width: 2),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall,
            ),
          ),
          // "Hoy" sobra bajo el título "Para hoy"; la hora o el atraso no.
          if (_taskWhen(t) case final label?
              when label != context.l.homeToday) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.labelMuted),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.l.homePoints(t.points),
            style: AppTextStyles.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.woodDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Texto breve de cuándo toca una tarea: 'Hoy', 'Mañana' o 'dd/mm'.
  /// Devuelve null si la tarea no tiene fecha.
  String? _taskWhen(HomeTask t) {
    final due = t.nextDue ?? t.dueDate;
    if (due == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    String label;
    if (diff == 0) {
      label = context.l.homeToday;
    } else if (diff == 1) {
      label = context.l.homeTomorrow;
    } else {
      label =
          '${due.day.toString().padLeft(2, '0')}/'
          '${due.month.toString().padLeft(2, '0')}';
    }
    final time = t.dueTime;
    return time != null ? '$label $time' : label;
  }

  /// Aviso amable para calcular el objetivo de calorías con el cuestionario
  /// guiado. Aparece mientras el perfil no está completo. Al pulsarlo abre el
  /// ProfileWizardScreen y, al volver, refresca el resumen de calorías y avisa
  /// al shell por si el wizard cambió los módulos activados (p. ej. desactivar
  /// Tareas debe ocultar su pestaña sin esperar a un reinicio).
  Widget _calorieGoalPrompt() {
    return InkWell(
      borderRadius: AppRadius.lgRadius,
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileWizardScreen()));
        _loadCaloriesSummary(); // refrescar al volver del cuestionario
        // El wizard puede cambiar los módulos: que el shell recargue prefs y
        // reconstruya la barra de navegación.
        MainShell.reloadModules();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppTheme.surfaceDecoration(
          radius: AppRadius.lg,
          elevation: 2,
        ),
        child: Row(
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 56),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l.homeCaloriesTitle, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l.homeCaloriesHint,
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.inkMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Cifras del día en una sola superficie plana (es información, no algo
  /// que pulsar con prisa): calorías y gasto, cada una en su fila con barra.
  Widget _numbersCard(List<DashboardCard> cards) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: AppTheme.surfaceDecoration(elevation: 0),
      child: Column(
        children: [
          for (final (i, c) in cards.indexed) ...[
            if (i > 0) Divider(height: 1, color: AppColors.line),
            if (c == DashboardCard.calories)
              _numberRow(
                icon: Icons.local_fire_department_outlined,
                color: AppColors.terracotta,
                label: context.l.homeCaloriesToday,
                value: _todayCalories,
                format: (v) => context.l.homeKcal(v.round()),
                target: _targetCalories?.toDouble(),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodDiaryScreen()),
                  );
                  _loadCaloriesSummary(); // refrescar al volver del diario
                },
              )
            else
              _numberRow(
                icon: Icons.savings_outlined,
                color: AppColors.gold,
                label: context.l.homeMonthSpend,
                value: _monthSpent,
                format: formatEuros,
                target: _monthBudget,
                onTap: _openStats,
              ),
          ],
        ],
      ),
    );
  }

  /// Fila de cifra: etiqueta, "valor de objetivo" y barra fina de progreso
  /// (roja si se pasa). Sin objetivo o presupuesto, solo la cifra.
  Widget _numberRow({
    required IconData icon,
    required Color color,
    required String label,
    required double value,
    required String Function(double) format,
    required double? target,
    required VoidCallback onTap,
  }) {
    final hasTarget = target != null && target > 0;
    final over = hasTarget && value > target;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedCounter(
                  value: value,
                  formatter: format,
                  style: AppTextStyles.titleSmall,
                ),
                if (hasTarget) ...[
                  const SizedBox(width: 4),
                  Text(
                    context.l.homeOf(format(target)),
                    style: AppTextStyles.labelMuted,
                  ),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
            if (hasTarget) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (value / target).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  color: over ? AppColors.expired : color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Comida planificada (tipo + título de receta + si se salta) usada por el
/// resumen de comidas de hoy del dashboard.
class _PlanItem {
  final String mealType;
  final String title;
  final bool skipped;
  final bool fromFreezer;
  final Recipe? recipe;
  _PlanItem({
    required this.mealType,
    required this.title,
    required this.skipped,
    this.fromFreezer = false,
    this.recipe,
  });
}

/// Pantalla para PERSONALIZAR el Inicio: reordenar y mostrar/ocultar tarjetas
/// (arrastrando) y elegir los accesos rápidos. Devuelve las nuevas
/// preferencias con Navigator.pop al guardar.
class _CustomizeDashboardScreen extends StatefulWidget {
  final DashboardPrefs initial;
  const _CustomizeDashboardScreen({required this.initial});

  @override
  State<_CustomizeDashboardScreen> createState() =>
      _CustomizeDashboardScreenState();
}

class _CustomizeDashboardScreenState extends State<_CustomizeDashboardScreen> {
  late List<DashboardCard> _order;
  late Set<DashboardCard> _hidden;
  late List<QuickAction> _quick;

  @override
  void initState() {
    super.initState();
    _order = [...widget.initial.order];
    _hidden = {...widget.initial.hidden};
    _quick = [...widget.initial.quick];
  }

  void _save() {
    // Conservar módulos y estilo de cocina del perfil; este editor solo
    // cambia orden/ocultas/accesos rápidos.
    Navigator.of(context).pop(
      widget.initial.copyWith(order: _order, hidden: _hidden, quick: _quick),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(context.l.homeCustomize),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              context.l.save,
              style: TextStyle(
                color: AppColors.woodDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _sectionLabel(context.l.homeCardsSection),
          const SizedBox(height: 8),
          // Reordenable; cada fila tiene un switch para mostrar/ocultar.
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: true,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _order.removeAt(oldIndex);
                _order.insert(newIndex, item);
              });
            },
            children: [
              for (final card in _order)
                Container(
                  key: ValueKey(card.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppTheme.cardDecoration(radius: 14),
                  child: SwitchListTile(
                    value: !_hidden.contains(card),
                    // Deja sitio al asa de arrastre, que se pinta encima a la derecha.
                    contentPadding: const EdgeInsets.only(left: 16, right: 44),
                    secondary: Icon(card.icon, color: AppColors.woodDark),
                    title: Text(
                      context.l.dashCard(card.id),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onChanged: (visible) => setState(() {
                      if (visible) {
                        _hidden.remove(card);
                      } else {
                        _hidden.add(card);
                      }
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel(context.l.homeQuickSection),
          const SizedBox(height: 4),
          Text(context.l.homeQuickHint, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuickAction.values.map((q) {
              final sel = _quick.contains(q);
              return FilterChip(
                label: Text(context.l.quickAction(q.id)),
                avatar: Icon(
                  q.icon,
                  size: 18,
                  color: sel ? AppColors.ink : AppColors.woodDark,
                ),
                selected: sel,
                backgroundColor: AppColors.card,
                onSelected: (v) => setState(() {
                  if (v) {
                    _quick.add(q);
                  } else {
                    _quick.remove(q);
                  }
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 12,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w800,
      color: AppColors.ink.withValues(alpha: 0.6),
    ),
  );
}
