import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';
import 'animations/app_transitions.dart';
import 'dish_illustration.dart';

/// Muestra la foto de la receta si existe; si no, un placeholder cozy con un
/// icono grande según el tipo de plato. Reutilizable en tarjetas y detalle.
class RecipeImage extends StatelessWidget {
  /// Ancho fijo de decodificado para miniaturas (evita recalcular en vuelos Hero).
  static const int thumbCacheWidth = 240;

  /// Ancho fijo de decodificado para tarjetas de la cuadrícula de recetas.
  static const int gridCacheWidth = 480;

  /// Ancho fijo de decodificado para cabeceras y tarjetas grandes.
  static const int fullCacheWidth = 960;

  final Recipe recipe;
  final double? width;
  final double height;
  final double radius;

  /// Ancho de decodificado explícito (si se omite, se elige según [width]).
  final int? cacheWidth;

  /// Ancho de caché ya decodificado que se usa como placeholder inmediato
  /// mientras carga la versión a mayor resolución (p. ej. [gridCacheWidth]).
  final int? placeholderCacheWidth;

  /// Si es true, ignora [recipe.imageUrl] y pinta SIEMPRE el placeholder cozy.
  /// Mismo patrón que [FoodImage.forceIllustration]: útil cuando se quiere la
  /// ilustración coherente en vez de una foto que pueda salir poco relevante.
  final bool forceIllustration;

  const RecipeImage({
    super.key,
    required this.recipe,
    this.width,
    this.height = 160,
    this.radius = 20,
    this.cacheWidth,
    this.placeholderCacheWidth,
    this.forceIllustration = false,
  });

  bool get _hasPhoto => !forceIllustration && recipe.imageUrl != null;

  /// Icono representativo del tipo de plato para el placeholder. Prioriza el
  /// tipo más "identificable" (desayuno/postre/snack) y cae a un plato
  /// genérico.
  static IconData iconFor(Recipe recipe) {
    final types = recipe.mealTypes;
    if (types.contains('breakfast')) return Icons.free_breakfast_outlined;
    if (types.contains('dessert')) return Icons.cake_outlined;
    if (types.contains('drink')) return Icons.local_drink_outlined;
    if (types.contains('snack')) return Icons.cookie_outlined;
    if (types.contains('dinner')) return Icons.dinner_dining_outlined;
    return Icons.restaurant_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final targetCacheWidth =
        cacheWidth ??
        ((width != null && width! <= 140) ? thumbCacheWidth : fullCacheWidth);
    final Widget placeholderWidget =
        (placeholderCacheWidth != null &&
            placeholderCacheWidth != targetCacheWidth &&
            _hasPhoto)
        ? Image.network(
            recipe.imageUrl!,
            fit: BoxFit.cover,
            cacheWidth: placeholderCacheWidth,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => _placeholder(),
            frameBuilder: (context, child, frame, sync) =>
                (sync || frame != null) ? child : _placeholder(loading: true),
          )
        : _placeholder(loading: true);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: _hasPhoto
            ? Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
                // Bucket fijo de decodificado para no invalidar la caché en
                // animaciones Hero o cambios de tamaño.
                cacheWidth: targetCacheWidth,
                gaplessPlayback: true,
                errorBuilder: (context, error, stack) => _placeholder(),
                frameBuilder: (context, child, frame, sync) => fadeInPhoto(
                  context: context,
                  image: child,
                  frame: frame,
                  wasSynchronouslyLoaded: sync,
                  placeholder: placeholderWidget,
                ),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    // Sin foto: un plato dibujado según el tipo de receta. Mientras carga
    // la foto, el mismo fondo con un indicador encima.
    return Stack(
      fit: StackFit.expand,
      children: [
        DishIllustration(title: recipe.title, mealTypes: recipe.mealTypes),
        if (loading)
          Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.woodDark),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shuttle para transiciones [Hero] entre tarjeta de receta y detalle:
/// interpola el radio de esquina usando la foto ya cacheada para evitar
/// parpadeos y recargas durante el vuelo.
HeroFlightShuttleBuilder recipeHeroFlightShuttle(
  Recipe recipe, {
  double startRadius = 14,
  double endRadius = 0,
  int cacheWidth = RecipeImage.thumbCacheWidth,
}) {
  final radiusTween = BorderRadiusTween(
    begin: BorderRadius.circular(startRadius),
    end: BorderRadius.circular(endRadius),
  );
  return (
    flightContext,
    animation,
    flightDirection,
    fromHeroContext,
    toHeroContext,
  ) {
    final url = recipe.imageUrl;
    final content = url != null
        ? Image.network(
            url,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => DishIllustration(
              title: recipe.title,
              mealTypes: recipe.mealTypes,
            ),
          )
        : DishIllustration(title: recipe.title, mealTypes: recipe.mealTypes);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => ClipRRect(
        borderRadius: radiusTween.evaluate(animation) ?? BorderRadius.zero,
        child: child,
      ),
      child: content,
    );
  };
}
