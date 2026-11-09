import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../utils/recipe_browse.dart';
import 'recipe_chip.dart';

String recipeCategoryLabel(BuildContext context, String key) => switch (key) {
  'favorites' => context.l.recFavorites,
  'quick' => context.l.recQuick,
  'light' => context.l.recLight,
  'freezer' => context.l.recFreezer,
  _ => context.l.mealType(key),
};

IconData recipeCategoryIcon(String key) => switch (key) {
  'favorites' => Icons.favorite_rounded,
  'quick' => Icons.bolt_rounded,
  'light' => Icons.eco_rounded,
  'freezer' => Icons.ac_unit_rounded,
  _ => mealTypeIcon(key),
};

/// Categorías del recetario como baldosas de 5 en fila (sin deslizar), con
/// cuántas recetas hay en cada una. Tocar una la elige; otra vez la quita.
class RecipeCategoryChips extends StatelessWidget {
  const RecipeCategoryChips({
    super.key,
    required this.recipes,
    required this.selected,
    required this.onSelected,
  });

  final List<Recipe> recipes;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final counts = recipeCategoryCounts(recipes);
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final width = (c.maxWidth - gap * 4) / 5;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final e in counts.entries)
              SizedBox(
                width: width,
                child: _Tile(
                  icon: recipeCategoryIcon(e.key),
                  label: recipeCategoryLabel(context, e.key),
                  count: e.value,
                  selected: e.key == selected,
                  onTap: () => onSelected(e.key == selected ? null : e.key),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.wood : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.woodDark : AppColors.wood,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.ink : AppColors.woodDark,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
