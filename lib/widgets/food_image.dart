import 'package:flutter/material.dart';

import 'food_category_icon.dart';

/// Combo visual de un alimento: FOTO REAL si hay URL, o una ILUSTRACIÓN COZY
/// vectorial de categoría como respaldo. NUNCA renderiza un emoji del sistema.
///
/// Es el equivalente de [RecipeImage] para los productos del inventario y la
/// lista de la compra. Se usa tanto como miniatura cuadrada (leading de una
/// tarjeta) como en tamaños mayores:
///   - Si [imageUrl] no es null ni vacío -> [Image.network] recortado con
///     esquinas redondeadas, con `cacheWidth` acotado al ancho real pintado
///     (igual que [RecipeImage]) para no decodificar la foto a resolución
///     completa en una miniatura. El [loadingBuilder] muestra un spinner suave
///     sobre la ilustración cozy y el [errorBuilder] cae a la ilustración.
///   - Si no hay URL -> ilustración cozy: un contenedor con el color de fondo
///     cálido de la categoría y su icono vectorial Material centrado, ambos de
///     [CategoryIcons].
///
/// Degrada con elegancia: sin clave de Unsplash (o sin foto cacheada) todos los
/// items se ven con su ilustración cozy y nada se rompe.
class FoodImage extends StatelessWidget {
  /// Nombre del producto (base para inferir la categoría de la ilustración).
  final String name;

  /// Tipo de item ('comida' | 'hogar'), usado como pista para la categoría
  /// cuando el nombre no da match claro.
  final String? itemType;

  /// URL http(s) de la foto real; null o vacío => ilustración cozy.
  final String? imageUrl;

  /// Lado del cuadrado cuando se usa como miniatura. Si se dan [width]/[height]
  /// explícitos, estos tienen prioridad.
  final double size;

  /// Ancho/alto explícitos (opcionales). Si se omiten, se usa [size] en ambos.
  final double? width;
  final double? height;

  /// Radio de las esquinas redondeadas.
  final double radius;

  const FoodImage({
    super.key,
    required this.name,
    this.itemType,
    this.imageUrl,
    this.size = 48,
    this.width,
    this.height,
    this.radius = 14,
  });

  bool get _hasPhoto => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: w,
        height: h,
        child: _hasPhoto
            ? LayoutBuilder(
                builder: (context, constraints) => Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  // Acotamos la resolución de decodificado al ancho real que se
                  // va a pintar (en píxeles físicos), igual que RecipeImage.
                  cacheWidth: _cacheWidthFor(context, constraints, w),
                  errorBuilder: (context, error, stack) => _cozyIllustration(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _cozyIllustration(loading: true);
                  },
                ),
              )
            : _cozyIllustration(),
      ),
    );
  }

  /// Ancho objetivo de decodificado en píxeles físicos: el ancho pintado por el
  /// devicePixelRatio. Si el ancho es ilimitado, caemos a [fallbackWidth].
  int? _cacheWidthFor(
    BuildContext context,
    BoxConstraints constraints,
    double fallbackWidth,
  ) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : (fallbackWidth.isFinite ? fallbackWidth : 400.0);
    if (logicalWidth <= 0) return null;
    return (logicalWidth * dpr).round();
  }

  /// Ilustración cozy de respaldo: fondo cálido de la categoría + icono
  /// vectorial Material centrado. Durante la carga de la foto se superpone un
  /// spinner suave sobre esta misma ilustración para que no haya saltos.
  Widget _cozyIllustration({bool loading = false}) {
    final style = CategoryIcons.styleFor(name, itemType: itemType);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.hasBoundedHeight && constraints.maxHeight > 0
            ? constraints.maxHeight
            : (height ?? size);
        final iconSize = (side * 0.5).clamp(16.0, 72.0);
        final spinnerSize = (side * 0.32).clamp(14.0, 28.0);
        return Container(
          color: style.background,
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: spinnerSize,
                  height: spinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(style.foreground),
                  ),
                )
              : Icon(style.icon, color: style.foreground, size: iconSize),
        );
      },
    );
  }
}
