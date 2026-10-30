import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'skeleton.dart';

/// Esqueleto de carga genérico con forma de lista (foto + dos líneas), para
/// las pantallas secundarias. Las principales tienen el suyo en
/// skeleton.dart, con la forma exacta de su contenido.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.rows = 7,
    this.leading = true,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final int rows;
  final EdgeInsetsGeometry padding;

  /// Mostrar el hueco de la foto/icono a la izquierda.
  final bool leading;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        // shrinkWrap: también cabe dentro de otra lista.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: rows,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => BoneCard(
          radius: AppRadius.md,
          child: Row(
            children: [
              if (leading) ...[
                const Bone(width: 44, height: 44, radius: AppRadius.sm),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(width: i.isEven ? 160 : 120, height: 12),
                    const SizedBox(height: AppSpacing.sm),
                    const Bone(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
