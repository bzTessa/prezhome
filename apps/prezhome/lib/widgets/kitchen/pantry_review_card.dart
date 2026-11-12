import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/inventory_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/shopping_display.dart' show shoppingCleanName;

/// Repaso rápido de lo caducado: un producto cada vez y tres respuestas de
/// un toque (sigue bien, se acabó, a la basura). Así la despensa se pone al
/// día sin abrir producto por producto.
class PantryReviewCard extends StatelessWidget {
  const PantryReviewCard({
    super.key,
    required this.item,
    required this.position,
    required this.total,
    required this.onStillGood,
    required this.onUsedUp,
    required this.onThrown,
  });

  final InventoryItem item;

  /// Posición (desde 1) de [item] dentro del repaso.
  final int position;
  final int total;
  final VoidCallback onStillGood;
  final VoidCallback onUsedUp;
  final VoidCallback onThrown;

  @override
  Widget build(BuildContext context) {
    final onDark = AppColors.cream;
    final days = item.daysUntilExpiry;
    final ago = days == null ? null : -days;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.dark ? AppColors.iconTile : AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg + 6),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l.panReviewTitle(position, total).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.gold,
                  ),
                ),
              ),
              for (var i = 1; i <= total.clamp(1, 6); i++)
                Container(
                  width: 16,
                  height: 5,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: i <= position
                        ? AppColors.gold
                        : onDark.withValues(alpha: 0.2),
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l.panReviewAsk(shoppingCleanName(item.name)),
            style: AppTextStyles.headline.copyWith(
              color: onDark,
              fontSize: 22,
              height: 1.2,
            ),
          ),
          if (ago != null && ago > 0) ...[
            const SizedBox(height: 4),
            Text(
              context.l.panReviewExpiredAgo(ago),
              style: AppTextStyles.body.copyWith(
                color: onDark.withValues(alpha: 0.75),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ReviewButton(
                  label: context.l.panReviewOk,
                  background: onDark,
                  foreground: AppColors.dark ? AppColors.cream : AppColors.ink,
                  onTap: onStillGood,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReviewButton(
                  label: context.l.panReviewUsed,
                  background: onDark.withValues(alpha: 0.12),
                  foreground: onDark,
                  onTap: onUsedUp,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReviewButton(
                  label: context.l.panReviewThrown,
                  background: onDark.withValues(alpha: 0.12),
                  foreground: const Color(0xFFF4A88B),
                  onTap: onThrown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
