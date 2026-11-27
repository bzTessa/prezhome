import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../services/weight_history.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';

/// Tarjeta "Tu peso" del diario: último peso, cuánto ha cambiado en un mes,
/// una línea con los últimos meses y un botón para apuntarlo.
class WeightCard extends StatefulWidget {
  const WeightCard({super.key, this.onSaved});

  /// Tras apuntar: el objetivo de calorías puede cambiar.
  final VoidCallback? onSaved;

  @override
  State<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<WeightCard> {
  late final _history = WeightHistory(Supabase.instance.client);
  List<WeightEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await _history.load();
      if (mounted) setState(() => _entries = e);
    } catch (_) {
      if (mounted) setState(() => _entries = const []);
    }
  }

  String _kg(double v) =>
      NumberFormat('0.0', Localizations.localeOf(context).toString()).format(v);

  Future<void> _add() async {
    final last = _entries?.lastOrNull?.kg;
    final kg = await showDialog<double>(
      context: context,
      builder: (_) => _WeightDialog(initial: last == null ? '' : _kg(last)),
    );
    if (kg == null || !mounted) return;
    try {
      await _history.save(kg);
      HapticFeedback.lightImpact();
      await _load();
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    if (entries == null) return const SizedBox.shrink();
    final last = entries.lastOrNull;
    final change = weightChange(entries);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l.wtTitle, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    if (last == null)
                      Text(context.l.wtEmpty, style: AppTextStyles.bodyMuted)
                    else ...[
                      Text(
                        '${_kg(last.kg)} kg',
                        style: AppTextStyles.numeric(
                          AppFonts.serif(fontSize: 30, color: AppColors.ink),
                        ),
                      ),
                      if (change != null)
                        Text(
                          context.l.wtChange(
                            '${change > 0
                                ? '+'
                                : change < 0
                                ? '−'
                                : ''}'
                            '${_kg(change.abs())}',
                          ),
                          style: AppTextStyles.labelMuted,
                        ),
                    ],
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.monitor_weight_outlined, size: 20),
                label: Text(context.l.wtAdd),
              ),
            ],
          ),
          if (entries.length >= 2) ...[
            const SizedBox(height: 14),
            SizedBox(height: 90, child: _chart(entries)),
          ],
        ],
      ),
    );
  }

  Widget _chart(List<WeightEntry> e) {
    final first = e.first.day;
    final spots = [
      for (final x in e)
        FlSpot(x.day.difference(first).inDays.toDouble(), x.kg),
    ];
    final ys = e.map((x) => x.kg);
    final minY = ys.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = ys.reduce((a, b) => a > b ? a : b) + 1;
    return ExcludeSemantics(
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.terracotta,
              barWidth: 3,
              dotData: FlDotData(show: e.length <= 12),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.terracotta.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightDialog extends StatefulWidget {
  const _WeightDialog({required this.initial});

  final String initial;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 20 || v > 400) {
      setState(() => _error = context.l.wtInvalid);
      return;
    }
    Navigator.of(context).pop(double.parse(v.toStringAsFixed(1)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l.wtDialogTitle),
    content: TextField(
      controller: _ctrl,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onSubmitted: (_) => _save(),
      decoration: InputDecoration(suffixText: 'kg', errorText: _error),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l.cancel),
      ),
      FilledButton(onPressed: _save, child: Text(context.l.save)),
    ],
  );
}
