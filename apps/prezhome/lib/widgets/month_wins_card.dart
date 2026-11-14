import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/month_wins.dart';
import '../theme/app_theme.dart';

/// "Tu mes en casa": cuatro cifras de lo que la app ha ayudado este mes.
class MonthWinsCard extends StatelessWidget {
  const MonthWinsCard({super.key, required this.wins});

  final MonthWins wins;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.tactileDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.winsTitle,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (wins.isEmpty)
            Text(l.winsEmpty, style: TextStyle(color: AppColors.inkMuted))
          else ...[
            Row(
              children: [
                _tile(wins.rescued, l.winsRescued, AppColors.fresh),
                const SizedBox(width: 10),
                _tile(wins.thrown, l.winsThrown, AppColors.expired),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _tile(wins.mealsAtHome, l.winsMeals, AppColors.terracotta),
                const SizedBox(width: 10),
                _tile(wins.tasksDone, l.winsTasks, AppColors.lilac),
              ],
            ),
            if (wins.thrownLess > 0) ...[
              const SizedBox(height: 10),
              Text(
                l.winsThrownLess(wins.thrownLess),
                style: TextStyle(
                  color: AppColors.fresh,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _tile(int value, String label, Color color) => Expanded(
    child: Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
