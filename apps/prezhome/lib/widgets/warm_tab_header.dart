import 'package:flutter/material.dart';

import '../global_search_screen.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Cabecera de pestaña del estilo «Cocina cálida»: título grande en serif y
/// la lupa del buscador global, como en Hoy. En el estilo clásico no se pinta.
class WarmTabHeader extends StatelessWidget {
  const WarmTabHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (!AppColors.warmLight) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.display.copyWith(height: 1.1),
              ),
            ),
          ),
          Tooltip(
            message: context.l.gsTitle,
            child: Material(
              color: AppColors.card,
              shape: CircleBorder(side: BorderSide(color: AppColors.cardEdge)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                ),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(Icons.search_rounded, color: AppColors.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
