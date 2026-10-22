import 'package:flutter/material.dart';
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
        '¡${s.days} días seguidos!',
        'Hito conseguido. Siguiente: $next días.',
      ),
      _ when s.doneToday => (
        MiauMood.greeting,
        _days(s.days),
        'Hoy ya cuenta. Próximo hito: $next días.',
      ),
      _ when s.days > 0 => (
        MiauMood.curious,
        _days(s.days),
        'Tacha una tarea o apunta una comida para seguir.',
      ),
      _ => (
        MiauMood.sleeping,
        'Empieza tu racha',
        'Tacha una tarea o apunta una comida hoy.',
      ),
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

  static String _days(int n) => n == 1 ? '1 día seguido' : '$n días seguidos';
}
