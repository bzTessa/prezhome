import 'package:flutter/material.dart';

import '../services/product_photo_resolver.dart';
import 'drawn_icons.dart';
import 'food_category_icon.dart';
import 'product_icons.dart';

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
///
/// En modo [photoOnly] (lista de la compra, despensa, buscador) la foto real
/// del catálogo tiene prioridad absoluta; con [illustrationFallback] true, si
/// no existe foto alguna, se pinta la ilustración cozy de categoría como último
/// recurso en vez de un recuadro blanco.
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

  /// Si es true, ignora [imageUrl] y pinta SIEMPRE la ilustración cozy de la
  /// categoría. Útil en contextos como la lista de la compra, donde las fotos
  /// reales de básicos abstractos ("sal", "aceite") salen genéricas/aleatorias
  /// y la ilustración por categoría queda más limpia y coherente.
  final bool forceIllustration;

  /// Solo la foto real: se enseña aunque el producto sea genérico y, si no
  /// hay, se cae a la ilustración cozy de categoría SOLO cuando
  /// [illustrationFallback] es true; si es false queda el hueco liso (buscador,
  /// iconos apagados).
  final bool photoOnly;

  /// En modo [photoOnly], si no hay foto real, muestra la ilustración cozy de
  /// categoría (icono propio / dibujo / icono de categoría) como ÚLTIMO RECURSO
  /// en vez de dejar un recuadro blanco vacío. La foto real del catálogo SIEMPRE
  /// tiene prioridad: la ilustración solo aparece cuando no existe foto alguna.
  /// Por defecto false para no cambiar el comportamiento de los demás usos.
  final bool illustrationFallback;

  /// Ajuste de la foto. Las fotos de envase del súper se ven mejor enteras
  /// (contain); las de alimentos, recortadas (cover).
  final BoxFit fit;

  const FoodImage({
    super.key,
    required this.name,
    this.itemType,
    this.imageUrl,
    this.size = 48,
    this.width,
    this.height,
    this.radius = 14,
    this.forceIllustration = false,
    this.photoOnly = false,
    this.illustrationFallback = false,
    this.fit = BoxFit.cover,
  });

  /// En los productos genéricos (cebolla, leche...) no se enseña la foto de
  /// un envase de OFF: va su foto genérica, la de la persona o el icono.
  bool get _hasPhoto =>
      !forceIllustration &&
      imageUrl != null &&
      imageUrl!.trim().isNotEmpty &&
      // Con photoOnly tampoco valen los dibujos guardados como foto.
      (photoOnly
          ? !DrawnIcons.isDrawn(imageUrl)
          : !(ProductIcons.isGeneric(name) &&
                (isSharablePhoto(imageUrl!) || isStockPhoto(imageUrl))));

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
            ? DrawnIcons.isDrawn(imageUrl)
                  ? _iconBox(_network(BoxFit.contain, w))
                  : _isPackshot
                  // Foto de envase: entera y reducida sobre blanco, para que
                  // se reconozca el producto (recortada no se entiende).
                  ? ColoredBox(
                      color: Colors.white,
                      child: _inset(0.06, _network(BoxFit.contain, w)),
                    )
                  : _network(fit, w)
            : _cozyIllustration(),
      ),
    );
  }

  /// Fotos de producto sobre blanco: envases de Open Food Facts y fotos
  /// genéricas (`product-image`). Se ven enteras, como en el súper online.
  bool get _isPackshot {
    final url = imageUrl ?? '';
    // Con contain se pide la foto entera: va sobre blanco, como el envase.
    return fit == BoxFit.contain ||
        url.contains('openfoodfacts') ||
        url.contains('/generic/');
  }

  Widget _network(BoxFit boxFit, double w) {
    return LayoutBuilder(
      builder: (context, constraints) => Image.network(
        imageUrl!,
        fit: boxFit,
        // Acotamos la resolución de decodificado al ancho real que se
        // va a pintar (en píxeles físicos), igual que RecipeImage.
        cacheWidth: _cacheWidthFor(context, constraints, w),
        errorBuilder: (context, error, stack) {
          // Se busca otra foto la próxima vez (ver brokenPhotos).
          brokenPhotos.add(imageUrl!);
          return _cozyIllustration();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _cozyIllustration(loading: true);
        },
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

  /// Ilustración de respaldo: el icono propio del producto, su dibujo
  /// compartido o el icono de la categoría. Mientras carga la foto, un
  /// spinner sobre el fondo de la categoría.
  Widget _cozyIllustration({bool loading = false}) {
    if (loading) return _categoryIcon(loading: true);
    // En photoOnly sin foto real: la ilustración cozy es el ÚLTIMO recurso
    // (nunca un recuadro blanco) cuando se pide explícitamente; si no, hueco
    // liso como antes.
    if (photoOnly && !illustrationFallback) return const SizedBox.expand();
    final asset = ProductIcons.assetFor(name);
    if (asset != null) {
      return _iconBox(Image.asset(asset, fit: BoxFit.contain));
    }
    // Sin icono propio: su dibujo compartido (se dibuja la primera vez).
    final drawn = DrawnIcons.urlFor(name);
    if (drawn == null) return _categoryIcon();
    return FutureBuilder<String?>(
      future: drawn,
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) return _categoryIcon();
        return _iconBox(
          LayoutBuilder(
            builder: (context, constraints) => Image.network(
              url,
              fit: BoxFit.contain,
              // Los dibujos miden 512 px: sin esto cada icono de la lista se
              // decodifica entero y la lista da tirones.
              cacheWidth: _cacheWidthFor(context, constraints, size),
              errorBuilder: (context, error, stack) => _categoryIcon(),
            ),
          ),
        );
      },
    );
  }

  /// Icono de producto sobre el fondo cálido de su categoría.
  Widget _iconBox(Widget icon) {
    final style = CategoryIcons.styleFor(name, itemType: itemType);
    return ColoredBox(color: style.background, child: _inset(0.14, icon));
  }

  /// Margen proporcional al ancho pintado. Con `width: double.infinity`
  /// (tarjetas de la cuadrícula) el margen salía infinito y la foto no se veía.
  Widget _inset(double factor, Widget child) => LayoutBuilder(
    builder: (context, constraints) {
      final side = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : (width ?? size);
      return Padding(
        padding: EdgeInsets.all(side.isFinite ? side * factor : 0),
        child: child,
      );
    },
  );

  /// Icono vectorial de la categoría (o un spinner mientras carga la foto).
  Widget _categoryIcon({bool loading = false}) {
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
