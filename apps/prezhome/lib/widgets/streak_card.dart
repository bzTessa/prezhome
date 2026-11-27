import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../collection_screen.dart';
import '../l10n/l10n.dart';
import '../services/streak.dart';
import '../theme/app_theme.dart';

/// Tarjeta de la racha de "casa al día".
class StreakCard extends StatefulWidget {
  const StreakCard({super.key, this.loader});

  /// Cargador opcional (útil en tests; por defecto lee Supabase).
  final Future<Streak?> Function()? loader;

  @override
  State<StreakCard> createState() => StreakCardState();
}

class StreakCardState extends State<StreakCard> {
  // Última racha conocida en sesión: al volver a Hoy o recargar el panel,
  // la tarjeta no colapsa a 0 px ni empuja el contenido de debajo.
  static Streak? _cached;

  late Streak? _streak = widget.loader == null ? _cached : null;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Recarga la racha en segundo plano sin ocultar ni mover la tarjeta.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final next =
          await (widget.loader?.call() ??
              Streak.load(Supabase.instance.client));
      if (!mounted || next == null) return;
      if (widget.loader == null) {
        _cached = next;
        unawaited(Streak.rememberBest(next.days));
      }
      if (_streak?.days != next.days || _streak?.doneToday != next.doneToday) {
        setState(() => _streak = next);
      }
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _streak;
    if (s == null) return const SizedBox.shrink();
    return StreakView(
      streak: s,
      onTap: widget.loader != null
          ? null
          : () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CollectionScreen())),
    );
  }
}

/// La tarjeta ya con la racha calculada (separada para poder probarla).
class StreakView extends StatelessWidget {
  const StreakView({super.key, required this.streak, this.onTap});

  final Streak streak;

  /// Abre Mi colección.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = streak;
    final next = Streak.milestones.firstWhere(
      (m) => m > s.days,
      orElse: () => s.days + 100,
    );
    final (title, subtitle) = switch (s) {
      _ when s.milestoneToday => (
        context.l.streakMilestone(s.days),
        context.l.streakMilestoneSub(next),
      ),
      _ when s.doneToday => (
        context.l.streakDays(s.days),
        context.l.streakDoneSub(next),
      ),
      _ when s.days > 0 => (
        context.l.streakDays(s.days),
        context.l.streakKeepSub,
      ),
      _ => (context.l.streakStart, context.l.streakStartSub),
    };
    return Semantics(
      label: '$title. $subtitle',
      button: onTap != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.goldBg, AppColors.card],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: s.doneToday
                      ? AppColors.terracottaBg
                      : AppColors.iconTile,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: s.doneToday
                      ? AppColors.terracotta
                      : AppColors.inkMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.labelMuted),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: AppColors.cardEdge),
                ),
                child: Text(
                  '${s.days}/$next',
                  style: AppTextStyles.numeric(
                    AppTextStyles.label.copyWith(
                      color: AppColors.terracottaText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
