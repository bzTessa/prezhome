import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../dish_illustration.dart';
import '../recipe_image.dart';

/// Hoy en el estilo "Cocina cálida": la comida que toca en grande, en
/// terracota, con el plato a la derecha y un botón para ponerse a cocinar.
class WarmMealHero extends StatelessWidget {
  const WarmMealHero({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.mealType,
    required this.actionLabel,
    required this.onOpen,
    this.recipe,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String mealType;
  final String actionLabel;
  final VoidCallback onOpen;
  final Recipe? recipe;

  static const _plate = 184.0;

  @override
  Widget build(BuildContext context) {
    final onT = AppColors.onTerracotta;
    final r = recipe;
    return Material(
      color: AppColors.terracotta,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: LayoutBuilder(
          builder: (context, c) {
            // El texto no se mete debajo del plato.
            final textW = (c.maxWidth - _plate * 0.78 - 34).clamp(140.0, 260.0);
            return SizedBox(
              height: 256,
              child: Stack(
                children: [
                  Positioned(
                    right: -_plate * 0.22,
                    top: 40,
                    child: ExcludeSemantics(
                      child: Container(
                        width: _plate,
                        height: _plate,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dark
                              ? AppColors.card
                              : const Color(0xFFF7EBD9),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: r != null
                              ? RecipeImage(
                                  recipe: r,
                                  width: _plate - 24,
                                  height: _plate - 24,
                                  radius: 0,
                                )
                              : DishIllustration(
                                  title: title,
                                  mealTypes: [mealType],
                                ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: onT,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: textW,
                          child: Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.serif(
                              fontSize: 31,
                              height: 1.05,
                              color: onT,
                            ),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: textW,
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: onT.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        FilledButton(
                          onPressed: onOpen,
                          style: FilledButton.styleFrom(
                            backgroundColor: onT,
                            foregroundColor: const Color(0xFF241C15),
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                          ),
                          child: Text(actionLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum WarmTileTone { plain, terracotta, sage }

class WarmTileData {
  const WarmTileData({
    required this.label,
    required this.value,
    required this.tone,
    this.sub,
    this.onTap,
    this.number = true,
  });

  final String label;
  final String value;
  final String? sub;
  final WarmTileTone tone;
  final VoidCallback? onTap;

  /// Cifra grande en serifa; si no, texto normal en negrita.
  final bool number;
}

/// Fichas de dos en dos; si sobra una, ocupa todo el ancho.
class WarmTiles extends StatelessWidget {
  const WarmTiles({super.key, required this.tiles});

  final List<WarmTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Tile(tiles[i])),
                if (i + 1 < tiles.length) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _Tile(tiles[i + 1])),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.d);

  final WarmTileData d;

  @override
  Widget build(BuildContext context) {
    final dk = AppColors.dark;
    final (Color bg, Color fg) = switch (d.tone) {
      WarmTileTone.plain => (AppColors.card, AppColors.inkMuted),
      WarmTileTone.terracotta => (
        AppColors.terracottaBg,
        dk ? AppColors.terracottaText : const Color(0xFF6E2A12),
      ),
      WarmTileTone.sage => (
        AppColors.sageBg,
        dk ? AppColors.sage : const Color(0xFF2F4D31),
      ),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: d.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.label, style: TextStyle(fontSize: 13, color: fg)),
              const SizedBox(height: 6),
              Text(
                d.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: d.number
                    ? AppTextStyles.numeric(
                        AppFonts.serif(
                          fontSize: 32,
                          height: 1,
                          color: AppColors.ink,
                        ),
                      )
                    : AppTextStyles.title.copyWith(height: 1.25),
              ),
              if (d.sub != null && d.sub!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  d.sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
