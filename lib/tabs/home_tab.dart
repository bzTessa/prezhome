import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

/// Pestaña de Inicio: se puede ver como Dashboard o como Calendario,
/// con un conmutador arriba a la derecha.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _calendarView = false; // false = dashboard, true = calendario

  String get _greetingName {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final name = meta?['full_name'];
    return (name is String && name.isNotEmpty) ? name : '';
  }

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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Cabecera con Presidente Miau
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/presidente_prezhome.jpg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola! 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Presidente Miau supervisa el hogar 🐱👑',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Resumen de hoy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
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
            child: Center(
              child: Text(
                '$d',
                style: TextStyle(
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: AppColors.ink,
                ),
              ),
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
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/presidente_prezhome.jpg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aquí verás tus comidas y tareas del día cuando '
                      'actives el planificador semanal.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
