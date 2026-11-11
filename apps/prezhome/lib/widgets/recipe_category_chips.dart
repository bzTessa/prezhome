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

(Color bg, Color fg) recipeCategoryColors(String key) => switch (key) {
  'favorites' => (AppColors.terracottaBg, AppColors.terracotta),
  'breakfast' || 'quick' => (AppColors.goldBg, AppColors.gold),
  'lunch' || 'light' => (AppColors.sageBg, AppColors.sage),
  'dinner' => (AppColors.lilacBg, AppColors.lilac),
  'dessert' => (AppColors.peachBg, AppColors.peach),
  'snack' => (AppColors.freshBg, AppColors.fresh),
  _ => (AppColors.frostBg, AppColors.frost),
};

/// Orden en pantalla: las 4 primeras con recetas van siempre a la vista;
/// el resto aparece al tocar "Más".
const _displayOrder = [
  'favorites',
  'breakfast',
  'lunch',
  'dinner',
  'quick',
  'light',
  'dessert',
  'snack',
  'drink',
  'freezer',
];

/// Categorías del recetario como círculos de color en una fila, al estilo de
/// las apps de recetas. Tocar una la elige; otra vez la quita.
class RecipeCategoryChips extends StatefulWidget {
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
  State<RecipeCategoryChips> createState() => _RecipeCategoryChipsState();
}

class _RecipeCategoryChipsState extends State<RecipeCategoryChips> {
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    final counts = recipeCategoryCounts(widget.recipes);
    final keys = _displayOrder.where(counts.containsKey).toList();
    final hasMore = keys.length > 5;
    final open = _more || (hasMore && keys.indexOf(widget.selected ?? '') >= 4);
    final shown = !hasMore || open ? keys : keys.take(4).toList();
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 6.0;
        final width = (c.maxWidth - gap * 4) / 5;
        Widget tile(String key) => SizedBox(
          width: width,
          child: _Tile(
            category: key,
            label: recipeCategoryLabel(context, key),
            count: counts[key] ?? 0,
            selected: key == widget.selected,
            onTap: () => widget.onSelected(key == widget.selected ? null : key),
          ),
        );
        return Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (final k in shown) tile(k),
            if (hasMore)
              SizedBox(
                width: width,
                child: _MoreTile(
                  open: open,
                  onTap: () => setState(() => _more = !open),
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
    required this.category,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = recipeCategoryColors(category);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? fg : bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  recipeCategoryIcon(category),
                  size: 24,
                  color: selected ? Colors.white : fg,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = open ? context.l.recLess : context.l.recMore;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(
                  open ? Icons.expand_less_rounded : Icons.more_horiz_rounded,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
