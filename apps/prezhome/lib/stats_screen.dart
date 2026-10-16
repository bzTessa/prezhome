import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'economy_screen.dart';
import 'product_stats_screen.dart';
import 'scan_ticket_screen.dart';
import 'services/spend_forecast.dart';
import 'services/home_people.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'utils/ticket_date.dart';
import 'widgets/animations/animated_counter.dart';
import 'widgets/animations/staggered_entrance.dart';
import 'widgets/food_category_icon.dart';

/// "Tus datos": gráficas de gasto (con previsión), compra, despensa, comidas
/// y tareas del hogar en una sola pantalla.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

const _monthShort = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

class _StatsData {
  final double budget;

  /// Gasto de los últimos 6 meses; el último es el mes en curso.
  final List<(String, double)> months;
  final double forecast;
  final List<(String, double)> byCategory;
  final List<(String, double)> topProducts;
  final List<(String, double)> pantryByZone;
  final int expired, expiringSoon, fresh;

  /// Comidas en casa por semana (las 4 últimas, la actual al final).
  final List<(String, double)> mealsByWeek;
  final int mealsOut;
  final List<(String, double)> tasksByPerson;
  final List<(String, double)> tasksByWeek;

  _StatsData({
    required this.budget,
    required this.months,
    required this.forecast,
    required this.byCategory,
    required this.topProducts,
    required this.pantryByZone,
    required this.expired,
    required this.expiringSoon,
    required this.fresh,
    required this.mealsByWeek,
    required this.mealsOut,
    required this.tasksByPerson,
    required this.tasksByWeek,
  });

  double get spent => months.last.$2;
}

String _day(DateTime d) => d.toIso8601String().split('T').first;

DateTime _weekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

/// Mayores primero, y el resto junto en "Otros" para no pasar de [max] filas.
List<(String, double)> _top(Map<String, double> m, int max) {
  final list = m.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
  if (list.length <= max) return list;
  final rest = list.skip(max - 1).fold<double>(0, (a, e) => a + e.$2);
  return [...list.take(max - 1), ('Otros', rest)];
}

class _StatsScreenState extends State<StatsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_StatsData?> _future = _load();

  void _reload() => setState(() => _future = _load());

  Future<_StatsData?> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month);
    final sixAgo = DateTime(now.year, now.month - 5);
    final weeks = [
      for (int i = 3; i >= 0; i--)
        _weekStart(today).subtract(Duration(days: 7 * i)),
    ];
    final since = weeks.first.isBefore(monthStart) ? weeks.first : monthStart;

    final results = await Future.wait<dynamic>([
      _client
          .from('budgets')
          .select('monthly_amount')
          .eq('home_id', homeId)
          .maybeSingle(),
      _client
          .from('tickets')
          .select('total_amount, purchased_at, created_at')
          .eq('home_id', homeId)
          .or(ticketRangeFilter(sixAgo, DateTime(now.year, now.month + 1))),
      _client
          .from('ticket_items')
          .select(
            'name, category, total_price, created_at, tickets(purchased_at)',
          )
          .eq('home_id', homeId)
          .gte('created_at', _day(today.subtract(const Duration(days: 90)))),
      _client
          .from('inventory_items')
          .select('category, expiration_date')
          .eq('home_id', homeId),
      _client
          .from('meal_plan_entries')
          .select('plan_date, skipped')
          .eq('home_id', homeId)
          .gte('plan_date', _day(weeks.first))
          .lte('plan_date', _day(today)),
      _client
          .from('task_points')
          .select('user_id, points, created_at')
          .eq('home_id', homeId)
          .gt('points', 0)
          .gte('created_at', _day(since)),
      _client.from('profiles').select('id, full_name').eq('home_id', homeId),
    ]);

    final budget =
        ((results[0] as Map?)?['monthly_amount'] as num?)?.toDouble() ?? 0;

    // Gasto por mes (misma regla que Gastos y tickets: por fecha de compra).
    final byMonth = <String, double>{};
    for (final t in (results[1] as List)) {
      final d = ticketDate(t as Map);
      if (d == null) continue;
      final k = '${d.year}-${d.month}';
      byMonth[k] =
          (byMonth[k] ?? 0) + ((t['total_amount'] as num?)?.toDouble() ?? 0);
    }
    final months = <(String, double)>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      months.add((
        _monthShort[m.month - 1],
        byMonth['${m.year}-${m.month}'] ?? 0.0,
      ));
    }
    final forecast = forecastMonthSpend(
      spentSoFar: months.last.$2,
      today: today,
      // Los 3 meses anteriores al actual.
      previousMonths: [for (int i = 2; i <= 4; i++) months[i].$2],
    );

    // En qué se gasta este mes y qué se compra más (90 días).
    final byCategory = <String, double>{};
    final productCount = <String, double>{};
    for (final it in (results[2] as List)) {
      final name = _cap((it['name'] as String?)?.trim() ?? '');
      if (name.isNotEmpty) productCount[name] = (productCount[name] ?? 0) + 1;
      final d = ticketDate({...?(it['tickets'] as Map?), ...it as Map});
      if (d == null || d.isBefore(monthStart)) continue;
      final raw = (it['category'] as String?)?.trim() ?? '';
      // Los tickets antiguos guardaban la clave ("lacteos"); los nuevos, el nombre.
      final cat = raw.isEmpty
          ? 'Sin categoría'
          : FoodCategory.values
                    .where((c) => c.name == raw)
                    .firstOrNull
                    ?.label ??
                _cap(raw);
      byCategory[cat] =
          (byCategory[cat] ?? 0) +
          ((it['total_price'] as num?)?.toDouble() ?? 0);
    }

    // Despensa: por zona y estado de caducidad.
    final byZone = <String, double>{};
    var expired = 0, soon = 0, fresh = 0;
    for (final it in (results[3] as List)) {
      final zone = (it['category'] as String?) ?? 'Despensa';
      byZone[zone] = (byZone[zone] ?? 0) + 1;
      final exp = DateTime.tryParse(it['expiration_date'] as String? ?? '');
      if (exp != null && exp.isBefore(today)) {
        expired++;
      } else if (exp != null && exp.difference(today).inDays <= 3) {
        soon++;
      } else {
        fresh++;
      }
    }

    String weekLabel(int w) =>
        w == 3 ? 'Esta' : '${weeks[w].day}/${weeks[w].month}';

    // Comidas en casa por semana y comidas fuera.
    final mealsPerWeek = List<double>.filled(4, 0);
    var mealsOut = 0;
    for (final e in (results[4] as List)) {
      final d = DateTime.tryParse(e['plan_date'] as String? ?? '');
      if (d == null) continue;
      if (e['skipped'] == true) {
        mealsOut++;
        continue;
      }
      final idx = weeks.lastIndexWhere((w) => !d.isBefore(w));
      if (idx >= 0) mealsPerWeek[idx]++;
    }

    // Tareas hechas: por persona este mes y por semana.
    final names = <String, String>{};
    for (final p in (results[6] as List)) {
      final full = (p['full_name'] as String?)?.trim() ?? '';
      names[p['id'] as String] = full.isEmpty ? 'Miembro' : full.split(' ')[0];
    }
    names.addAll(await HomePeople(_client).load(homeId));
    final byPerson = <String, double>{};
    final tasksPerWeek = List<double>.filled(4, 0);
    for (final r in (results[5] as List)) {
      final d = DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal();
      if (d == null) continue;
      if (!d.isBefore(monthStart)) {
        final who = names[r['user_id']] ?? 'Miembro';
        byPerson[who] = (byPerson[who] ?? 0) + 1;
      }
      final idx = weeks.lastIndexWhere((w) => !d.isBefore(w));
      if (idx >= 0) tasksPerWeek[idx]++;
    }

    return _StatsData(
      budget: budget,
      months: months,
      forecast: forecast,
      byCategory: _top(byCategory, 6),
      topProducts: _top(productCount, 7).take(6).toList(),
      pantryByZone: _top(byZone, 7),
      expired: expired,
      expiringSoon: soon,
      fresh: fresh,
      mealsByWeek: [
        for (int w = 0; w < 4; w++) (weekLabel(w), mealsPerWeek[w]),
      ],
      mealsOut: mealsOut,
      tasksByPerson: _top(byPerson, 6),
      tasksByWeek: [
        for (int w = 0; w < 4; w++) (weekLabel(w), tasksPerWeek[w]),
      ],
    );
  }

  Future<void> _scan() async {
    HapticFeedback.selectionClick();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanTicketScreen()));
    if (mounted) _reload();
  }

  Future<void> _openTickets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EconomyScreen(showPoints: false)),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Tus datos')),
      body: FutureBuilder<_StatsData?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(friendlyError(snap.error)));
          }
          final d = snap.data;
          if (d == null) {
            return const Center(child: Text('No perteneces a ningún hogar.'));
          }
          final sections = _sections(d);
          return RefreshIndicator(
            color: AppColors.woodDark,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxxl * 2,
              ),
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) =>
                  StaggeredEntrance(index: i, child: sections[i]),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _sections(_StatsData d) => [
    _spendHero(d),
    _card(
      title: 'Gasto por mes',
      icon: Icons.bar_chart_rounded,
      accent: (AppColors.peachBg, AppColors.woodDark),
      footer: d.spent > 0 ? 'En claro, lo que falta para la previsión' : null,
      child: d.months.every((m) => m.$2 == 0)
          ? _noData('Escanea un ticket y verás tu gasto mes a mes.')
          : _ColumnChart(
              values: d.months,
              color: AppColors.wood,
              euros: true,
              lastGhost: d.forecast,
              guide: d.budget > 0 ? d.budget : null,
            ),
    ),
    _card(
      title: 'En qué gastas este mes',
      icon: Icons.donut_small_outlined,
      accent: (AppColors.peachBg, AppColors.woodDark),
      child: d.byCategory.isEmpty
          ? _noData('Aún no hay tickets este mes.')
          : _BarList(items: d.byCategory, color: AppColors.wood, euros: true),
    ),
    _card(
      title: 'Lo que más compras',
      icon: Icons.shopping_basket_outlined,
      accent: (AppColors.sageBg, AppColors.sage),
      footer: 'Veces en tus tickets de los últimos 3 meses',
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProductStatsScreen())),
      child: d.topProducts.isEmpty
          ? _noData('Saldrá cuando escanees tickets.')
          : _BarList(items: d.topProducts, color: AppColors.sage),
    ),
    _card(
      title: 'Tu despensa',
      icon: Icons.kitchen_outlined,
      accent: (AppColors.frostBg, AppColors.frost),
      child: Column(
        children: [
          _pantryStatus(d),
          if (d.pantryByZone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _BarList(items: d.pantryByZone, color: AppColors.frost),
          ],
        ],
      ),
    ),
    _card(
      title: 'Comidas en casa',
      icon: Icons.restaurant_menu_rounded,
      accent: (AppColors.terracottaBg, AppColors.terracotta),
      footer: d.mealsOut > 0
          ? 'Por semana · ${d.mealsOut} fuera de casa'
          : 'Por semana',
      child: d.mealsByWeek.every((w) => w.$2 == 0)
          ? _noData('Planifica comidas y verás cuántas hacéis en casa.')
          : _ColumnChart(values: d.mealsByWeek, color: AppColors.terracotta),
    ),
    _card(
      title: 'Tareas hechas',
      icon: Icons.check_circle_outline_rounded,
      accent: (AppColors.lilacBg, AppColors.lilac),
      footer: d.tasksByPerson.isEmpty
          ? 'Por semana'
          : 'Por semana y quién ha hecho más este mes',
      child: d.tasksByWeek.every((w) => w.$2 == 0)
          ? _noData('Cuando completéis tareas aparecerán aquí.')
          : Column(
              children: [
                _ColumnChart(values: d.tasksByWeek, color: AppColors.lilac),
                if (d.tasksByPerson.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _BarList(items: d.tasksByPerson, color: AppColors.lilac),
                ],
              ],
            ),
    ),
  ];

  /// Lo primero: cuánto llevas este mes, cuánto vas a gastar y el acceso a
  /// escanear un ticket.
  Widget _spendHero(_StatsData d) {
    final past = d.months.take(5).map((m) => m.$2).where((v) => v > 0);
    final avg = past.isEmpty ? 0.0 : past.reduce((a, b) => a + b) / past.length;
    final diff = avg > 0 ? (d.forecast - avg) / avg * 100 : null;
    final over = d.budget > 0 && d.forecast > d.budget;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppTheme.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Llevas este mes', style: AppTextStyles.labelMuted),
          const SizedBox(height: AppSpacing.xs),
          AnimatedCounter(
            value: d.spent,
            formatter: (v) => '${v.toStringAsFixed(2)} €',
            style: AppTextStyles.display.copyWith(fontSize: 34),
          ),
          if (d.spent > 0 || avg > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: over ? AppColors.expired : AppColors.woodDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Previsión: '),
                        TextSpan(
                          text: '${d.forecast.toStringAsFixed(0)} €',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (diff != null && diff.abs() >= 5)
                          TextSpan(
                            text: diff > 0
                                ? ', un ${diff.round()} % más que tu media'
                                : ', un ${(-diff).round()} % menos que tu media',
                          ),
                      ],
                    ),
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ],
          if (d.budget > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _BudgetBar(spent: d.spent, forecast: d.forecast, budget: d.budget),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _scan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.wood,
                    foregroundColor: AppColors.ink,
                  ),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Escanear ticket'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: _openTickets,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink),
                child: const Text('Tickets'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pantryStatus(_StatsData d) {
    Widget tile(
      String label,
      int n,
      IconData icon,
      Color bg,
      Color fg,
    ) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdRadius),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(height: AppSpacing.xs),
            Text('$n', style: AppTextStyles.headline.copyWith(fontSize: 22)),
            Text(label, style: AppTextStyles.labelMuted),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile(
          'Caducado',
          d.expired,
          Icons.error_outline_rounded,
          AppColors.expiredBg,
          AppColors.expired,
        ),
        const SizedBox(width: AppSpacing.sm),
        tile(
          'Caduca pronto',
          d.expiringSoon,
          Icons.schedule_rounded,
          AppColors.soonBg,
          AppColors.soon,
        ),
        const SizedBox(width: AppSpacing.sm),
        tile(
          'Bien',
          d.fresh,
          Icons.check_rounded,
          AppColors.freshBg,
          AppColors.fresh,
        ),
      ],
    );
  }

  Widget _noData(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(text, style: AppTextStyles.bodyMuted),
  );

  Widget _card({
    required String title,
    required IconData icon,
    required (Color, Color) accent,
    required Widget child,
    String? footer,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.$1,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Icon(icon, size: 20, color: accent.$2),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(title, style: AppTextStyles.title)),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(footer, style: AppTextStyles.labelMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de presupuesto: lo gastado en sólido y lo previsto, más claro.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.spent,
    required this.forecast,
    required this.budget,
  });

  final double spent, forecast, budget;

  @override
  Widget build(BuildContext context) {
    final over = forecast > budget;
    final color = over ? AppColors.expired : AppColors.wood;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: AppColors.line),
                FractionallySizedBox(
                  widthFactor: (forecast / budget).clamp(0.0, 1.0),
                  child: Container(color: color.withValues(alpha: 0.35)),
                ),
                FractionallySizedBox(
                  widthFactor: (spent / budget).clamp(0.0, 1.0),
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          over
              ? 'A este ritmo te pasarás ${(forecast - budget).toStringAsFixed(0)} € del presupuesto'
              : 'Presupuesto: ${budget.toStringAsFixed(0)} €',
          style: AppTextStyles.labelMuted.copyWith(
            color: over ? AppColors.expired : null,
          ),
        ),
      ],
    );
  }
}

/// Columnas de una sola serie con el valor al tocar. [lastGhost] dibuja en
/// claro, detrás de la última columna, hasta dónde se espera que llegue;
/// [guide] es una línea discontinua de referencia (el presupuesto).
class _ColumnChart extends StatelessWidget {
  const _ColumnChart({
    required this.values,
    required this.color,
    this.euros = false,
    this.lastGhost,
    this.guide,
  });

  final List<(String, double)> values;
  final Color color;
  final bool euros;
  final double? lastGhost;
  final double? guide;

  String _fmt(double v) =>
      euros ? '${v.toStringAsFixed(0)} €' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final maxV = [
      ...values.map((v) => v.$2),
      lastGhost ?? 0,
      guide ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    final last = values.length - 1;
    return SizedBox(
      height: 170,
      child: BarChart(
        duration: AppMotion.slow,
        BarChartData(
          maxY: maxV <= 0 ? 1 : maxV * 1.15,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                group.x == last && lastGhost != null
                    ? '${_fmt(rod.toY)}\nPrevisión ${_fmt(lastGhost!)}'
                    : _fmt(rod.toY),
                TextStyle(color: AppColors.cream, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, meta) => v == meta.max
                    ? const SizedBox.shrink()
                    : Text(
                        meta.formattedValue,
                        style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                      ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i > last) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      values[i].$1,
                      style: AppTextStyles.labelMuted.copyWith(
                        fontSize: 12,
                        fontWeight: i == last ? FontWeight.w800 : null,
                        color: i == last ? AppColors.ink : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: guide == null
              ? const ExtraLinesData()
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: guide!,
                      color: AppColors.inkMuted,
                      strokeWidth: 1.5,
                      dashArray: [5, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                        labelResolver: (_) => 'Presupuesto',
                      ),
                    ),
                  ],
                ),
          barGroups: [
            for (int i = 0; i <= last; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].$2,
                    color: color,
                    width: 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: i == last && lastGhost != null
                        ? BackgroundBarChartRodData(
                            show: true,
                            toY: lastGhost!,
                            color: color.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Barras horizontales con su nombre y el valor escrito (no solo color).
class _BarList extends StatelessWidget {
  const _BarList({
    required this.items,
    required this.color,
    this.euros = false,
  });

  final List<(String, double)> items;
  final Color color;
  final bool euros;

  @override
  Widget build(BuildContext context) {
    final maxV = items.fold<double>(0, (a, e) => e.$2 > a ? e.$2 : a);
    return Column(
      children: [
        for (final (label, v) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label,
                      ),
                    ),
                    Text(
                      euros
                          ? '${v.toStringAsFixed(2)} €'
                          : v.toStringAsFixed(0),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: maxV > 0 ? v / maxV : 0),
                  duration: AppMotion.slow,
                  curve: Curves.easeOutCubic,
                  builder: (_, f, _) => ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: Stack(
                      children: [
                        Container(height: 8, color: AppColors.line),
                        FractionallySizedBox(
                          widthFactor: f,
                          child: Container(height: 8, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
