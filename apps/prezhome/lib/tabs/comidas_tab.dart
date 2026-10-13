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
          bottom: TabBar(
            indicatorColor: AppColors.woodDark,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.line,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.inkMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Plan'),
              Tab(text: 'Recetas'),
              Tab(text: 'Diario'),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
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
    final range = _weekStart.month == weekEnd.month
        ? '${_weekStart.day} – ${weekEnd.day} de '
              '${_months[weekEnd.month - 1].toLowerCase()}'
        : '${_weekStart.day} ${_months[_weekStart.month - 1].toLowerCase()} – '
              '${weekEnd.day} ${_months[weekEnd.month - 1].toLowerCase()}';
    final isThisWeek = _isSameDay(_weekStart, _mondayOf(DateTime.now()));

    final days = List<DateTime>.generate(
      7,
      (i) => _weekStart.add(Duration(days: i)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Navegación de semanas: una fila ligera, sin tarjeta.
        Row(
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => _changeWeek(-1),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    isThisWeek ? 'Esta semana' : 'Semana',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.woodDark,
                    ),
                  ),
                  Text(
                    range,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Semana siguiente',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => _changeWeek(1),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!_weekHasPlan)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
            child: Column(
              children: [
                const MiauCharacter(
                  mood: MiauMood.curious,
                  size: 72,
                  float: false,
                ),
                const SizedBox(height: 12),
                Text(
                  'Semana sin plan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea el plan y verás aquí las comidas de cada día.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ],
            ),
          )
        else ...[
          ...days.map(_buildDayCard),
          const SizedBox(height: 8),
          _VarietyCard(planByDate: _planByDate),
        ],

        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MealPlanScreen()));
            _loadWeekPlan(); // refrescar al volver
          },
          icon: Icon(
            _weekHasPlan ? Icons.edit_calendar_rounded : Icons.add_rounded,
          ),
          label: Text(_weekHasPlan ? 'Editar plan' : 'Crear plan'),
        ),
      ],
    );
  }

  static const _mealIcons = {
    'breakfast': Icons.free_breakfast_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'dinner': Icons.dinner_dining_rounded,
    'snack': Icons.cookie_rounded,
    'dessert': Icons.icecream_rounded,
  };

  /// Un día: bloque de fecha a la izquierda y sus comidas a la derecha. Hoy
  /// lleva borde de madera; los días sin plan quedan en una línea.
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration:
          AppTheme.surfaceDecoration(
            radius: AppRadius.md,
            elevation: isToday ? 2 : 1,
          ).copyWith(
            border: isToday
                ? Border.all(color: AppColors.wood, width: 2)
                : null,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isToday ? AppColors.wood : AppColors.cream,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Text(
                  _weekdayNames[date.weekday - 1].substring(0, 3),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isToday ? AppColors.ink : AppColors.inkMuted,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      'Sin plan',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final it in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _mealIcons[it.mealType] ??
                                    Icons.restaurant_rounded,
                                size: 18,
                                color: it.skipped
                                    ? AppColors.inkMuted
                                    : AppColors.woodDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mealLabels[it.mealType] ?? it.mealType,
                                      style: TextStyle(
                                        color: AppColors.inkMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      it.skipped
                                          ? '${it.title} · fuera'
                                          : it.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        decoration: it.skipped
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: it.skipped
                                            ? AppColors.inkMuted
                                            : AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VARIEDAD DE LA SEMANA',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
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
            style: TextStyle(color: AppColors.inkMuted),
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
      mensajeColor = AppColors.inkMuted;
    } else if (ratio >= 0.75) {
      mensaje = 'Menú variado';
      mensajeColor = AppColors.woodDark;
    } else if (ratio >= 0.5) {
      mensaje = 'Menú bastante variado';
      mensajeColor = AppColors.woodDark;
    } else {
      mensaje = 'Se repiten varias recetas';
      mensajeColor = AppColors.inkMuted;
    }

    final comidasLabel = numeroComidas == 1 ? 'comida' : 'comidas';
    final recetasLabel = numeroRecetasDistintas == 1
        ? 'receta distinta'
        : 'recetas distintas';

    // Recetas de más a menos repetida. Barras horizontales con el nombre
    // entero encima: nada se corta, ni el texto ni la barra.
    final ordenadas = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordenadas.take(5).toList();
    final maxCount = top.isEmpty ? 1 : top.first.value;

    return [
      Text(
        '$numeroRecetasDistintas $recetasLabel en $numeroComidas $comidasLabel',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
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
      for (final e in top)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.value} ${e.value == 1 ? 'vez' : 'veces'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: e.value / maxCount,
                  minHeight: 8,
                  color: e.value > 2 ? AppColors.terracotta : AppColors.wood,
                  backgroundColor: AppColors.line,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
