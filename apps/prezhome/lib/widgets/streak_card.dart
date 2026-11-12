import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/streak.dart';
import '../theme/app_theme.dart';
import 'miau_character.dart';

/// Tarjeta de la racha de "casa al día" con la mascota según cómo vas.
class StreakCard extends StatefulWidget {
  const StreakCard({super.key});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  late final Future<Streak?> _future = Streak.load(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Streak?>(
      future: _future,
      builder: (context, snap) {
        final s = snap.data;
        if (s == null) return const SizedBox.shrink();
        return StreakView(streak: s);
      },
    );
  }
}

/// La tarjeta ya con la racha calculada (separada para poder probarla).
class StreakView extends StatelessWidget {
  const StreakView({super.key, required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final s = streak;
    final next = Streak.milestones.firstWhere(
      (m) => m > s.days,
      orElse: () => s.days + 100,
    );
    final (mood, title, subtitle) = switch (s) {
      _ when s.milestoneToday => (
        MiauMood.celebrating,
        context.l.streakMilestone(s.days),
        context.l.streakMilestoneSub(next),
      ),
      _ when s.doneToday => (
        MiauMood.greeting,
        context.l.streakDays(s.days),
        context.l.streakDoneSub(next),
      ),
      _ when s.days > 0 => (
        MiauMood.curious,
        context.l.streakDays(s.days),
        context.l.streakKeepSub,
      ),
      _ => (MiauMood.sleeping, context.l.streakStart, context.l.streakStartSub),
    };
    return Semantics(
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            MiauCharacter(mood: mood, size: 64, float: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: AppColors.inkMuted)),
                ],
              ),
            ),
            Icon(
              Icons.local_fire_department_rounded,
              color: s.doneToday ? AppColors.terracotta : AppColors.line,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
