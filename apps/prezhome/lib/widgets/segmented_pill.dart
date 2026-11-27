import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'animations/spring_value.dart';

/// Selector de vistas en píldora editorial: el indicador elevado se desliza
/// con un muelle (interrumpible) hasta la opción elegida.
class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.iconTile,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardEdge, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              Positioned.fill(
                child: SpringValue(
                  value: selected.toDouble(),
                  spring: AppMotion.fluidBouncy,
                  builder: (context, x, child) => Transform.translate(
                    offset: Offset(x * w, 0),
                    child: child,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: w,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.cardEdge.withValues(alpha: 0.6),
                          width: 0.5,
                        ),
                        boxShadow: AppElevation.level1,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Responde al tocar, sin esperar a levantar el dedo.
                          onTapDown: (_) {
                            if (i == selected) return;
                            HapticFeedback.selectionClick();
                            onChanged(i);
                          },
                          child: Center(
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: i == selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: i == selected
                                    ? AppColors.ink
                                    : AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
