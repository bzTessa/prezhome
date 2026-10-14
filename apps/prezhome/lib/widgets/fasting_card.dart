import 'dart:async';

import 'package:flutter/material.dart';

import '../services/plan_prefs.dart';
import '../theme/app_theme.dart';

/// Tarjeta de Hoy para quien ayuna: si toca ayunar o comer y cuánto queda.
class FastingCard extends StatefulWidget {
  const FastingCard({super.key});

  @override
  State<FastingCard> createState() => _FastingCardState();
}

class _FastingCardState extends State<FastingCard> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final s = PlanPrefs.current.value.fastAt(now);
    if (s == null) return const SizedBox.shrink();
    final left = s.until.difference(now);
    final h = left.inHours;
    final m = left.inMinutes % 60;
    final time = PlanPrefs.formatMinutes(s.until.hour * 60 + s.until.minute);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.tactileDecoration(),
      child: Row(
        children: [
          Icon(
            s.fasting
                ? Icons.hourglass_bottom_rounded
                : Icons.restaurant_rounded,
            color: AppColors.woodDark,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fasting ? 'En ayuno' : 'Puedes comer',
                  style: AppTextStyles.title,
                ),
                Text(
                  s.fasting
                      ? 'Quedan ${h > 0 ? '$h h ' : ''}$m min · Comes a las $time'
                      : 'Hasta las $time',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
