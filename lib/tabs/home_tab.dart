import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../food_diary_screen.dart';
import '../meal_plan_screen.dart';
import '../models/meal_plan_entry.dart';
import '../models/nutrition_profile.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/miau_character.dart';

/// Vistas disponibles en la pestaña de Inicio.
enum _HomeView { dashboard, semana, mes }

/// Pestaña de Inicio: se puede ver como Dashboard, como agenda de la Semana
/// o como calendario del Mes, con un conmutador arriba a la derecha.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  // Vista activa. El arranque de la pestaña sigue siendo el Dashboard.
  _HomeView _view = _HomeView.dashboard;

  // Claves para poder forzar la recarga de la vista activa sin reconstruir
  // la pestaña completa ni las demás pestañas del IndexedStack.
  final GlobalKey<_DashboardViewState> _dashboardKey =
      GlobalKey<_DashboardViewState>();
  final GlobalKey<_WeekAgendaViewState> _weekKey =
      GlobalKey<_WeekAgendaViewState>();
  final GlobalKey<_CalendarViewState> _calendarKey =
      GlobalKey<_CalendarViewState>();

  /// Recarga los datos de la vista actualmente visible. Lo llama MainShell
  /// cuando la pestaña Inicio vuelve a estar en primer plano, para reflejar
  /// un plan recién generado sin recargar toda la app.
  void refreshActiveView() {
    switch (_view) {
      case _HomeView.dashboard:
        _dashboardKey.currentState?.reload();
        break;
      case _HomeView.semana:
        _weekKey.currentState?.reload();
        break;
      case _HomeView.mes:
        _calendarKey.currentState?.reload();
        break;
    }
  }

  Widget _buildBody() {
    switch (_view) {
      case _HomeView.dashboard:
        return _DashboardView(key: _dashboardKey);
      case _HomeView.semana:
        return _WeekAgendaView(key: _weekKey);
      case _HomeView.mes:
        return _CalendarView(key: _calendarKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('PrezHome'),
        actions: [
          // Conmutador Dashboard <-> Semana <-> Mes
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ViewToggle(
              current: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

/// Botón segmentado para cambiar de vista.
class _ViewToggle extends StatelessWidget {
  final _HomeView current;
  final ValueChanged<_HomeView> onChanged;
  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _seg(
            Icons.dashboard_rounded,
            current == _HomeView.dashboard,
            () => onChanged(_HomeView.dashboard),
          ),
          _seg(
            Icons.view_agenda_rounded,
            current == _HomeView.semana,
            () => onChanged(_HomeView.semana),
          ),
          _seg(
            Icons.calendar_month_rounded,
            current == _HomeView.mes,
            () => onChanged(_HomeView.mes),
          ),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.wood : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

/// Vista Dashboard: cabecera con Miau + resumen del día.
class _DashboardView extends StatefulWidget {
  const _DashboardView({super.key});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final SupabaseClient _client = Supabase.instance.client;

  // Comidas planificadas para HOY (mismo patrón que _CalendarView).
  List<_PlanItem> _todayItems = [];

  // Resumen de tareas pendientes del hogar (is_done == false).
  List<HomeTask> _pendingTasks = [];

  // Resumen de economía del mes en curso.
  double _monthSpent = 0;
  double _monthBudget = 0;

  // Resumen de calorías de hoy (diario de consumo personal).
  double _todayCalories = 0;
  int? _targetCalories;

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

  /// Permite a HomeTab forzar una recarga de todo el dashboard.
  void reload() => _loadDashboard();

  /// Carga todas las secciones del dashboard. Cada carga tiene su propio
  /// try/catch, de modo que un fallo en una no impide ver las demás.
  Future<void> _loadDashboard() async {
    await Future.wait([
      _loadTodayPlan(),
      _loadTasksSummary(),
      _loadEconomySummary(),
      _loadCaloriesSummary(),
    ]);
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
  /// lib/tasks_screen.dart) y las guarda ordenadas: las que tienen fecha
  /// primero (ascendente) y las que no la tienen al final.
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

      // Ordenar por fecha ascendente; las tareas sin fecha van al final.
      pending.sort((a, b) {
        final da = a.dueDate;
        final db = b.dueDate;
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
      final target = profileRow != null
          ? NutritionProfile.fromMap(profileRow).targetCalories
          : null;

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
        });
      }
    } catch (e) {
      // No rompemos la UI (la tarjeta se ve a 0), pero dejamos traza del
      // error para no confundir un fallo de carga con un día sin comidas.
      debugPrint('HomeTab._loadCaloriesSummary error: $e');
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
    return ListView(
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
        const SizedBox(height: 28),

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

        // Resumen de las comidas planificadas para hoy.
        _mealsCard(),
        const SizedBox(height: 12),
        _caloriesCard(),
        const SizedBox(height: 12),
        _tasksCard(),
        const SizedBox(height: 12),
        _spendingCard(),
      ],
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

  /// Tarjeta 'Tareas del hogar' con el recuento de pendientes y las próximas.
  Widget _tasksCard() {
    const color = Color(0xFFE8F0DC);
    final count = _pendingTasks.length;
    // Hasta 3 próximas tareas (ya vienen ordenadas por fecha ascendente).
    final next = _pendingTasks.take(3).toList();

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
            child: const Icon(Icons.check_circle_outline, color: AppColors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tareas del hogar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                if (count == 0)
                  const Text(
                    'Todo al día',
                    style: TextStyle(color: Colors.black54),
                  )
                else ...[
                  Text(
                    count == 1
                        ? '1 tarea pendiente'
                        : '$count tareas pendientes',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ...next.map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  /// Texto breve de cuándo toca una tarea: 'Hoy', 'Mañana' o 'dd/mm'.
  /// Devuelve null si la tarea no tiene fecha.
  String? _taskWhen(HomeTask t) {
    final due = t.dueDate;
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

/// Vista Calendario: mes actual con selección de día (estructura base).
class _CalendarView extends StatefulWidget {
  const _CalendarView({super.key});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  final SupabaseClient _client = Supabase.instance.client;
  // Plan cargado: 'yyyy-mm-dd' -> lista de (tipo, titulo receta, skipped)
  Map<String, List<_PlanItem>> _planByDate = {};
  Set<String> _daysWithPlan = {};

  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  static const _mealLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Snack',
    'dessert': 'Postre',
  };

  @override
  void initState() {
    super.initState();
    _loadMonthPlan();
  }

  /// Permite a HomeTab forzar una recarga del calendario.
  void reload() => _loadMonthPlan();

  Future<void> _loadMonthPlan() async {
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

      final start = DateTime(_month.year, _month.month, 1);
      final end = DateTime(_month.year, _month.month + 1, 1);
      // Traer entries del mes con el título de la receta.
      final res = await _client
          .from('meal_plan_entries')
          .select('plan_date, meal_type, skipped, recipes(title)')
          .eq('home_id', homeId)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);

      final byDate = <String, List<_PlanItem>>{};
      final withPlan = <String>{};
      for (final row in (res as List)) {
        final e = MealPlanEntry.fromMap(row);
        final key = e.date.toIso8601String().split('T').first;
        final rec = row['recipes'];
        final title = (rec is Map ? rec['title'] : null) as String?;
        byDate
            .putIfAbsent(key, () => [])
            .add(
              _PlanItem(
                mealType: e.mealType,
                title: title ?? 'Receta',
                skipped: e.skipped,
              ),
            );
        withPlan.add(key);
      }
      if (mounted) {
        setState(() {
          _planByDate = byDate;
          _daysWithPlan = withPlan;
        });
      }
    } catch (e) {
      // No rompemos la UI (el calendario se ve sin plan), pero dejamos traza
      // del error para no confundir un fallo de carga con un mes sin plan.
      debugPrint('HomeTab._loadMonthPlan error: $e');
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadMonthPlan();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday: 1=Lun..7=Dom -> offset para empezar en Lunes
    final leading = firstDay.weekday - 1;

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      final isSelected =
          date.year == _selected.year &&
          date.month == _selected.month &&
          date.day == _selected.day;
      final isToday = _isSameDay(date, DateTime.now());
      final key = date.toIso8601String().split('T').first;
      final hasPlan = _daysWithPlan.contains(key);
      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selected = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.wood : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.wood, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                // Puntito si ese día tiene comidas planificadas
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasPlan && !isSelected
                        ? AppColors.woodDark
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              Row(
                children: _weekdays
                    .map(
                      (w) => Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cells,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan del ${_selected.day} de ${_months[_selected.month - 1]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDayPlan(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                    );
                    _loadMonthPlan(); // refrescar al volver
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.wood, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Gestionar plan semanal'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayPlan() {
    final key = _selected.toIso8601String().split('T').first;
    final items = _planByDate[key] ?? [];
    if (items.isEmpty) {
      return Row(
        children: [
          const MiauCharacter(mood: MiauMood.curious, size: 48, float: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay comidas planificadas este día. Genera el plan semanal.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }
    // Ordenar por tipo de comida (desayuno, comida, cena...)
    const order = ['breakfast', 'lunch', 'dinner', 'snack', 'dessert'];
    items.sort(
      (a, b) => order.indexOf(a.mealType).compareTo(order.indexOf(b.mealType)),
    );
    return Column(
      children: items.map((it) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  _mealLabels[it.mealType] ?? it.mealType,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  it.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: it.skipped ? TextDecoration.lineThrough : null,
                    color: it.skipped ? Colors.grey : AppColors.ink,
                  ),
                ),
              ),
              if (it.skipped)
                Text(
                  'fuera',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Vista Semana: agenda vertical con los 7 días de la semana actual
/// (lunes a domingo) y las comidas de cada día escritas, sin tener que
/// pulsar ningún día. Es la respuesta directa al feedback de ver el plan
/// de un vistazo. Carga sus propios datos, espejo de _CalendarView.
class _WeekAgendaView extends StatefulWidget {
  const _WeekAgendaView({super.key});

  @override
  State<_WeekAgendaView> createState() => _WeekAgendaViewState();
}

class _WeekAgendaViewState extends State<_WeekAgendaView> {
  // Lunes de la semana mostrada actualmente.
  DateTime _weekStart = _mondayOf(DateTime.now());

  final SupabaseClient _client = Supabase.instance.client;
  // Plan cargado: 'yyyy-mm-dd' -> lista de (tipo, titulo receta, skipped)
  Map<String, List<_PlanItem>> _planByDate = {};

  static const _weekdayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
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

  /// Devuelve el lunes de la semana que contiene [d] (a medianoche).
  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadWeekPlan();
  }

  /// Permite a HomeTab forzar una recarga de la agenda semanal.
  void reload() => _loadWeekPlan();

  Future<void> _loadWeekPlan() async {
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

      // Rango acotado a la semana mostrada: lunes incluido, lunes siguiente
      // excluido (misma técnica que _loadMonthPlan).
      final start = _weekStart;
      final end = _weekStart.add(const Duration(days: 7));
      final res = await _client
          .from('meal_plan_entries')
          .select('plan_date, meal_type, skipped, recipes(title)')
          .eq('home_id', homeId)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);

      final byDate = <String, List<_PlanItem>>{};
      for (final row in (res as List)) {
        final e = MealPlanEntry.fromMap(row);
        final key = e.date.toIso8601String().split('T').first;
        final rec = row['recipes'];
        final title = (rec is Map ? rec['title'] : null) as String?;
        byDate
            .putIfAbsent(key, () => [])
            .add(
              _PlanItem(
                mealType: e.mealType,
                title: title ?? 'Receta',
                skipped: e.skipped,
              ),
            );
      }
      if (mounted) {
        setState(() => _planByDate = byDate);
      }
    } catch (e) {
      // No rompemos la UI (la agenda se ve sin plan), pero dejamos traza del
      // error para no confundir un fallo de carga con una semana sin plan.
      debugPrint('HomeTab._loadWeekPlan error: $e');
    }
  }

  void _changeWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * delta)));
    _loadWeekPlan();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _weekHasPlan => _planByDate.values.any((items) => items.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final title =
        'Semana del ${_weekStart.day} de ${_months[_weekStart.month - 1]}';

    final days = List<DateTime>.generate(
      7,
      (i) => _weekStart.add(Duration(days: i)),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Cabecera con navegación de semanas.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeWeek(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_weekStart.day} ${_months[_weekStart.month - 1]} - '
                      '${weekEnd.day} ${_months[weekEnd.month - 1]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Estado vacío: ningún día de la semana tiene plan.
        if (!_weekHasPlan)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Row(
              children: [
                const MiauCharacter(
                  mood: MiauMood.curious,
                  size: 56,
                  float: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta semana aún no tiene plan. Genera el plan semanal '
                    'para ver aquí las comidas de cada día.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          )
        else
          ...days.map(_buildDayCard),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MealPlanScreen()));
              _loadWeekPlan(); // refrescar al volver
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.wood, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Gestionar plan semanal'),
          ),
        ),
      ],
    );
  }

  /// Tarjeta de un día: cabecera (nombre + número, HOY resaltado) y las
  /// comidas del día escritas.
  Widget _buildDayCard(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());
    final key = date.toIso8601String().split('T').first;
    final items = [...(_planByDate[key] ?? <_PlanItem>[])];
    items.sort(
      (a, b) => _mealOrder
          .indexOf(a.mealType)
          .compareTo(_mealOrder.indexOf(b.mealType)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del día; se resalta HOY con un fondo wood.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.wood : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday
                      ? null
                      : Border.all(color: AppColors.wood, width: 1.2),
                ),
                child: Text(
                  '${_weekdayNames[date.weekday - 1]} ${date.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Text(
                  'Hoy',
                  style: TextStyle(
                    color: AppColors.woodDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'Sin plan',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )
          else
            ...items.map(
              (it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        _mealLabels[it.mealType] ?? it.mealType,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        it.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
