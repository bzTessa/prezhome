import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'services/streak.dart';
import 'theme/app_theme.dart';

/// Mi colección: una ilustración por cada hito de la racha (3, 7, 14, 30 y
/// 100 días). Las que aún no se han ganado salen en gris con lo que falta.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, this.best});

  /// Mejor racha (tests). Si es null, se lee del móvil.
  final int? best;

  static const pieces = <(int, String)>[
    (3, 'assets/images/miau_saludando.png'),
    (7, 'assets/images/miau_cocinando.png'),
    (14, 'assets/images/miau_comprando.png'),
    (30, 'assets/images/miau_celebrando.png'),
    (100, 'assets/images/miau_durmiendo.png'),
  ];

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late int? _best = widget.best;

  @override
  void initState() {
    super.initState();
    if (_best == null) {
      Streak.best().then((b) {
        if (mounted) setState(() => _best = b);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final best = _best ?? 0;
    final won = CollectionScreen.pieces.where((p) => best >= p.$1).length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(context.l.colTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          Text(
            context.l.colIntro(won, CollectionScreen.pieces.length),
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < CollectionScreen.pieces.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _piece(CollectionScreen.pieces[i], best)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < CollectionScreen.pieces.length
                        ? _piece(CollectionScreen.pieces[i + 1], best)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _piece((int, String) p, int best) {
    final (days, asset) = p;
    final won = best >= days;
    Widget img = Image.asset(asset, height: 120, fit: BoxFit.contain);
    if (!won) {
      img = Opacity(
        opacity: 0.35,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0, 0, 0, 1, 0, //
          ]),
          child: img,
        ),
      );
    }
    return Semantics(
      label: won
          ? context.l.colWon(days)
          : context.l.colLocked(days, days - best),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: won ? AppColors.card : AppColors.iconTile,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                img,
                if (!won)
                  Icon(Icons.lock_rounded, size: 28, color: AppColors.inkMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.l.colDays(days),
              textAlign: TextAlign.center,
              style: AppFonts.serif(fontSize: 20, color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            Text(
              won ? context.l.colWonShort : context.l.colMissing(days - best),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMuted,
            ),
          ],
        ),
      ),
    );
  }
}
