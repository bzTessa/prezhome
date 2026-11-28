import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/inventory_item.dart';
import '../../models/ready_meal.dart';
import '../../models/recipe.dart';
import '../../services/not_cooking.dart';
import '../../theme/app_theme.dart';
import '../food_image.dart';
import '../recipe_image.dart';

/// Lo elegido en "Hoy no me apetece cocinar".
class NotCookingChoice {
  const NotCookingChoice({
    this.dish,
    this.ready,
    this.recipe,
    this.out = false,
  });
  final InventoryItem? dish;
  final ReadyMeal? ready;
  final Recipe? recipe;
  final bool out;
}

/// Hoja con lo que hay listo: tápers, preparados del súper y algo rápido.
/// Devuelve lo elegido, o null si se cierra.
Future<NotCookingChoice?> showNotCookingSheet(
  BuildContext context,
  Future<NotCookingOptions> options,
) {
  return showModalBottomSheet<NotCookingChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => FutureBuilder<NotCookingOptions>(
        future: options,
        builder: (ctx, snap) {
          final o = snap.data;
          final l = ctx.l;
          Widget section(String title) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.inkMuted,
              ),
            ),
          );
          Widget tile({
            required Widget leading,
            required String title,
            String? subtitle,
            required NotCookingChoice choice,
          }) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 48, height: 48, child: leading),
            ),
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: subtitle == null
                ? null
                : Text(subtitle, style: AppTextStyles.labelMuted),
            onTap: () => Navigator.of(ctx).pop(choice),
          );
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(l.ncTitle, style: AppTextStyles.headline),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(l.ncBody, style: AppTextStyles.bodyMuted),
              ),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (o != null && o.dishes.isNotEmpty) ...[
                  section(l.ncDishes),
                  for (final d in o.dishes)
                    tile(
                      leading: FoodImage(
                        name: d.name,
                        imageUrl: d.imageUrl,
                        size: 48,
                        radius: 12,
                      ),
                      title: d.name,
                      subtitle: d.category == 'Congelador'
                          ? l.ncFrozen
                          : l.ncFridge,
                      choice: NotCookingChoice(dish: d),
                    ),
                ],
                if (o != null && o.ready.isNotEmpty) ...[
                  section(l.ncReady),
                  for (final r in o.ready)
                    tile(
                      leading: FoodImage(
                        name: r.meal.name,
                        imageUrl: r.meal.imageUrl,
                        size: 48,
                        radius: 12,
                      ),
                      title: r.meal.name,
                      subtitle: r.atHome ? l.ncAtHome : l.ncNotAtHome,
                      choice: NotCookingChoice(ready: r.meal),
                    ),
                ],
                if (o != null && o.quick.isNotEmpty) ...[
                  section(l.ncQuick),
                  for (final r in o.quick)
                    tile(
                      leading: RecipeImage(
                        recipe: r,
                        width: 48,
                        height: 48,
                        radius: 12,
                      ),
                      title: r.title,
                      subtitle: !r.needsCooking
                          ? l.kindNoCook
                          : l.warmMinutes(r.totalTimeMinutes ?? 0),
                      choice: NotCookingChoice(recipe: r),
                    ),
                ],
                if (o == null || o.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Text(l.ncNothing, style: AppTextStyles.bodyMuted),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      ctx,
                    ).pop(const NotCookingChoice(out: true)),
                    icon: const Icon(Icons.restaurant_rounded),
                    label: Text(l.ncOut),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
