import 'package:flutter/material.dart';

import '../services/product_photo_resolver.dart';
import 'animations/app_transitions.dart';
import 'drawn_icons.dart';
import 'food_category_icon.dart';
import 'product_icons.dart';

/// Combo visual de un alimento: FOTO REAL si hay URL, o una ILUSTRACIÓN COZY
/// vectorial de categoría como respaldo. NUNCA renderiza un emoji del sistema.
class FoodImage extends StatelessWidget {
  final String name;
  final String? itemType;
  final String? imageUrl;
  final double size;
  final double? width;
  final double? height;
  final double radius;
  final bool forceIllustration;
  final bool photoOnly;
  final bool illustrationFallback;
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

  bool get _hasPhoto =>
      !forceIllustration &&
      imageUrl != null &&
      imageUrl!.trim().isNotEmpty &&
      !isBrokenPhoto(imageUrl) &&
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
                  ? _iconBox(_network(context, BoxFit.contain, w), w)
                  : _isPackshot
                  ? ColoredBox(
                      color: Colors.white,
                      child: _inset(
                        0.06,
                        _network(context, BoxFit.contain, w),
                        w,
                      ),
                    )
                  : _network(context, fit, w)
            : _cozyIllustration(),
      ),
    );
  }

  bool get _isPackshot {
    final url = imageUrl ?? '';
    return fit == BoxFit.contain ||
        url.contains('openfoodfacts') ||
        url.contains('/generic/');
  }

  Widget _network(BuildContext context, BoxFit boxFit, double w) {
    if (w.isFinite && w > 0) {
      return _buildNetworkImage(
        boxFit,
        cacheWidth: _cacheWidthFromLogical(context, w),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _buildNetworkImage(
        boxFit,
        cacheWidth: _cacheWidthFor(context, constraints, w),
      ),
    );
  }

  Widget _buildNetworkImage(BoxFit boxFit, {int? cacheWidth}) {
    return Image.network(
      imageUrl!,
      fit: boxFit,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stack) {
        brokenPhotos.add(imageUrl!);
        return _cozyIllustration();
      },
      frameBuilder: (context, child, frame, sync) => fadeInPhoto(
        context: context,
        image: child,
        frame: frame,
        wasSynchronouslyLoaded: sync,
        placeholder: _cozyIllustration(loading: true),
      ),
    );
  }

  int? _cacheWidthFromLogical(BuildContext context, double logicalWidth) {
    if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalWidth * dpr).round();
  }

  int? _cacheWidthFor(
    BuildContext context,
    BoxConstraints constraints,
    double fallbackWidth,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : (fallbackWidth.isFinite ? fallbackWidth : 400.0);
    if (logicalWidth <= 0) return null;
    return (logicalWidth * dpr).round();
  }

  Widget _cozyIllustration({bool loading = false}) {
    if (loading) return _categoryIcon(loading: true);
    if (photoOnly && !illustrationFallback) return const SizedBox.expand();
    final asset = ProductIcons.assetFor(name);
    if (asset != null) {
      return _iconBox(Image.asset(asset, fit: BoxFit.contain), width ?? size);
    }
    final drawn = DrawnIcons.urlFor(name);
    if (drawn == null) return _categoryIcon();
    return FutureBuilder<String?>(
      future: drawn,
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) return _categoryIcon();
        final w = width ?? size;
        return _iconBox(
          w.isFinite && w > 0
              ? Image.network(
                  url,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  cacheWidth: _cacheWidthFromLogical(context, w),
                  errorBuilder: (context, error, stack) => _categoryIcon(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => Image.network(
                    url,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    cacheWidth: _cacheWidthFor(context, constraints, size),
                    errorBuilder: (context, error, stack) => _categoryIcon(),
                  ),
                ),
          w,
        );
      },
    );
  }

  Widget _iconBox(Widget icon, double w) {
    final style = CategoryIcons.styleFor(name, itemType: itemType);
    return ColoredBox(color: style.background, child: _inset(0.14, icon, w));
  }

  Widget _inset(double factor, Widget child, double w) {
    if (w.isFinite && w > 0) {
      return Padding(padding: EdgeInsets.all(w * factor), child: child);
    }
    return LayoutBuilder(
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
  }

  Widget _categoryIcon({bool loading = false}) {
    final style = CategoryIcons.styleFor(name, itemType: itemType);
    final side = height ?? size;
    if (side.isFinite && side > 0) {
      final iconSize = (side * 0.5).clamp(16.0, 72.0);
      return Container(
        color: style.background,
        alignment: Alignment.center,
        child: Icon(
          style.icon,
          color: loading
              ? style.foreground.withValues(alpha: 0.55)
              : style.foreground,
          size: iconSize,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final measured =
            constraints.hasBoundedHeight && constraints.maxHeight > 0
            ? constraints.maxHeight
            : (height ?? size);
        final iconSize = (measured * 0.5).clamp(16.0, 72.0);
        return Container(
          color: style.background,
          alignment: Alignment.center,
          child: Icon(
            style.icon,
            color: loading
                ? style.foreground.withValues(alpha: 0.55)
                : style.foreground,
            size: iconSize,
          ),
        );
      },
    );
  }
}
