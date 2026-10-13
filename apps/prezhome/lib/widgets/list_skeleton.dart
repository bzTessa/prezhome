import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Esqueleto de carga con la forma de una lista (foto + dos líneas), en vez
/// de un círculo girando: la pantalla ya "tiene su forma" mientras llegan los
/// datos. Late suavemente; con "reducir movimiento" queda quieto.
class ListSkeleton extends StatefulWidget {
  const ListSkeleton({super.key, this.rows = 7, this.leading = true});

  final int rows;

  /// Mostrar el hueco de la foto/icono a la izquierda.
  final bool leading;

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotionOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block(double w, double h, {double radius = 8}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AppColors.line,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: FadeTransition(
        opacity: Tween(
          begin: 0.55,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: widget.rows,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                if (widget.leading) ...[
                  _block(44, 44, radius: AppRadius.sm),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(i.isEven ? 160 : 120, 12),
                      const SizedBox(height: AppSpacing.sm),
                      _block(80, 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
