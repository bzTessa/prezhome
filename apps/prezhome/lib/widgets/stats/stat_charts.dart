import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';

/// Columnas de una sola serie con el valor al tocar. [lastGhost] dibuja en
/// claro, detrás de la última columna, hasta dónde se espera que llegue;
/// [guide] es una línea discontinua de referencia (el presupuesto).
class ColumnChart extends StatelessWidget {
  const ColumnChart({
    super.key,
    required this.values,
    required this.color,
    this.euros = false,
    this.lastGhost,
    this.guide,
    this.highlight,
  });

  final List<(String, double)> values;

  /// Columna cuyo nombre va resaltado (por defecto, la última).
  final int? highlight;
  final Color color;
  final bool euros;
  final double? lastGhost;
  final double? guide;

  String _fmt(double v) => euros ? money(v, decimals: 0) : v.toStringAsFixed(0);

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
        duration: AppMotion.effectiveDuration(
          AppMotion.slow,
          reduceMotion: AppMotion.reduceMotionOf(context),
        ),
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
                    ? '${_fmt(rod.toY)}\n${context.l.stForecastTip(_fmt(lastGhost!))}'
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
                        fontWeight: i == (highlight ?? last)
                            ? FontWeight.w800
                            : null,
                        color: i == (highlight ?? last) ? AppColors.ink : null,
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
                        labelResolver: (_) => context.l.ecoBudgetShort,
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
class BarList extends StatelessWidget {
  const BarList({
    super.key,
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
                      euros ? money(v) : v.toStringAsFixed(0),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: maxV > 0 ? v / maxV : 0),
                  duration: AppMotion.effectiveDuration(
                    AppMotion.slow,
                    reduceMotion: AppMotion.reduceMotionOf(context),
                  ),
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

/// Dos columnas por grupo (p. ej. aprovechado y tirado cada mes), con su
/// leyenda escrita debajo.
class PairedColumns extends StatelessWidget {
  const PairedColumns({
    super.key,
    required this.labels,
    required this.a,
    required this.b,
    required this.aLabel,
    required this.bLabel,
    required this.aColor,
    required this.bColor,
  });

  final List<String> labels;
  final List<double> a, b;
  final String aLabel, bLabel;
  final Color aColor, bColor;

  @override
  Widget build(BuildContext context) {
    final maxV = [...a, ...b, 1.0].reduce((x, y) => x > y ? x : y);
    final last = labels.length - 1;
    Widget legend(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(t, style: AppTextStyles.labelMuted),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: BarChart(
            duration: AppMotion.effectiveDuration(
              AppMotion.slow,
              reduceMotion: AppMotion.reduceMotionOf(context),
            ),
            BarChartData(
              maxY: maxV * 1.2,
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
                  getTooltipItem: (group, _, rod, i) => BarTooltipItem(
                    '${i == 0 ? aLabel : bLabel}: ${rod.toY.toStringAsFixed(0)}',
                    TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
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
                          labels[i],
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
              barGroups: [
                for (int i = 0; i <= last; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      for (final (v, c) in [(a[i], aColor), (b[i], bColor)])
                        BarChartRodData(
                          toY: v,
                          color: c,
                          width: 11,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.lg,
          children: [legend(aColor, aLabel), legend(bColor, bLabel)],
        ),
      ],
    );
  }
}

/// Línea de una serie por días (calorías, peso) con una referencia
/// discontinua opcional ([guide], p. ej. el objetivo). Los huecos (null) no se
/// dibujan.
class TrendLine extends StatelessWidget {
  const TrendLine({
    super.key,
    required this.points,
    required this.color,
    required this.format,
    this.guide,
    this.guideLabel,
    this.bottomLabels = const {},
    this.minX,
    this.maxX,
  });

  /// Eje x fijo (p. ej. 0 a 29 para 30 días); si no, el de los puntos.
  final double? minX, maxX;

  /// (x, y): x en días desde el primero.
  final List<(double, double)> points;
  final Color color;
  final String Function(double) format;
  final double? guide;
  final String? guideLabel;

  /// Etiquetas del eje x por posición.
  final Map<int, String> bottomLabels;

  @override
  Widget build(BuildContext context) {
    final ys = [for (final p in points) p.$2, ?guide];
    var lo = ys.reduce((a, b) => a < b ? a : b);
    var hi = ys.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo).abs() < 1 ? 1.0 : (hi - lo) * 0.15;
    lo -= pad;
    hi += pad;
    final hiX = maxX ?? (points.isEmpty ? 1.0 : points.last.$1);
    return SizedBox(
      height: 160,
      child: LineChart(
        duration: AppMotion.effectiveDuration(
          AppMotion.slow,
          reduceMotion: AppMotion.reduceMotionOf(context),
        ),
        LineChartData(
          minY: lo < 0 ? 0 : lo,
          maxY: hi,
          minX: minX ?? (points.isEmpty ? 0 : points.first.$1),
          maxX: hiX <= 0 ? 1 : hiX,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    format(s.y),
                    TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => v == meta.max || v == meta.min
                    ? const SizedBox.shrink()
                    : Text(
                        meta.formattedValue,
                        style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                      ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: bottomLabels.isNotEmpty,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final t = v == v.roundToDouble()
                      ? bottomLabels[v.toInt()]
                      : null;
                  if (t == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      t,
                      style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
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
                        show: guideLabel != null,
                        alignment: Alignment.topLeft,
                        style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                        labelResolver: (_) => guideLabel ?? '',
                      ),
                    ),
                  ],
                ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (final p in points) FlSpot(p.$1, p.$2)],
              isCurved: true,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: points.length <= 12),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendario de actividad: una columna por semana (la actual a la derecha),
/// lunes arriba. Más intenso cuantas más cosas hechas ese día.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.activity,
    required this.today,
    required this.color,
    this.weeks = 12,
  });

  final Map<DateTime, int> activity;
  final DateTime today;
  final Color color;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final t = DateTime(today.year, today.month, today.day);
    final monday = t.subtract(Duration(days: t.weekday - 1));
    final start = monday.subtract(Duration(days: 7 * (weeks - 1)));
    final maxV = activity.values.fold<int>(1, (a, b) => b > a ? b : a);
    final days = activity.values.where((v) => v > 0).length;
    return Semantics(
      label: context.l.fsActivityA11y(days, weeks),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, c) {
            const gap = 4.0;
            final cell = ((c.maxWidth - gap * (weeks - 1)) / weeks).clamp(
              8.0,
              22.0,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int w = 0; w < weeks; w++)
                  Column(
                    children: [
                      for (int d = 0; d < 7; d++)
                        Builder(
                          builder: (_) {
                            final day = DateTime(
                              start.year,
                              start.month,
                              start.day + w * 7 + d,
                            );
                            final n = activity[day] ?? 0;
                            final future = day.isAfter(t);
                            return Container(
                              width: cell,
                              height: cell,
                              margin: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
                              decoration: BoxDecoration(
                                color: future
                                    ? Colors.transparent
                                    : n == 0
                                    ? AppColors.line
                                    : color.withValues(
                                        alpha: 0.35 + 0.65 * (n / maxV),
                                      ),
                                borderRadius: BorderRadius.circular(4),
                                border: day == t
                                    ? Border.all(
                                        color: AppColors.ink,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Un dato curioso: cifra grande en serif y una línea que lo explica.
class FactTile extends StatelessWidget {
  const FactTile({
    super.key,
    required this.value,
    required this.caption,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String value, caption;
  final IconData icon;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value. $caption',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.lgRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 22,
                  height: 1.15,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Datos curiosos en dos columnas (sin carrusel).
class FactsGrid extends StatelessWidget {
  const FactsGrid({super.key, required this.tiles});

  final List<FactTile> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: i + 1 < tiles.length
                    ? tiles[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: AppSpacing.sm));
    }
    return Column(children: rows);
  }
}

/// Fila de texto con un valor a la derecha (precios, ahorro...).
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.trailingColor,
  });

  final String title, subtitle, trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label,
                ),
                Text(subtitle, style: AppTextStyles.labelMuted),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w800,
              color: trailingColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una estadística: icono en su color, título y, debajo, el
/// gráfico y una nota opcional.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.footer,
    this.onTap,
  });

  final String title;
  final IconData icon;

  /// (fondo, color) del icono.
  final (Color, Color) accent;
  final Widget child;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                Text(footer!, style: AppTextStyles.labelMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Título de un bloque de estadísticas, en serif, con una nota opcional.
class StatSectionHeader extends StatelessWidget {
  const StatSectionHeader(this.title, {super.key, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Semantics(
        header: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title, style: AppTextStyles.headline.copyWith(fontSize: 24)),
            if (note != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  note!,
                  style: AppTextStyles.labelMuted,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cifra pequeña con su etiqueta (para filas de 3: racha, media...).
class StatNumber extends StatelessWidget {
  const StatNumber({
    super.key,
    required this.value,
    required this.label,
    required this.bg,
  });

  final String value, label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdRadius),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.headline.copyWith(fontSize: 20),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.labelMuted,
            ),
          ],
        ),
      ),
    );
  }
}
