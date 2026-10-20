import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/meal_plan_entry.dart';
import 'models/recipe.dart';
import 'models/task.dart';
import 'services/meal_prep_planner.dart';
import 'services/plan_prefs.dart';
import 'services/plan_prep.dart';
import 'services/task_scheduler.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';
import 'widgets/plan/plan_parts.dart';
import 'utils/friendly_error.dart';

/// Calendario MENSUAL del hogar, todo junto: comidas planificadas, tareas
/// (con las apariciones futuras de las recurrentes, [TaskOccurrences]) y la
/// cocina en lote (compra, día de cocinar y qué pasar a la nevera).
///
/// Es el ÚNICO calendario mensual de la app; se abre desde Comidas > Plan.
/// Al tocar un día se ve su detalle en el panel inferior.
class MonthCalendarScreen extends StatefulWidget {
  const MonthCalendarScreen({super.key});

  @override
  State<MonthCalendarScreen> createState() => _MonthCalendarScreenState();
}

class _MonthCalendarScreenState extends State<MonthCalendarScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  late Future<_MonthData> _future;
  // Primer dia del mes visible (dia 1). Arranca en el mes actual.
  late DateTime _visibleMonth;
  // Dia seleccionado para ver su detalle (comidas + tareas).
  late DateTime _selectedDay;

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
  static const _monthNames = [
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
  static const _weekdayHeaders = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _future = _load();
  }

  void _reload() {
    final f = _load();
    setState(() {
      _future = f;
    });
  }

  void _changeMonth(int delta) {
    final m = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    setState(() {
      _visibleMonth = m;
      // Al cambiar de mes, seleccionamos su dia 1 (o hoy si es el mes actual).
      final now = DateTime.now();
      if (m.year == now.year && m.month == now.month) {
        _selectedDay = DateTime(now.year, now.month, now.day);
      } else {
        _selectedDay = DateTime(m.year, m.month, 1);
      }
    });
    _reload();
  }

  DateTime get _monthStart => _visibleMonth;
  DateTime get _monthEnd =>
      DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

  Future<_MonthData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return _MonthData(homeId: null);

    final start = _monthStart;
    final end = _monthEnd;

    // Comidas del mes (mismo patron que meal_plan_screen / _loadTodayPlan).
    final mealsRes = await _client
        .from('meal_plan_entries')
        .select(
          'plan_date, meal_type, skipped, recipe_id, servings, recipes(title)',
        )
        .eq('home_id', homeId)
        .gte('plan_date', _day(_gridStart))
        .lte('plan_date', _day(_gridEnd));

    final entries = <MealPlanEntry>[];
    final mealsByDay = <DateTime, List<_PlanItem>>{};
    for (final row in (mealsRes as List)) {
      final e = MealPlanEntry.fromMap(row);
      entries.add(e);
      final rec = row['recipes'];
      final title = (rec is Map ? rec['title'] : null) as String?;
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      (mealsByDay[key] ??= []).add(
        _PlanItem(
          mealType: e.mealType,
          title: title ?? 'Receta',
          skipped: e.skipped,
        ),
      );
    }
    for (final list in mealsByDay.values) {
      list.sort(
        (a, b) => _mealOrder
            .indexOf(a.mealType)
            .compareTo(_mealOrder.indexOf(b.mealType)),
      );
    }

    // Tareas del hogar (todas las no completadas puntuales + recurrentes) para
    // proyectar sus apariciones dentro del mes visible.
    final tasksRes = await _client.from('tasks').select().eq('home_id', homeId);
    final tasks = (tasksRes as List).map((m) => HomeTask.fromMap(m)).toList();

    final tasksByDay = <DateTime, List<HomeTask>>{};
    for (final t in tasks) {
      final days = TaskOccurrences.inRange(t, start, end);
      for (final d in days) {
        (tasksByDay[d] ??= []).add(t);
      }
    }

    // Cocina en lote: si alguien del hogar cocina en tanda, la agenda de cada
    // semana que toca el mes (la misma que enseña el plan semanal).
    final prepByDay = <DateTime, List<PrepEvent>>{};
    final modes = await _client
        .from('profiles')
        .select('cooking_mode')
        .eq('home_id', homeId);
    final batch = (modes as List).any((m) => m['cooking_mode'] == 'mealprep');
    if (batch && entries.isNotEmpty) {
      final recRes = await _client
          .from('recipes')
          .select()
          .eq('home_id', homeId);
      final recipes = {
        for (final m in (recRes as List)) m['id'] as String: Recipe.fromMap(m),
      };
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (
        var w = _gridStart;
        !w.isAfter(_gridEnd);
        w = DateTime(w.year, w.month, w.day + 7)
      ) {
        final plan = prepPlanForWeek(
          entries: entries,
          recipesById: recipes,
          weekStart: w,
          energyLevel: PlanPrefs.current.value.energy,
        );
        for (final ev in prepAgenda(plan, earliest: today)) {
          (prepByDay[ev.date] ??= []).add(ev);
        }
      }
    }

    return _MonthData(
      homeId: homeId,
      mealsByDay: mealsByDay,
      tasksByDay: tasksByDay,
      prepByDay: prepByDay,
    );
  }

  String _day(DateTime d) => d.toIso8601String().split('T').first;

  /// Lunes de la semana del día 1 y domingo de la del último día: semanas
  /// enteras, para que la cocina en lote de una semana partida salga bien.
  DateTime get _gridStart =>
      DateTime(_monthStart.year, _monthStart.month, 2 - _monthStart.weekday);
  DateTime get _gridEnd => DateTime(
    _monthEnd.year,
    _monthEnd.month,
    _monthEnd.day + 7 - _monthEnd.weekday,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Calendario')),
      body: FutureBuilder<_MonthData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return const Center(child: Text('No perteneces a ningún hogar.'));
          }
          return Column(
            children: [
              _header(),
              _weekdayRow(),
              Expanded(child: SingleChildScrollView(child: _grid(data))),
              _dayDetail(data),
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    final label =
        '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Anterior',
            icon: Icon(Icons.chevron_left, color: AppColors.woodDark),
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Siguiente',
            icon: Icon(Icons.chevron_right, color: AppColors.woodDark),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _weekdayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _weekdayHeaders
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _grid(_MonthData data) {
    final first = _monthStart;
    final daysInMonth = _monthEnd.day;
    // weekday: 1=Lun..7=Dom -> huecos vacios antes del dia 1.
    final leading = first.weekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    for (var i = 0; i < rows * 7; i++) {
      final dayNum = i - leading + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        cells.add(const SizedBox());
        continue;
      }
      final day = DateTime(first.year, first.month, dayNum);
      final isToday = day == today;
      final isSelected = day == _selectedDay;
      final hasMeals = (data.mealsByDay[day] ?? const []).isNotEmpty;
      final hasTasks = (data.tasksByDay[day] ?? const []).isNotEmpty;
      final prepKinds = {
        for (final e in data.prepByDay[day] ?? const <PrepEvent>[]) e.kind,
      };

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.wood
                  : (isToday
                        ? AppColors.wood.withValues(alpha: 0.35)
                        : AppColors.card),
              borderRadius: BorderRadius.circular(16),
              border: isToday
                  ? Border.all(color: AppColors.woodDark, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasMeals) _dot(AppColors.woodDark),
                    if (hasTasks) _dot(AppColors.sage),
                    for (final k in prepKinds) _dot(prepEventStyle(k).fg),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.82,
        children: cells,
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _dayDetail(_MonthData data) {
    final meals = data.mealsByDay[_selectedDay] ?? const [];
    final tasks = data.tasksByDay[_selectedDay] ?? const [];
    final prep = data.prepByDay[_selectedDay] ?? const <PrepEvent>[];
    final label =
        '${_dayNames[_selectedDay.weekday - 1]} ${_selectedDay.day} de '
        '${_monthNames[_selectedDay.month - 1].toLowerCase()}';
    final empty = meals.isEmpty && tasks.isEmpty && prep.isEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (empty)
            Row(
              children: [
                const MiauCharacter(mood: MiauMood.sleeping, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nada planificado este día.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ),
              ],
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final ev in prep) PrepEventTile(event: ev),
                    if (meals.isNotEmpty) ...[
                      _sectionTitle('Comidas'),
                      ...meals.map(
                        (m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  _mealLabels[m.mealType] ?? m.mealType,
                                  style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  m.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: m.skipped
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: m.skipped
                                        ? AppColors.inkMuted
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (tasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionTitle('Tareas'),
                      ...tasks.map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.sage,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Text(
                                t.recurrenceLabel,
                                style: TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

class _MonthData {
  final String? homeId;
  final Map<DateTime, List<_PlanItem>> mealsByDay;
  final Map<DateTime, List<HomeTask>> tasksByDay;
  final Map<DateTime, List<PrepEvent>> prepByDay;
  _MonthData({
    required this.homeId,
    this.mealsByDay = const {},
    this.tasksByDay = const {},
    this.prepByDay = const {},
  });
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
