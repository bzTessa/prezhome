import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';

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
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _placeholder(loading: true);
                  },
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
    // Gradiente cálido crema -> madera para que el placeholder se sienta
    // "cozy" y no un bloque plano. El emoji por tipo de plato da identidad.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cream, Color(0xFFF3E6C4), AppColors.wood],
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.woodDark),
                ),
              )
            : _iconBadge(),
      ),
    );
  }

  Widget _iconBadge() {
    // Tamaño del icono proporcional a la altura, con un círculo crema
    // translúcido detrás para que destaque sobre el gradiente.
    final badgeSize = (height * 0.52).clamp(44.0, 120.0);
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.softShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        iconFor(recipe),
        size: badgeSize * 0.5,
        color: AppColors.woodDark,
      ),
    );
  }
}
