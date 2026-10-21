import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/taper_sync.dart';
import '../services/plan_prefs.dart';
import '../services/shopping_checkout.dart';
import '../services/task_scheduler.dart';
import '../theme/app_theme.dart';
import '../widgets/fasting_card.dart';
import '../widgets/list_skeleton.dart';
import '../widgets/miau_character.dart';
import '../widgets/plan/plan_parts.dart';
import '../widgets/recipe_image.dart';
import '../widgets/animations/animated_counter.dart';
import '../widgets/animations/celebrate.dart';
import '../widgets/animations/press_scale.dart';
import '../widgets/animations/staggered_entrance.dart';
import '../utils/friendly_error.dart';

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
  int _expiringSoon = 0;
  int _expired = 0;

  // Productos pendientes en la lista de la compra (para el acceso de un
  // vistazo).
  int _pendingShopping = 0;

  // Preferencias de personalización del dashboard (orden/visibilidad de
  // tarjetas y accesos rápidos). Por usuario, en profiles.dashboard_prefs.
  DashboardPrefs _prefs = DashboardPrefs.defaults();

  // Hasta la primera carga completa se ven esqueletos, no tarjetas a cero.
  bool _loaded = false;

  static const _mealLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Merienda',
    'dessert': 'Postre',
  };
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
  Future<void> _loadDashboard() async {
    _profileFuture = null; // perfil fresco en cada recarga
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
          .select('plan_date, meal_type, skipped, recipes(*)')
          .eq('home_id', homeId)
          .eq('plan_date', todayKey);

      final items = <_PlanItem>[];
      for (final row in (res as List)) {
        final e = MealPlanEntry.fromMap(row);
        final rec = row['recipes'];
        Recipe? recipe;
        if (rec is Map<String, dynamic>) {
          try {
            recipe = Recipe.fromMap(rec);
          } catch (_) {}
        }
        final title = (rec is Map ? rec['title'] : null) as String?;
        items.add(
          _PlanItem(
            mealType: e.mealType,
            title: title ?? 'Receta',
            skipped: e.skipped,
            recipe: recipe,
          ),
        );
      }
      items.sort(
        (a, b) => _mealOrder
            .indexOf(a.mealType)
            .compareTo(_mealOrder.indexOf(b.mealType)),
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('+${task.points} puntos')));
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
      final startStr = monthStart.toIso8601String().split('T').first;
      final endStr = monthEnd.toIso8601String().split('T').first;

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
            .gte('created_at', startStr)
            .lt('created_at', endStr),
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

      final profileRow = await _profile();
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

      var soon = 0;
      var expired = 0;
      for (final it in items) {
        switch (it.expiryStatus) {
          case ExpiryStatus.pronto:
            soon++;
            break;
          case ExpiryStatus.caducado:
            expired++;
            break;
          case ExpiryStatus.fresco:
          case ExpiryStatus.sinFecha:
            break;
        }
      }

      if (mounted) {
        setState(() {
          _expiringSoon = soon;
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
    if (h < 6) return 'Buenas noches';
    if (h < 14) return 'Buenos días';
    if (h < 21) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String _todayLabel() {
    final d = DateTime.now();
    return '${_weekdays[d.weekday - 1]}, ${d.day} de ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final rest = _prefs.visibleCards
        .where((c) => c != DashboardCard.meals)
        .toList();
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
                const ListSkeleton(
                  rows: 4,
                  leading: false,
                  padding: EdgeInsets.zero,
                )
              else ...[
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

              // De un vistazo: caducidades, tareas y compra. Tocar lleva a su
              // pestaña.
              StaggeredEntrance(index: 2, child: _glanceRow()),
              const SizedBox(height: AppSpacing.xl),

              if (_prefs.quick.isNotEmpty) ...[
                StaggeredEntrance(index: 3, child: _quickAccessRow()),
                const SizedBox(height: AppSpacing.xl),
              ],

              if (_prefs.visibleCards.contains(DashboardCard.calories) &&
                  (!_profileComplete ||
                      _targetCalories == null ||
                      _targetCalories! <= 0)) ...[
                StaggeredEntrance(index: 4, child: _calorieGoalPrompt()),
                const SizedBox(height: AppSpacing.md),
              ],

              for (final (i, card) in rest.indexed) ...[
                StaggeredEntrance(index: 5 + i, child: _cardWidget(card)),
                const SizedBox(height: AppSpacing.md),
              ],
              ],

              // Como "Editar" en los resúmenes: al final, no compitiendo con
              // el saludo.
              Center(
                child: TextButton.icon(
                  onPressed: _openCustomize,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Personalizar Inicio'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkMuted,
                  ),
                ),
              ),
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
                style: TextStyle(
                  fontSize: 30,
                  letterSpacing: -0.6,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        _roundButton(
          icon: Icons.insights_rounded,
          tooltip: 'Tus datos',
          onTap: _openStats,
        ),
        const SizedBox(width: AppSpacing.sm),
        _roundButton(
          icon: Icons.home_rounded,
          tooltip: 'Tu hogar',
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
        shape: CircleBorder(
          side: BorderSide(color: AppColors.stroke, width: 1.5),
        ),
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
                            'HOY · ${style.label.toUpperCase()}',
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
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: -0.4,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
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
              s.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              it.skipped ? 'Fuera de casa' : it.title,
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
                  '¿Qué comemos hoy?',
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
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
          Text(
            'Aún no hay nada planificado para hoy.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: _openMealPlan,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Planificar'),
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
                label: const Text('Con lo que tengo'),
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

  /// Tres fichas de un vistazo. Cada una salta a su pestaña.
  Widget _glanceRow() {
    final expiring = _expiringSoon + _expired;
    final tasksToday = _todayTasks.length;
    return Row(
      children: [
        Expanded(
          child: _glanceTile(
            value: expiring,
            label: 'Por caducar',
            icon: Icons.hourglass_bottom_rounded,
            bg: _expired > 0 ? AppColors.expiredBg : AppColors.soonBg,
            fg: _expired > 0 ? AppColors.expired : AppColors.soon,
            onTap: widget.onNavigateToDespensa,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (_prefs.isModuleEnabled(HomeModule.tasks)) ...[
          Expanded(
            child: _glanceTile(
              value: tasksToday,
              label: tasksToday == 1 ? 'Tarea hoy' : 'Tareas hoy',
              icon: Icons.check_circle_outline_rounded,
              bg: AppColors.sageBg,
              fg: AppColors.sage,
              onTap: widget.onNavigateToTasks,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: _glanceTile(
            value: _pendingShopping,
            label: 'En la compra',
            icon: Icons.shopping_cart_outlined,
            bg: AppColors.frostBg,
            fg: AppColors.frost,
            onTap: widget.onNavigateToShopping,
          ),
        ),
      ],
    );
  }

  Widget _glanceTile({
    required int value,
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: '$value $label',
      // En cero la ficha se queda en papel y gris: solo llama la atención lo
      // que pide algo.
      child: Container(
        decoration: AppTheme.surfaceDecoration(
          radius: AppRadius.md,
          color: value == 0 ? AppColors.card : bg,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mdRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: value == 0 ? AppColors.inkMuted : fg,
                    size: 22,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 28,
                      letterSpacing: -0.6,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: value == 0 ? AppColors.inkMuted : fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Par de colores (fondo pastel + acento) para el cuadro de icono de cada
  /// tarjeta del dashboard, dando vida y color por tipo de información de forma
  /// coherente con la paleta Cozy.
  (Color, Color) _cardAccent(DashboardCard card) {
    switch (card) {
      case DashboardCard.meals:
        return (AppColors.peachBg, AppColors.peach);
      case DashboardCard.calories:
        return (AppColors.terracottaBg, AppColors.terracotta);
      case DashboardCard.tasks:
        return (AppColors.sageBg, AppColors.sage);
      case DashboardCard.spending:
        return (AppColors.peachBg, AppColors.woodDark);
    }
  }

  /// Cuadro de icono reutilizable para las tarjetas: fondo pastel + icono en el
  /// acento correspondiente.
  Widget _cardIconBox(IconData icon, (Color, Color) accent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accent.$1,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Icon(icon, color: accent.$2),
    );
  }

  /// Devuelve el widget de una tarjeta del dashboard por su tipo.
  Widget _cardWidget(DashboardCard card) {
    switch (card) {
      case DashboardCard.meals:
        return _mealsCard();
      case DashboardCard.calories:
        return _caloriesCard();
      case DashboardCard.tasks:
        return _tasksCard();
      case DashboardCard.spending:
        return _spendingCard();
    }
  }

  /// Fila horizontal de accesos rápidos elegidos por el usuario. Cada botón
  /// aparece de forma escalonada (StaggeredEntrance por index) y da feedback
  /// táctil al pulsar (PressScale), sin tocar la navegación _runQuickAction.
  Widget _quickAccessRow() {
    final items = _prefs.quick;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => SizedBox(
          width: 72,
          child: StaggeredEntrance(
            index: i,
            child: _quickAccessButton(items[i]),
          ),
        ),
      ),
    );
  }

  /// Par pastel (fondo + acento) por acceso rápido, para dar vida al cuadro del
  /// icono en vez de usar siempre el mismo color plano, cuidando el contraste.
  (Color, Color) _quickAccent(QuickAction action) {
    switch (action) {
      case QuickAction.addInventory:
        return (AppColors.sageBg, AppColors.sage);
      case QuickAction.scanTicket:
        return (AppColors.peachBg, AppColors.peach);
      case QuickAction.shopping:
        return (AppColors.frostBg, AppColors.frost);
      case QuickAction.addRecipe:
        return (AppColors.terracottaBg, AppColors.terracotta);
      case QuickAction.mealPlan:
        return (AppColors.soonBg, AppColors.woodDark);
      case QuickAction.diary:
        return (AppColors.terracottaBg, AppColors.terracotta);
    }
  }

  Widget _quickAccessButton(QuickAction action) {
    final accent = _quickAccent(action);
    return PressScale(
      onTap: () => _runQuickAction(action),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accent.$1,
              shape: BoxShape.circle,
              border: AppElevation.border,
            ),
            child: Icon(action.icon, color: accent.$2, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(fontSize: 11, height: 1.1),
          ),
        ],
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

  /// Tarjeta 'Comidas de hoy' con el plan real de meal_plan_entries.
  Widget _mealsCard() {
    final accent = _cardAccent(DashboardCard.meals);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        elevation: 2,
        color: Color.alphaBlend(
          accent.$1.withValues(alpha: 0.28),
          AppColors.card,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardIconBox(Icons.restaurant_menu, accent),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comidas de hoy', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                if (_todayItems.isEmpty)
                  Text(
                    'Aún no hay un plan para hoy',
                    style: AppTextStyles.bodyMuted,
                  )
                else
                  ..._todayItems.map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              _mealLabels[it.mealType] ?? it.mealType,
                              style: AppTextStyles.labelMuted,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              it.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                decoration: it.skipped
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: it.skipped
                                    ? AppColors.inkMuted
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                          if (it.skipped)
                            Text('Fuera', style: AppTextStyles.labelMuted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta 'Tareas del hogar': muestra las tareas de HOY (y atrasadas o sin
  /// fecha) y permite marcarlas como hechas de un toque directamente desde el
  /// Dashboard, con el mismo flujo de puntos + reprogramacion que la pantalla
  /// de Tareas. Debajo, un recuento del total de pendientes.
  Widget _tasksCard() {
    final accent = _cardAccent(DashboardCard.tasks);
    final count = _pendingTasks.length;
    final today = _todayTasks;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        elevation: 2,
        color: Color.alphaBlend(
          accent.$1.withValues(alpha: 0.24),
          AppColors.card,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardIconBox(Icons.check_circle_outline, accent),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tareas del hogar',
                            style: AppTextStyles.title,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: accent.$1,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: AnimatedCounter(
                              value: count.toDouble(),
                              formatter: (v) => '${v.round()}',
                              style: AppTextStyles.label.copyWith(
                                color: accent.$2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (count == 0)
                      Text('Todo al día', style: AppTextStyles.bodyMuted)
                    else if (today.isEmpty)
                      Text(
                        count == 1
                            ? '1 tarea pendiente (ninguna para hoy)'
                            : '$count tareas pendientes (ninguna para hoy)',
                        style: AppTextStyles.titleSmall,
                      )
                    else
                      Text(
                        today.length == 1
                            ? 'Para hoy: 1 tarea'
                            : 'Para hoy: ${today.length} tareas',
                        style: AppTextStyles.titleSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Lista de tareas de hoy, cada una marcable de un toque.
          if (today.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...today.map(_todayTaskRow),
          ],
        ],
      ),
    );
  }

  /// Fila de una tarea de hoy con boton circular para marcarla hecha, con el
  /// mismo aspecto que _TaskCard de la pantalla de Tareas.
  Widget _todayTaskRow(HomeTask t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
          if (_taskWhen(t) != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(_taskWhen(t)!, style: AppTextStyles.labelMuted),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${t.points} pts',
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
      label = 'Hoy';
    } else if (diff == 1) {
      label = 'Mañana';
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
                  Text(
                    'Calcula tu objetivo de calorías',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Responde unas preguntas rápidas y adaptaré PrezHome a ti.',
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

  /// Tarjeta 'Calorías de hoy': total consumido del diario personal y, si el
  /// perfil tiene objetivo, barra de progreso con lo que queda o el exceso.
  /// Al tocarla abre el diario del día y refresca al volver.
  Widget _caloriesCard() {
    final accent = _cardAccent(DashboardCard.calories);
    final total = _todayCalories;
    final target = _targetCalories;
    final hasTarget = target != null && target > 0;
    final ratio = hasTarget ? (total / target).clamp(0.0, 1.0) : 0.0;
    final over = hasTarget && total > target;

    return InkWell(
      borderRadius: AppRadius.lgRadius,
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FoodDiaryScreen()));
        _loadCaloriesSummary(); // refrescar al volver del diario
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardIconBox(Icons.local_fire_department_outlined, accent),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calorías de hoy', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedCounter(
                    value: total,
                    formatter: (v) => hasTarget
                        ? 'Hoy has comido ${v.round()} kcal de $target'
                        : 'Hoy has comido ${v.round()} kcal',
                    style: AppTextStyles.titleSmall,
                  ),
                  if (hasTarget) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: AppColors.line,
                        color: over ? AppColors.expired : AppColors.wood,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      over
                          ? 'Te has pasado ${(total - target).round()} kcal'
                          : 'Te quedan ${(target - total).round()} kcal',
                      style: AppTextStyles.label.copyWith(
                        color: over ? AppColors.expired : AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  /// Tarjeta 'Gasto del mes': gasto acumulado y, si hay presupuesto, barra de
  /// progreso con el restante o el exceso (misma lógica que economy_screen).
  Widget _spendingCard() {
    final accent = _cardAccent(DashboardCard.spending);
    final spent = _monthSpent;
    final budget = _monthBudget;
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = budget > 0 && spent > budget;

    return PressScale(
      onTap: _openStats,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardIconBox(Icons.savings_outlined, accent),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gasto del mes', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedCounter(
                    value: spent,
                    formatter: (v) => '${v.toStringAsFixed(2)} €',
                    style: AppTextStyles.display.copyWith(fontSize: 24),
                  ),
                  if (budget > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: AppColors.line,
                        color: over ? AppColors.expired : AppColors.wood,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      over
                          ? 'Te has pasado ${(spent - budget).toStringAsFixed(2)} € del presupuesto'
                          : 'Te quedan ${(budget - spent).toStringAsFixed(2)} €',
                      style: AppTextStyles.label.copyWith(
                        color: over ? AppColors.expired : AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
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
  final Recipe? recipe;
  _PlanItem({
    required this.mealType,
    required this.title,
    required this.skipped,
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
        title: const Text('Personalizar Inicio'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Guardar',
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
          _sectionLabel('Tarjetas (arrastra para ordenar)'),
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
                    activeThumbColor: AppColors.woodDark,
                    secondary: Icon(card.icon, color: AppColors.woodDark),
                    title: Text(
                      card.label,
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
          _sectionLabel('Accesos rápidos'),
          const SizedBox(height: 4),
          Text(
            'Elige los atajos que verás arriba del Inicio.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuickAction.values.map((q) {
              final sel = _quick.contains(q);
              return FilterChip(
                label: Text(q.label),
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
