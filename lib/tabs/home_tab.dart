import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../add_inventory_item_screen.dart';
import '../add_recipe_chooser.dart';
import '../food_diary_screen.dart';
import '../main_shell.dart';
import '../meal_plan_screen.dart';
import '../profile_wizard_screen.dart';
import '../scan_ticket_screen.dart';
import '../shopping_list_screen.dart';
import '../models/dashboard_prefs.dart';
import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../models/nutrition_profile.dart';
import '../models/task.dart';
import '../services/smart_reminders.dart';
import '../services/task_scheduler.dart';
import '../theme/app_theme.dart';
import '../widgets/miau_character.dart';
import '../widgets/animations/animated_counter.dart';
import '../widgets/animations/celebrate.dart';
import '../widgets/animations/press_scale.dart';
import '../widgets/animations/staggered_entrance.dart';

/// Pestaña de Inicio: dashboard con el resumen del día del hogar (comidas de
/// hoy, calorías, tareas y gasto). El plan semanal/mensual vive ahora en la
/// pestaña Comidas > Plan, así que Inicio solo muestra el resumen.
class HomeTab extends StatefulWidget {
  /// Petición de cambiar a la pestaña Despensa (sub-tab Inventario). La inyecta
  /// MainShell para que la tarjeta de caducidades aterrice donde el inventario
  /// vive de verdad, en lugar de abrir una InventoryScreen suelta.
  final VoidCallback? onNavigateToDespensa;
  const HomeTab({super.key, this.onNavigateToDespensa});

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

  // Recordatorios inteligentes unificados (cocina/congelador/caducidad/tareas/
  // compra). Se calculan sin IA cruzando los datos del día.
  List<Reminder> _reminders = [];

  // Preferencias de personalización del dashboard (orden/visibilidad de
  // tarjetas y accesos rápidos). Por usuario, en profiles.dashboard_prefs.
  DashboardPrefs _prefs = DashboardPrefs.defaults();

  static const _mealLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Snack',
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
    await Future.wait([
      _loadPrefs(),
      _loadTodayPlan(),
      _loadTasksSummary(),
      _loadEconomySummary(),
      _loadCaloriesSummary(),
      _loadExpirySummary(),
      _loadReminders(),
    ]);
  }

  /// Carga las preferencias del dashboard del usuario (orden/visibilidad de
  /// tarjetas y accesos rápidos). Si no hay, usa las por defecto.
  Future<void> _loadPrefs() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final row = await _client
          .from('profiles')
          .select('dashboard_prefs')
          .eq('id', user.id)
          .maybeSingle();
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
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      final todayKey = DateTime.now().toIso8601String().split('T').first;
      final res = await _client
          .from('meal_plan_entries')
          .select('plan_date, meal_type, skipped, recipes(title)')
          .eq('home_id', homeId)
          .eq('plan_date', todayKey);

      final items = <_PlanItem>[];
      for (final row in (res as List)) {
        final e = MealPlanEntry.fromMap(row);
        final rec = row['recipes'];
        final title = (rec is Map ? rec['title'] : null) as String?;
        items.add(
          _PlanItem(
            mealType: e.mealType,
            title: title ?? 'Receta',
            skipped: e.skipped,
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
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
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
      await TaskScheduler(_client).complete(task);
      if (mounted) {
        // Micro-celebración reutilizable (respeta reduce-motion: no hace nada
        // visible aparatoso) además del SnackBar de puntos existente.
        Celebrate.show(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡+${task.points} puntos!')));
      }
      await _loadTasksSummary();
    } catch (e) {
      debugPrint('HomeTab._completeTaskFromDashboard error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      final startStr = monthStart.toIso8601String().split('T').first;
      final endStr = monthEnd.toIso8601String().split('T').first;

      final budgetRow = await _client
          .from('budgets')
          .select('monthly_amount')
          .eq('home_id', homeId)
          .maybeSingle();
      final budget = (budgetRow?['monthly_amount'] as num?)?.toDouble() ?? 0;

      final ticketsRes = await _client
          .from('tickets')
          .select('total_amount')
          .eq('home_id', homeId)
          .gte('created_at', startStr)
          .lt('created_at', endStr);
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

      final profileRow = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
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
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
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

  /// Construye los recordatorios inteligentes (sin IA) cruzando: inventario de
  /// comida (caducidades y congelador), comidas de hoy, tareas de hoy y compra
  /// pendiente. Best-effort: si algo falla, la tarjeta se ve con lo que haya.
  Future<void> _loadReminders() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;

      // Inventario de comida con caducidad.
      final invRes = await _client
          .from('inventory_items')
          .select()
          .eq('home_id', homeId);
      final items = (invRes as List)
          .map((m) => InventoryItem.fromMap(m as Map<String, dynamic>))
          .where((it) => it.itemType == 'comida')
          .toList();

      final stock = <ReminderStockItem>[];
      final takeOuts = <ReminderTakeOut>[];
      for (final it in items) {
        final frozen = it.category == 'Congelador';
        stock.add(
          ReminderStockItem(
            name: it.name,
            daysUntilExpiry: it.daysUntilExpiry,
            isFrozen: frozen,
          ),
        );
        // Platos congelados que convviene sacar: si su consumo preferente está
        // muy cerca (<=2 días), sugerimos sacarlos. Es una señal simple y útil
        // sin depender del plan.
        if (frozen && it.kind == 'dish') {
          final d = it.daysUntilExpiry;
          if (d != null && d <= 2) {
            // daysUntilTakeOut 0 = hoy. Si ya caducó (d<0) -> ya tocaba.
            takeOuts.add(
              ReminderTakeOut(name: it.name, daysUntilTakeOut: d < 0 ? -1 : 0),
            );
          }
        }
      }

      // Tareas que vencen hoy o están vencidas (de las ya cargadas).
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      final tareasHoy = <String>[];
      for (final t in _pendingTasks) {
        final due = t.dueDate;
        if (due == null) continue;
        final dd = DateTime(due.year, due.month, due.day);
        if (!dd.isAfter(todayKey)) tareasHoy.add(t.title);
      }

      // Compra pendiente (no comprada).
      int pending = 0;
      try {
        final shopRes = await _client
            .from('shopping_list_items')
            .select('id')
            .eq('home_id', homeId)
            .eq('checked', false);
        pending = (shopRes as List).length;
      } catch (_) {}

      final reminders = buildReminders(
        mealsToday: [
          for (final m in _todayItems)
            if (!m.skipped) m.title,
        ],
        stock: stock,
        takeOuts: takeOuts,
        tasksToday: tareasHoy,
        pendingShopping: pending,
      );

      if (mounted) setState(() => _reminders = reminders);
    } catch (e) {
      debugPrint('HomeTab._loadReminders error: $e');
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Buenas noches';
    if (h < 14) return 'Buenos días';
    if (h < 21) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('PrezHome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Personalizar Inicio',
            onPressed: _openCustomize,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // Cabecera con Presidente Miau como personaje. Entra la primera
          // (index 0) con la aparición escalonada, con elevación de tarjeta.
          StaggeredEntrance(index: 0, child: _headerCard()),
          const SizedBox(height: AppSpacing.xl),

          // Accesos rápidos a lo que más usas (personalizables).
          if (_prefs.quick.isNotEmpty) ...[
            StaggeredEntrance(index: 1, child: _quickAccessRow()),
            const SizedBox(height: AppSpacing.xl),
          ],

          StaggeredEntrance(
            index: 2,
            child: Text(
              'Hoy',
              style: AppTextStyles.label.copyWith(
                letterSpacing: 0.5,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Si el perfil no está completo o aún no hay objetivo de calorías,
          // invitamos a calcularlo (independiente de la personalización).
          if (!_profileComplete ||
              _targetCalories == null ||
              _targetCalories! <= 0) ...[
            StaggeredEntrance(index: 3, child: _calorieGoalPrompt()),
            const SizedBox(height: AppSpacing.md),
          ],

          // Tarjetas en el orden y visibilidad elegidos por el usuario. Entran
          // de forma escalonada para que "entren por los ojos" al abrir.
          for (final (i, card) in _prefs.visibleCards.indexed) ...[
            StaggeredEntrance(index: 4 + i, child: _cardWidget(card)),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  /// Cabecera del dashboard: Presidente Miau saludando + jerarquía tipográfica
  /// nueva (saludo en headline, subtítulo en gris de marca) sobre una tarjeta
  /// en reposo.
  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
      child: Row(
        children: [
          const MiauCharacter(mood: MiauMood.greeting, size: 72),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: AppTextStyles.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Este es el resumen de tu hogar',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Par de colores (fondo pastel + acento) para el cuadro de icono de cada
  /// tarjeta del dashboard, dando vida y color por tipo de información de forma
  /// coherente con la paleta Cozy. Caducidades cambia según su estado.
  (Color, Color) _cardAccent(DashboardCard card) {
    switch (card) {
      case DashboardCard.reminders:
        return (AppColors.soonBg, AppColors.woodDark);
      case DashboardCard.meals:
        return (AppColors.peachBg, AppColors.peach);
      case DashboardCard.expiry:
        final hasExpired = _expired > 0;
        return hasExpired
            ? (AppColors.expiredBg, AppColors.expired)
            : (AppColors.soonBg, AppColors.soon);
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
      case DashboardCard.reminders:
        return _remindersCard();
      case DashboardCard.meals:
        return _mealsCard();
      case DashboardCard.expiry:
        return _expiryCard();
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
    // Reparte los accesos rápidos a lo ancho (Expanded) para que quepan todos
    // sin scroll horizontal; con pocos (4) se ven de un vistazo y con más
    // siguen cabiendo repartidos. Se mantiene la entrada escalonada por index.
    final items = _prefs.quick;
    return SizedBox(
      height: 112,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StaggeredEntrance(
                index: i,
                child: _quickAccessButton(items[i]),
              ),
            ),
          ],
        ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: AppTheme.surfaceDecoration(radius: AppRadius.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.$1,
                borderRadius: AppRadius.smRadius,
              ),
              child: Icon(action.icon, color: accent.$2, size: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              action.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(fontSize: 10.5, height: 1.1),
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
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
        break;
      case QuickAction.addRecipe:
        if (!mounted) return;
        await AddRecipeChooser.show(context);
        break;
      case QuickAction.mealPlan:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MealPlanScreen()));
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

  /// Tarjeta 'Hoy toca': centro de recordatorios inteligentes unificados
  /// (cocina, congelador, caducidades, tareas, compra), ordenados por urgencia.
  Widget _remindersCard() {
    final items = _reminders;
    final accent = _cardAccent(DashboardCard.reminders);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: accent.$2),
              const SizedBox(width: AppSpacing.sm),
              Text('Hoy toca', style: AppTextStyles.title),
              if (items.isNotEmpty) ...[
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
                    value: items.length.toDouble(),
                    formatter: (v) => '${v.round()}',
                    style: AppTextStyles.label.copyWith(color: accent.$2),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Row(
              children: [
                const MiauCharacter(
                  mood: MiauMood.sleeping,
                  size: 48,
                  float: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Nada urgente ahora mismo. Todo bajo control 🐾',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          else
          // Mostramos hasta 6 para no saturar; el resto se resume.
          ...[
            for (final r in items.take(6)) _reminderRow(r),
            if (items.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'y ${items.length - 6} más…',
                  style: AppTextStyles.labelMuted,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _reminderRow(Reminder r) {
    // Icono y color por área + urgencia.
    final IconData icon;
    switch (r.kind) {
      case ReminderKind.congelador:
        icon = Icons.ac_unit;
        break;
      case ReminderKind.caducidad:
        icon = Icons.schedule;
        break;
      case ReminderKind.cocina:
        icon = Icons.restaurant_menu;
        break;
      case ReminderKind.tarea:
        icon = Icons.check_circle_outline;
        break;
      case ReminderKind.compra:
        icon = Icons.shopping_cart_outlined;
        break;
    }
    final Color color = switch (r.urgency) {
      ReminderUrgency.urgente => AppColors.expired,
      ReminderUrgency.hoy => AppColors.woodDark,
      ReminderUrgency.pronto => AppColors.sage,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(r.text, style: AppTextStyles.body)),
          if (r.urgency == ReminderUrgency.urgente)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.sm, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.expiredBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '¡Ya!',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.expired,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tarjeta 'Caducidades': resume cuántos alimentos caducan pronto y cuántos
  /// ya han caducado. Al tocarla cambia a la pestaña Despensa > Inventario, que
  /// es donde el inventario vive de verdad, y al volver a Inicio MainShell
  /// refresca el recuento. Si no hay nada que avisar, muestra un mensaje
  /// tranquilizador con el tono cozy de Miau.
  Widget _expiryCard() {
    final accent = _cardAccent(DashboardCard.expiry);
    final hasAlerts = _expiringSoon > 0 || _expired > 0;

    return InkWell(
      borderRadius: AppRadius.lgRadius,
      onTap: () {
        // El inventario vive en la pestaña Despensa > Inventario; en vez de
        // abrir una InventoryScreen suelta a pantalla completa, cambiamos a esa
        // pestaña (sub-tab Inventario por defecto). Al volver a Inicio,
        // MainShell refresca la vista activa, así que el recuento de
        // caducidades se actualiza solo.
        widget.onNavigateToDespensa?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardIconBox(Icons.event_busy, accent),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caducidades', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  if (!hasAlerts)
                    Text(
                      'Todo fresco por aquí 🐾',
                      style: AppTextStyles.bodyMuted,
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_expiringSoon > 0)
                          _expiryCountChip(
                            count: _expiringSoon,
                            singular: 'alimento caduca pronto',
                            plural: 'alimentos caducan pronto',
                            bg: AppColors.soonBg,
                            fg: AppColors.soon,
                          ),
                        if (_expired > 0)
                          _expiryCountChip(
                            count: _expired,
                            singular: 'alimento caducado',
                            plural: 'alimentos caducados',
                            bg: AppColors.expiredBg,
                            fg: AppColors.expired,
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  /// Chip con recuento animado (AnimatedCounter) + etiqueta, para las alertas
  /// de caducidad. Reutiliza los MISMOS textos singular/plural de siempre.
  Widget _expiryCountChip({
    required int count,
    required String singular,
    required String plural,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCounter(
            value: count.toDouble(),
            formatter: (v) => '${v.round()}',
            style: AppTextStyles.bodyStrong.copyWith(color: fg),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count == 1 ? singular : plural,
            style: AppTextStyles.label.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  /// Tarjeta 'Comidas de hoy' con el plan real de meal_plan_entries.
  Widget _mealsCard() {
    final accent = _cardAccent(DashboardCard.meals);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
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
                            Text('fuera', style: AppTextStyles.labelMuted),
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
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
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
            const Icon(Icons.chevron_right, color: Colors.black26),
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
                        backgroundColor: const Color(0xFFEFE7CC),
                        color: over ? Colors.redAccent : AppColors.wood,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      over
                          ? 'Te has pasado ${(total - target).round()} kcal'
                          : 'Te quedan ${(target - total).round()} kcal',
                      style: AppTextStyles.label.copyWith(
                        color: over ? Colors.redAccent : AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
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

    return Container(
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
                      backgroundColor: const Color(0xFFEFE7CC),
                      color: over ? Colors.redAccent : AppColors.wood,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    over
                        ? 'Te has pasado ${(spent - budget).toStringAsFixed(2)} € del presupuesto'
                        : 'Te quedan ${(budget - spent).toStringAsFixed(2)} €',
                    style: AppTextStyles.label.copyWith(
                      color: over ? Colors.redAccent : AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
  _PlanItem({
    required this.mealType,
    required this.title,
    required this.skipped,
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
            child: const Text(
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
                selectedColor: AppColors.wood,
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
