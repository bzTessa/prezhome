import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/week_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';

/// Tarjeta del domingo y el lunes en Hoy: cómo ha ido la semana en casa.
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({
    super.key,
    required this.summary,
    required this.onDismiss,
  });

  final WeekSummary summary;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = summary;
    final stats = <(String, String)>[
      (l.wsMeals, '${s.mealsAtHome}'),
      if (s.spent > 0) (l.wsSpent, money(s.spent, decimals: 0)),
      (l.wsRescued, '${s.rescued}'),
      (l.wsTasks, '${s.tasksDone}'),
    ];
    final note = s.thrownLess > 0
        ? l.wsThrownLess(s.thrownLess)
        : s.thrown == 0
        ? l.wsNothingThrown
        : l.wsThrown(s.thrown);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 18),
      decoration: AppTheme.surfaceDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.wsTitle, style: AppTextStyles.headline)),
              IconButton(
                tooltip: l.wsClose,
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                for (var i = 0; i < stats.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(label: stats[i].$1, value: stats[i].$2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: i + 1 < stats.length
                            ? _Stat(
                                label: stats[i + 1].$1,
                                value: stats[i + 1].$2,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Icon(
                  s.thrownLess > 0 || s.thrown == 0
                      ? Icons.eco_rounded
                      : Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.sage,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(note, style: AppTextStyles.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.iconTile,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.numeric(
            AppFonts.serif(fontSize: 26, height: 1, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelMuted),
      ],
    ),
  );
}
