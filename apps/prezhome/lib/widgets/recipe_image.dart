import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';
import 'animations/app_transitions.dart';
import 'dish_illustration.dart';

/// Muestra la foto de la receta si existe; si no, un placeholder cozy con un
/// icono grande según el tipo de plato. Reutilizable en tarjetas y detalle.
class RecipeImage extends StatelessWidget {
  final Recipe recipe;
  final double? width;
  final double height;
  final double radius;

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: _hasPhoto
            ? LayoutBuilder(
                builder: (context, constraints) => Image.network(
                  recipe.imageUrl!,
                  fit: BoxFit.cover,
                  // Acotamos la resolución de decodificado al ancho real que se
                  // va a pintar (en píxeles físicos). Así la foto de Pexels no
                  // se decodifica a resolución completa en una miniatura de la
                  // rejilla, ahorrando memoria y datos en el móvil.
                  cacheWidth: _cacheWidthFor(context, constraints),
                  errorBuilder: (context, error, stack) => _placeholder(),
                  frameBuilder: (context, child, frame, sync) => fadeInPhoto(
                    context: context,
                    image: child,
                    frame: frame,
                    wasSynchronouslyLoaded: sync,
                    placeholder: _placeholder(loading: true),
                  ),
                ),
              )
            : _placeholder(),
      ),
    );
  }

  /// Ancho objetivo de decodificado en píxeles físicos: el ancho pintado por
  /// el devicePixelRatio. Si el ancho es ilimitado (double.infinity), caemos a
  /// un valor razonable para una tarjeta a pantalla completa.
  int? _cacheWidthFor(BuildContext context, BoxConstraints constraints) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : (width ?? 400.0);
    if (logicalWidth <= 0) return null;
    return (logicalWidth * dpr).round();
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
