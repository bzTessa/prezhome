import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../meal_plan_screen.dart';
import '../models/meal_plan_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/miau_character.dart';

/// Pestaña de Inicio: se puede ver como Dashboard o como Calendario,
/// con un conmutador arriba a la derecha.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _calendarView = false; // false = dashboard, true = calendario

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('PrezHome'),
        actions: [
          // Conmutador Dashboard <-> Calendario
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ViewToggle(
              calendar: _calendarView,
              onChanged: (v) => setState(() => _calendarView = v),
            ),
          ),
        ],
      ),
      body: _calendarView ? const _CalendarView() : const _DashboardView(),
    );
  }
}

/// Botón segmentado para cambiar de vista.
class _ViewToggle extends StatelessWidget {
  final bool calendar;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.calendar, required this.onChanged});

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
          _seg(Icons.dashboard_rounded, !calendar, () => onChanged(false)),
          _seg(Icons.calendar_month_rounded, calendar, () => onChanged(true)),
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
class _DashboardView extends StatelessWidget {
  const _DashboardView();

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

        // Tarjetas de resumen (placeholder hasta que exista el planificador)
        _summaryCard(
          icon: Icons.restaurant_menu,
          title: 'Comidas de hoy',
          subtitle: 'Aún no hay un plan para hoy',
          color: const Color(0xFFFDEFC8),
        ),
        const SizedBox(height: 12),
        _summaryCard(
          icon: Icons.check_circle_outline,
          title: 'Tareas del hogar',
          subtitle: 'Próximamente',
          color: const Color(0xFFE8F0DC),
        ),
        const SizedBox(height: 12),
        _summaryCard(
          icon: Icons.savings_outlined,
          title: 'Gasto del mes',
          subtitle: 'Próximamente',
          color: const Color(0xFFF3E4D7),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
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
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54),
                ),
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
  const _CalendarView();

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
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
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
        byDate.putIfAbsent(key, () => []).add(
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
    } catch (_) {
      // Silencioso: si falla, el calendario se ve sin plan.
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
      final isSelected = date.year == _selected.year &&
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
                      MaterialPageRoute(
                        builder: (_) => const MealPlanScreen(),
                      ),
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
          const MiauCharacter(
            mood: MiauMood.curious,
            size: 48,
            float: false,
          ),
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
                    decoration:
                        it.skipped ? TextDecoration.lineThrough : null,
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
