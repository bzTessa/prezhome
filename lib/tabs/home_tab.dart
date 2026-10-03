import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../add_inventory_item_screen.dart';
import '../add_recipe_chooser.dart';
import '../food_diary_screen.dart';
import '../inventory_screen.dart';
import '../meal_plan_screen.dart';
import '../month_calendar_screen.dart';
import '../profile_wizard_screen.dart';
import '../scan_ticket_screen.dart';
import '../shopping_list_screen.dart';
import '../models/dashboard_prefs.dart';
import '../models/inventory_item.dart';
import '../models/meal_plan_entry.dart';
import '../models/nutrition_profile.dart';
import '../models/task.dart';
import '../services/task_scheduler.dart';
import '../theme/app_theme.dart';
import '../widgets/miau_character.dart';

/// Pestaña de Inicio: dashboard con el resumen del día del hogar (comidas de
/// hoy, calorías, tareas y gasto). El plan semanal/mensual vive ahora en la
/// pestaña Comidas > Plan, así que Inicio solo muestra el resumen.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

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
        padding: const EdgeInsets.all(20),
        children: [
          // Cabecera con Presidente Miau como personaje
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Row(
              children: [
                const MiauCharacter(mood: MiauMood.greeting, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Este es el resumen de tu hogar',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Accesos rápidos a lo que más usas (personalizables).
          if (_prefs.quick.isNotEmpty) ...[
            _quickAccessRow(),
            const SizedBox(height: 20),
          ],

          Text(
            'Hoy',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),

          // Si el perfil no está completo o aún no hay objetivo de calorías,
          // invitamos a calcularlo (independiente de la personalización).
          if (!_profileComplete ||
              _targetCalories == null ||
              _targetCalories! <= 0) ...[
            _calorieGoalPrompt(),
            const SizedBox(height: 12),
          ],

          // Tarjetas en el orden y visibilidad elegidos por el usuario.
          for (final card in _prefs.visibleCards) ...[
            _cardWidget(card),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// Devuelve el widget de una tarjeta del dashboard por su tipo.
  Widget _cardWidget(DashboardCard card) {
    switch (card) {
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
      case DashboardCard.calendar:
        return _calendarCard();
    }
  }

  /// Fila horizontal de accesos rápidos elegidos por el usuario.
  Widget _quickAccessRow() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _prefs.quick.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _quickAccessButton(_prefs.quick[i]),
      ),
    );
  }

  Widget _quickAccessButton(QuickAction action) {
    return GestureDetector(
      onTap: () => _runQuickAction(action),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: AppTheme.cardDecoration(radius: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.wood,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: AppColors.ink, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w600,
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

  /// Tarjeta 'Caducidades': resume cuántos alimentos caducan pronto y cuántos
  /// ya han caducado. Al tocarla abre la Despensa (InventoryScreen a pantalla
  /// completa) y, al volver, refresca el recuento. Si no hay nada que avisar,
  /// muestra un mensaje tranquilizador con el tono cozy de Miau.
  Widget _expiryCard() {
    const color = AppColors.soonBg;
    final hasAlerts = _expiringSoon > 0 || _expired > 0;

    String statusText;
    if (!hasAlerts) {
      statusText = 'Todo fresco por aquí 🐾';
    } else {
      final parts = <String>[];
      if (_expiringSoon > 0) {
        parts.add(
          _expiringSoon == 1
              ? '1 alimento caduca pronto'
              : '$_expiringSoon alimentos caducan pronto',
        );
      }
      if (_expired > 0) {
        parts.add(
          _expired == 1
              ? '1 alimento caducado'
              : '$_expired alimentos caducados',
        );
      }
      statusText = parts.join(' · ');
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const InventoryScreen()));
        _loadExpirySummary(); // refrescar al volver de la despensa
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.event_busy, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caducidades',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: hasAlerts
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasAlerts ? AppColors.ink : Colors.grey[700],
                    ),
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

  /// Tarjeta 'Calendario del mes': abre la vista mensual con comidas y tareas
  /// (incluidas las apariciones futuras de las recurrentes). Al volver,
  /// refresca el resumen del dashboard.
  Widget _calendarCard() {
    const color = Color(0xFFE2DAF0);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MonthCalendarScreen()));
        _loadDashboard(); // refrescar al volver del calendario
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_month, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calendario del mes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comidas y tareas de todo el mes, día a día.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
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

  /// Tarjeta 'Comidas de hoy' con el plan real de meal_plan_entries.
  Widget _mealsCard() {
    const color = Color(0xFFFDEFC8);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.restaurant_menu, color: AppColors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comidas de hoy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                if (_todayItems.isEmpty)
                  const Text(
                    'Aún no hay un plan para hoy',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ..._todayItems.map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              _mealLabels[it.mealType] ?? it.mealType,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              it.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: it.skipped
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: it.skipped ? Colors.grey : AppColors.ink,
                              ),
                            ),
                          ),
                          if (it.skipped)
                            Text(
                              'fuera',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
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
    const color = Color(0xFFE8F0DC);
    final count = _pendingTasks.length;
    final today = _todayTasks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tareas del hogar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (count == 0)
                      const Text(
                        'Todo al día',
                        style: TextStyle(color: Colors.black54),
                      )
                    else if (today.isEmpty)
                      Text(
                        count == 1
                            ? '1 tarea pendiente (ninguna para hoy)'
                            : '$count tareas pendientes (ninguna para hoy)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    else
                      Text(
                        today.length == 1
                            ? 'Para hoy: 1 tarea'
                            : 'Para hoy: ${today.length} tareas',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Lista de tareas de hoy, cada una marcable de un toque.
          if (today.isNotEmpty) ...[
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _completeTaskFromDashboard(t),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: Colors.grey, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          if (_taskWhen(t) != null) ...[
            const SizedBox(width: 8),
            Text(
              _taskWhen(t)!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
          const SizedBox(width: 8),
          Text(
            '${t.points} pts',
            style: const TextStyle(
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
  /// ProfileWizardScreen y, al volver, refresca el resumen de calorías.
  Widget _calorieGoalPrompt() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileWizardScreen()));
        _loadCaloriesSummary(); // refrescar al volver del cuestionario
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calcula tu objetivo de calorías',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Responde unas preguntas rápidas y adaptaré PrezHome a ti.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
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
    const color = Color(0xFFFBE3D4);
    final total = _todayCalories;
    final target = _targetCalories;
    final hasTarget = target != null && target > 0;
    final ratio = hasTarget ? (total / target).clamp(0.0, 1.0) : 0.0;
    final over = hasTarget && total > target;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FoodDiaryScreen()));
        _loadCaloriesSummary(); // refrescar al volver del diario
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calorías de hoy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasTarget
                        ? 'Hoy has comido ${total.round()} kcal de $target'
                        : 'Hoy has comido ${total.round()} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (hasTarget) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEFE7CC),
                        color: over ? Colors.redAccent : AppColors.wood,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      over
                          ? 'Te has pasado ${(total - target).round()} kcal'
                          : 'Te quedan ${(target - total).round()} kcal',
                      style: TextStyle(
                        color: over ? Colors.redAccent : Colors.grey[700],
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
    const color = Color(0xFFF3E4D7);
    final spent = _monthSpent;
    final budget = _monthBudget;
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = budget > 0 && spent > budget;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.savings_outlined, color: AppColors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gasto del mes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '${spent.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                if (budget > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFEFE7CC),
                      color: over ? Colors.redAccent : AppColors.wood,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    over
                        ? 'Te has pasado ${(spent - budget).toStringAsFixed(2)} € del presupuesto'
                        : 'Te quedan ${(budget - spent).toStringAsFixed(2)} €',
                    style: TextStyle(
                      color: over ? Colors.redAccent : Colors.grey[700],
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
    Navigator.of(
      context,
    ).pop(DashboardPrefs(order: _order, hidden: _hidden, quick: _quick));
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
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
