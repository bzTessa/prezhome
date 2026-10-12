import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estilo (par fondo + color) de los chips informativos de receta, para dar
/// jerarquía visual. Compartido entre la lista (rejilla) y el detalle para que
/// ambos luzcan igual, sin duplicar el widget.
enum RecipeChipStyle { type, time, calories, freezer, favorite }

/// Chip "pastel" con icono + texto usado tanto en las tarjetas de la rejilla de
/// recetas como en la cabecera del detalle. Cada [RecipeChipStyle] fija un par
/// de colores de la paleta cozy (fondo suave + color de texto/icono).
class RecipeChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final RecipeChipStyle style;

  const RecipeChip({
    super.key,
    required this.text,
    this.icon,
    this.style = RecipeChipStyle.type,
  });

  (Color, Color) get _colors {
    switch (style) {
      case RecipeChipStyle.type:
        return (AppColors.peachBg, AppColors.peach);
      case RecipeChipStyle.time:
        return (AppColors.sageBg, AppColors.sage);
      case RecipeChipStyle.calories:
        return (AppColors.terracottaBg, AppColors.terracotta);
      case RecipeChipStyle.freezer:
        return (AppColors.frostBg, AppColors.frost);
      case RecipeChipStyle.favorite:
        return (AppColors.peachBg, AppColors.favorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono representativo de cada tipo de comida para los chips de receta.
/// Compartido por la lista y el detalle.
IconData mealTypeIcon(String type) {
  switch (type) {
    case 'breakfast':
      return Icons.free_breakfast;
    case 'lunch':
      return Icons.lunch_dining;
    case 'dinner':
      return Icons.dinner_dining;
    case 'snack':
      return Icons.fastfood;
    case 'dessert':
      return Icons.cake;
    default:
      return Icons.restaurant;
  }
}
