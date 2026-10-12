import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../food_diary_screen.dart';
import '../meal_plan_screen.dart';
import '../month_calendar_screen.dart';
import '../recipes_screen.dart';
import '../models/meal_plan_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/miau_character.dart';

/// Vistas disponibles dentro de la sub-pestaña Plan.
enum _PlanView { semana, mes }

/// Pestaña "Comidas": agrupa todo lo relacionado con comer en un mismo
/// lugar, como hacen las apps de planificación de comidas. Tiene tres
/// sub-tabs: Plan (agenda semanal/mensual del hogar), Recetas (recetario)
/// y Diario (diario de calorías personal).
class ComidasTab extends StatelessWidget {
  const ComidasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Comidas'),
          bottom: const TabBar(
            indicatorColor: AppColors.woodDark,
            labelColor: AppColors.ink,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Plan', icon: Icon(Icons.calendar_month_rounded)),
              Tab(text: 'Recetas', icon: Icon(Icons.restaurant_menu)),
              Tab(text: 'Diario', icon: Icon(Icons.local_fire_department)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Cada pantalla trae su propio contenido y botón flotante.
            _PlanTab(),
            _EmbeddedRecipes(),
            _EmbeddedDiary(),
          ],
        ),
      ),
    );
  }
}

// Envolvemos las pantallas existentes para reutilizarlas dentro de las tabs.
class _EmbeddedRecipes extends StatelessWidget {
  const _EmbeddedRecipes();
  @override
  Widget build(BuildContext context) => const RecipesScreen(embedded: true);
}

class _EmbeddedDiary extends StatelessWidget {
  const _EmbeddedDiary();
  @override
  Widget build(BuildContext context) => const FoodDiaryScreen(embedded: true);
}

/// Sub-pestaña Plan: muestra el plan de comidas del hogar como agenda de la
/// semana o como calendario del mes, con un conmutador arriba, y un botón
/// para abrir el gestor del plan semanal. La lógica de plan vivía antes en
/// la pestaña Inicio y se ha trasladado aquí.
class _PlanTab extends StatefulWidget {
  const _PlanTab();

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  _PlanView _view = _PlanView.semana;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlanViewToggle(
                current: _view,
                onChanged: (v) {
                  setState(() {
                    _view = v;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _view == _PlanView.semana
              ? const _WeekAgendaView()
              : const MonthCalendarScreen(embedded: true),
        ),
      ],
    );
  }
}

/// Botón segmentado para cambiar entre la vista de Semana y la de Mes.
class _PlanViewToggle extends StatelessWidget {
  final _PlanView current;
  final ValueChanged<_PlanView> onChanged;
  const _PlanViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(
            Icons.view_agenda_rounded,
            'Semana',
            current == _PlanView.semana,
            () => onChanged(_PlanView.semana),
          ),
          _seg(
            Icons.calendar_month_rounded,
            'Mes',
            current == _PlanView.mes,
            () => onChanged(_PlanView.mes),
          ),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.wood : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista Semana: agenda vertical con los 7 días de la semana actual
/// (lunes a domingo) y las comidas de cada día escritas, sin tener que
/// pulsar ningún día. Carga sus propios datos del plan de la semana.
class _WeekAgendaView extends StatefulWidget {
  const _WeekAgendaView();

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
      debugPrint('ComidasTab._loadWeekPlan error: $e');
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

        // Tarjeta de variedad del menú: solo tiene sentido si hay plan en la
        // semana. Si no, abajo ya se muestra el bloque de Miau.
        if (_weekHasPlan) ...[
          _VarietyCard(planByDate: _planByDate),
          const SizedBox(height: 16),
        ],

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

/// Tarjeta "Variedad de la semana": reutiliza el plan ya cargado en
/// [_planByDate] (sin consulta extra) para mostrar de un vistazo si el menú
/// está variado o repetitivo. Cuenta las comidas planificadas que NO están
/// saltadas, cuántas recetas distintas hay y cuántas veces se repite cada una.
class _VarietyCard extends StatelessWidget {
  final Map<String, List<_PlanItem>> planByDate;
  const _VarietyCard({required this.planByDate});

  @override
  Widget build(BuildContext context) {
    // Conteo por título solo de las comidas que de verdad se van a hacer
    // (ignoramos las saltadas: no cuentan para la variedad real del menú).
    final counts = <String, int>{};
    for (final items in planByDate.values) {
      for (final it in items) {
        if (it.skipped) continue;
        counts[it.title] = (counts[it.title] ?? 0) + 1;
      }
    }

    final numeroComidas = counts.values.fold<int>(0, (a, b) => a + b);
    final numeroRecetasDistintas = counts.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VARIEDAD DE LA SEMANA',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          if (numeroComidas == 0)
            _allSkipped()
          else
            ..._content(numeroComidas, numeroRecetasDistintas, counts),
        ],
      ),
    );
  }

  /// Caso en el que todas las comidas de la semana están marcadas como fuera:
  /// no tiene sentido dibujar una gráfica vacía, mejor un mensaje amable.
  Widget _allSkipped() {
    return Row(
      children: [
        const MiauCharacter(mood: MiauMood.curious, size: 56, float: false),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Esta semana todas las comidas están marcadas como fuera de casa. '
            'Cuando planifiquéis platos verás aquí si el menú es variado.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  List<Widget> _content(
    int numeroComidas,
    int numeroRecetasDistintas,
    Map<String, int> counts,
  ) {
    // Indicador cualitativo simple y sin jerga: comparamos recetas distintas
    // frente al total de comidas. Cuanto más cerca de 1, más variado.
    final ratio = numeroComidas == 0
        ? 0.0
        : numeroRecetasDistintas / numeroComidas;
    final String mensaje;
    final Color mensajeColor;
    if (numeroRecetasDistintas <= 1) {
      mensaje = 'Menú muy repetitivo';
      mensajeColor = Colors.grey[700]!;
    } else if (ratio >= 0.75) {
      mensaje = '¡Menú muy variado!';
      mensajeColor = AppColors.woodDark;
    } else if (ratio >= 0.5) {
      mensaje = 'Menú bastante variado';
      mensajeColor = AppColors.woodDark;
    } else {
      mensaje = 'Se repiten varias recetas';
      mensajeColor = Colors.grey[700]!;
    }

    final comidasLabel = numeroComidas == 1 ? 'comida' : 'comidas';
    final recetasLabel = numeroRecetasDistintas == 1
        ? 'receta distinta'
        : 'recetas distintas';

    // Top de recetas más repetidas, de mayor a menor. Limitamos a 6 para que
    // la gráfica no se sature cuando hay muchos platos distintos.
    final ordenadas = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordenadas.take(6).toList();
    final maxCount = top.fold<int>(0, (a, e) => e.value > a ? e.value : a);
    final maxY = maxCount <= 0 ? 1.0 : maxCount * 1.2;

    return [
      Text(
        '$numeroRecetasDistintas $recetasLabel en $numeroComidas $comidasLabel',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        mensaje,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: mensajeColor,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final veces = rod.toY.toInt();
                  return BarTooltipItem(
                    '${top[group.x].key}\n'
                    '$veces ${veces == 1 ? 'vez' : 'veces'}',
                    const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= top.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _shortTitle(top[i].key),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < top.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: top[i].value.toDouble(),
                      color: AppColors.wood,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Acorta títulos largos para que no se solapen bajo las barras.
  String _shortTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.length <= 10) return trimmed;
    return '${trimmed.substring(0, 9)}…';
  }
}
