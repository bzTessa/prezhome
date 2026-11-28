import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../services/fun_stats.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import 'stat_charts.dart';

/// Las tarjetas de datos curiosos de "Tus datos". Cada método devuelve null
/// cuando aún no hay datos para esa tarjeta, así la pantalla no se llena de
/// huecos vacíos.
class FunSections {
  FunSections(this.context, this.s, {DateTime? now})
    : now = now ?? DateTime.now();

  final BuildContext context;
  final FunStats s;
  final DateTime now;

  AppLocalizations get l => context.l;

  static String _capFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Nombre del día (0 = lunes), con mayúscula.
  static String weekday(int i, {bool short = false}) {
    final d = DateTime(2024, 1, 1 + i); // El 1-1-2024 fue lunes.
    return _capFirst((short ? DateFormat.E() : DateFormat.EEEE()).format(d));
  }

  String _num(double v) => NumberFormat.decimalPattern().format(v.round());

  String _signedKg(double v) {
    final f = NumberFormat('0.0').format(v.abs());
    return '${v > 0 ? '+' : (v < 0 ? '−' : '')}$f kg';
  }

  // ---------------------------------------------------------------- Datos

  /// Los datos curiosos en cuadrícula. Null si no hay ninguno.
  Widget? facts() {
    final tiles = <FactTile>[];
    void add(String v, String c, IconData i, Color bg, Color fg) =>
        tiles.add(FactTile(value: v, caption: c, icon: i, bg: bg, fg: fg));

    if (s.boughtThisMonth.isNotEmpty) {
      final (name, n) = s.boughtThisMonth.first;
      add(
        '${_num(n)} ${name.toLowerCase()}',
        l.fsFactBoughtCaption,
        Icons.shopping_basket_outlined,
        AppColors.sageBg,
        AppColors.sage,
      );
    }
    final store = s.usualStore;
    if (store != null && s.ticketCount >= 3) {
      add(
        store,
        l.fsFactStoreShare(s.topStoreShare),
        Icons.storefront_outlined,
        AppColors.peachBg,
        AppColors.woodDark,
      );
    }
    if (s.ticketCount >= 4) {
      add(
        weekday(s.busiestWeekday),
        l.fsFactShopDay,
        Icons.calendar_today_outlined,
        AppColors.frostBg,
        AppColors.frost,
      );
    }
    final rec = s.record;
    if (rec != null && s.ticketCount >= 2) {
      final date = DateFormat.MMMd().format(rec.day);
      add(
        money(rec.amount, decimals: 0),
        l.fsFactRecord(rec.store == null ? date : '${rec.store}, $date'),
        Icons.receipt_long_outlined,
        AppColors.goldBg,
        AppColors.woodDark,
      );
    }
    if (s.topRecipes.isNotEmpty && s.topRecipes.first.$2 >= 2) {
      final (title, n) = s.topRecipes.first;
      add(
        title,
        l.fsFactTopRecipe(n.round()),
        Icons.restaurant_rounded,
        AppColors.terracottaBg,
        AppColors.terracotta,
      );
    }
    if (s.rescuedThisMonth > 0) {
      add(
        '${s.rescuedThisMonth}',
        l.fsFactRescued,
        Icons.eco_outlined,
        AppColors.freshBg,
        AppColors.fresh,
      );
    }
    if (s.streak >= 2) {
      add(
        l.fsDays(s.streak),
        l.fsFactStreak(s.bestStreak),
        Icons.local_fire_department_outlined,
        AppColors.goldBg,
        AppColors.woodDark,
      );
    }
    if (s.tasksTotal >= 5) {
      final part = s.favouriteDayPart;
      final share = (s.tasksByDayPart[part] / s.tasksTotal * 10).round();
      add(
        l.fsDayPart(const ['morning', 'afternoon', 'night'][part]),
        l.fsFactDayPart(share),
        part == 2 ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined,
        AppColors.lilacBg,
        AppColors.lilac,
      );
    }
    if (s.distinctProducts >= 10) {
      add(
        '${s.distinctProducts}',
        l.fsFactDistinct,
        Icons.category_outlined,
        AppColors.sageBg,
        AppColors.sage,
      );
    }
    final k = s.kcal;
    if (k != null && k.daysLogged >= 3) {
      add(
        _num(k.average),
        l.fsFactKcal,
        Icons.local_dining_outlined,
        AppColors.peachBg,
        AppColors.woodDark,
      );
    }
    if (s.weights.length >= 2) {
      final diff = s.weights.last.$2 - s.weights.first.$2;
      if (diff.abs() >= 0.1) {
        add(
          _signedKg(diff),
          l.fsFactWeight(DateFormat.MMMd().format(s.weights.first.$1)),
          Icons.monitor_weight_outlined,
          AppColors.frostBg,
          AppColors.frost,
        );
      }
    }
    if (tiles.isEmpty) return null;
    // En número par, para que la cuadrícula no deje un hueco al final.
    if (tiles.length.isOdd && tiles.length > 1) tiles.removeLast();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatSectionHeader(l.fsFacts),
        const SizedBox(height: AppSpacing.md),
        FactsGrid(tiles: tiles),
      ],
    );
  }

  // ---------------------------------------------------------------- Dinero

  Widget? byStore() {
    if (s.stores.length < 2) return null;
    return StatCard(
      title: l.fsByStore,
      icon: Icons.storefront_outlined,
      accent: (AppColors.peachBg, AppColors.woodDark),
      footer: l.fsByStoreFooter(money(s.avgTicket), s.ticketCount),
      child: BarList(
        items: [for (final st in s.stores) (st.name, st.total)],
        color: AppColors.wood,
        euros: true,
      ),
    );
  }

  Widget? shopDays() {
    if (s.ticketCount < 4) return null;
    return StatCard(
      title: l.fsShopDays,
      icon: Icons.calendar_view_week_outlined,
      accent: (AppColors.frostBg, AppColors.frost),
      footer: l.fsShopDaysFooter,
      child: ColumnChart(
        values: [
          for (int i = 0; i < 7; i++)
            (weekday(i, short: true), s.ticketsByWeekday[i]),
        ],
        color: AppColors.frost,
        highlight: s.busiestWeekday,
      ),
    );
  }

  Widget? prices() {
    final rows = [...s.priceUps, ...s.priceDowns];
    if (rows.isEmpty) return null;
    return StatCard(
      title: l.fsPrices,
      icon: Icons.trending_up_rounded,
      accent: (AppColors.expiredBg, AppColors.expired),
      footer: l.fsPricesFooter,
      child: Column(
        children: [
          for (final c in rows)
            StatRow(
              title: c.name,
              subtitle: l.fsPriceSince(
                money(c.before),
                money(c.now),
                DateFormat.MMMd().format(c.since),
              ),
              trailing: '${c.pct > 0 ? '+' : '−'}${c.pct.abs().round()} %',
              trailingColor: c.pct > 0 ? AppColors.expired : AppColors.fresh,
            ),
        ],
      ),
    );
  }

  Widget? cheaper() {
    if (s.cheaperAt.isEmpty) return null;
    return StatCard(
      title: l.fsCheaper,
      icon: Icons.savings_outlined,
      accent: (AppColors.freshBg, AppColors.fresh),
      footer: l.fsCheaperFooter,
      child: Column(
        children: [
          for (final c in s.cheaperAt)
            StatRow(
              title: c.name,
              subtitle: l.fsCheaperRow(
                c.cheapStore,
                money(c.cheap),
                c.dearStore,
                money(c.dear),
              ),
              trailing: '−${money(c.saving)}',
              trailingColor: AppColors.fresh,
            ),
        ],
      ),
    );
  }

  Widget? boughtThisMonth() {
    if (s.boughtThisMonth.length < 2) return null;
    return StatCard(
      title: l.fsBoughtMonth,
      icon: Icons.shopping_cart_outlined,
      accent: (AppColors.sageBg, AppColors.sage),
      footer: l.fsBoughtFooter,
      child: BarList(items: s.boughtThisMonth, color: AppColors.sage),
    );
  }

  // ------------------------------------------------------- Cocina y despensa

  Widget topRecipes() => StatCard(
    title: l.fsTopRecipes,
    icon: Icons.restaurant_rounded,
    accent: (AppColors.terracottaBg, AppColors.terracotta),
    footer: s.topRecipes.isEmpty
        ? null
        : l.fsTopRecipesFooter(s.recipesThisMonth, s.recipesLastMonth),
    child: s.topRecipes.isEmpty
        ? Text(l.fsTopRecipesEmpty, style: AppTextStyles.bodyMuted)
        : BarList(items: s.topRecipes, color: AppColors.terracotta),
  );

  Widget? waste() {
    if (s.rescuedTotal + s.thrownTotal == 0) return null;
    final thrown = s.mostThrown
        .map((t) => '${t.$1.toLowerCase()} (${t.$2.round()})')
        .join(', ');
    return StatCard(
      title: l.fsWaste,
      icon: Icons.eco_outlined,
      accent: (AppColors.freshBg, AppColors.fresh),
      footer: thrown.isEmpty ? l.fsWasteFooter : l.fsMostThrown(thrown),
      child: PairedColumns(
        labels: [for (final w in s.waste) DateFormat.MMM().format(w.month)],
        a: [for (final w in s.waste) w.rescued.toDouble()],
        b: [for (final w in s.waste) w.thrown.toDouble()],
        aLabel: l.fsRescued,
        bLabel: l.fsThrown,
        aColor: AppColors.sage,
        bColor: AppColors.terracotta,
      ),
    );
  }

  // ---------------------------------------------------------------- Casa

  Widget? topTasks() {
    if (s.topTasks.length < 2) return null;
    return StatCard(
      title: l.fsTaskTop,
      icon: Icons.repeat_rounded,
      accent: (AppColors.lilacBg, AppColors.lilac),
      footer: l.fsTaskTopFooter,
      child: BarList(items: s.topTasks, color: AppColors.lilac),
    );
  }

  Widget? taskWhen() {
    final total = s.tasksTotal;
    if (total < 5) return null;
    String pct(int i) => '${(s.tasksByDayPart[i] / total * 100).round()} %';
    return StatCard(
      title: l.fsTaskWhen,
      icon: Icons.schedule_rounded,
      accent: (AppColors.lilacBg, AppColors.lilac),
      footer: l.fsTaskWhenFooter(weekday(s.busiestTaskWeekday).toLowerCase()),
      child: Column(
        children: [
          Row(
            children: [
              StatNumber(
                value: pct(0),
                label: l.fsMorning,
                bg: AppColors.goldBg,
              ),
              const SizedBox(width: AppSpacing.sm),
              StatNumber(
                value: pct(1),
                label: l.fsAfternoon,
                bg: AppColors.peachBg,
              ),
              const SizedBox(width: AppSpacing.sm),
              StatNumber(
                value: pct(2),
                label: l.fsNight,
                bg: AppColors.lilacBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ColumnChart(
            values: [
              for (int i = 0; i < 7; i++)
                (weekday(i, short: true), s.tasksByWeekday[i]),
            ],
            color: AppColors.lilac,
            highlight: s.busiestTaskWeekday,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Tú

  Widget activity() => StatCard(
    title: l.fsActivity,
    icon: Icons.local_fire_department_outlined,
    accent: (AppColors.goldBg, AppColors.woodDark),
    footer: l.fsActivityFooter,
    child: Column(
      children: [
        Row(
          children: [
            StatNumber(
              value: l.fsDays(s.streak),
              label: l.fsStreakNow,
              bg: AppColors.goldBg,
            ),
            const SizedBox(width: AppSpacing.sm),
            StatNumber(
              value: l.fsDays(s.bestStreak),
              label: l.fsStreakBest,
              bg: AppColors.peachBg,
            ),
            const SizedBox(width: AppSpacing.sm),
            StatNumber(
              value: '${s.activity.length}',
              label: l.fsDaysActive,
              bg: AppColors.sageBg,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ActivityHeatmap(
          activity: s.activity,
          today: now,
          color: AppColors.terracotta,
        ),
      ],
    ),
  );

  Widget? kcal() {
    final k = s.kcal;
    if (k == null) return null;
    final first = DateTime(now.year, now.month, now.day - 29);
    final macroKcal = k.protein * 4 + k.carbs * 4 + k.fat * 9;
    int share(double g, int per) =>
        macroKcal <= 0 ? 0 : (g * per / macroKcal * 100).round();
    final foods = k.topFoods.map((f) => f.$1.toLowerCase()).join(', ');
    final target = k.target;
    return StatCard(
      title: l.fsKcal,
      icon: Icons.local_dining_outlined,
      accent: (AppColors.peachBg, AppColors.woodDark),
      footer: foods.isEmpty ? l.fsKcalFooter : l.fsTopFoods(foods),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatNumber(
                value: _num(k.average),
                label: l.fsKcalAvg,
                bg: AppColors.peachBg,
              ),
              const SizedBox(width: AppSpacing.sm),
              StatNumber(
                value: '${k.daysLogged}/30',
                label: l.fsKcalLogged,
                bg: AppColors.sageBg,
              ),
              if (target != null && target > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                StatNumber(
                  value: '${k.daysOnTarget}',
                  label: l.fsKcalOnTarget,
                  bg: AppColors.goldBg,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TrendLine(
            points: [
              for (int i = 0; i < 30; i++)
                if (k.byDay[i] > 0) (i.toDouble(), k.byDay[i]),
            ],
            color: AppColors.terracotta,
            format: (v) => '${_num(v)} kcal',
            guide: target != null && target > 0 ? target.toDouble() : null,
            guideLabel: l.fsGoal,
            minX: 0,
            maxX: 29,
            bottomLabels: {
              0: DateFormat.MMMd().format(first),
              29: DateFormat.MMMd().format(now),
            },
          ),
          if (macroKcal > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _MacroBar(
              shares: [share(k.protein, 4), share(k.carbs, 4), share(k.fat, 9)],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.fsMacros(
                share(k.protein, 4),
                share(k.carbs, 4),
                share(k.fat, 9),
              ),
              style: AppTextStyles.labelMuted,
            ),
          ],
        ],
      ),
    );
  }

  Widget? weight() {
    final w = s.weights;
    if (w.length < 2) return null;
    final first = w.first.$1;
    final diff = w.last.$2 - w.first.$2;
    return StatCard(
      title: l.fsWeight,
      icon: Icons.monitor_weight_outlined,
      accent: (AppColors.frostBg, AppColors.frost),
      footer: l.fsWeightChange(
        _signedKg(diff),
        DateFormat.MMMd().format(first),
      ),
      child: TrendLine(
        points: [
          for (final (d, kg) in w) (d.difference(first).inDays.toDouble(), kg),
        ],
        color: AppColors.frost,
        format: (v) => '${NumberFormat('0.0').format(v)} kg',
        bottomLabels: {
          0: DateFormat.MMMd().format(first),
          w.last.$1.difference(first).inDays: DateFormat.MMMd().format(
            w.last.$1,
          ),
        },
      ),
    );
  }
}

/// Reparto de proteína, hidratos y grasa en una barra.
class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.shares});

  final List<int> shares;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.terracotta, AppColors.gold, AppColors.sage];
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.pillRadius,
        child: SizedBox(
          height: 10,
          child: Row(
            children: [
              for (int i = 0; i < 3; i++)
                if (shares[i] > 0)
                  Expanded(
                    flex: shares[i],
                    child: Container(color: colors[i]),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
