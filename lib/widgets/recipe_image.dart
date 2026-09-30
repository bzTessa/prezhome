import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';

/// Muestra la foto de la receta si existe; si no, un placeholder cozy con un
/// icono según el tipo de plato. Reutilizable en tarjetas y detalle.
class RecipeImage extends StatelessWidget {
  final Recipe recipe;
  final double? width;
  final double height;
  final double radius;

  const RecipeImage({
    super.key,
    required this.recipe,
    this.width,
    this.height = 160,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: recipe.imageUrl != null
            ? Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder(loading: true);
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E6C4), AppColors.wood],
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                IconData(recipe.placeholderIconCode, fontFamily: 'MaterialIcons'),
                size: height * 0.32,
                color: Colors.white.withValues(alpha: 0.9),
              ),
      ),
    );
  }
}
