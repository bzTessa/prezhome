import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Qué se pinta en el plato de una receta sin foto.
enum DishKind { soup, pasta, rice, salad, dessert, drink, breakfast, plate }

const _kindWords = <DishKind, List<String>>{
  DishKind.soup: [
    'sopa',
    'crema',
    'caldo',
    'potaje',
    'puré',
    'pure',
    'gazpacho',
    'salmorejo',
    'cocido',
    'estofad',
    'lentejas',
    'garbanzos',
    'alubias',
    'guiso',
  ],
  DishKind.pasta: [
    'pasta',
    'espagueti',
    'spaghetti',
    'macarrones',
    'tallarines',
    'lasaña',
    'lasana',
    'fideo',
    'noodle',
    'ñoquis',
    'gnocchi',
    'ravioli',
  ],
  DishKind.rice: [
    'arroz',
    'paella',
    'risotto',
    'quinoa',
    'cuscús',
    'cuscus',
    'bowl',
  ],
  DishKind.salad: ['ensalada', 'salad', 'verduras', 'vegetal', 'wok'],
  DishKind.dessert: [
    'tarta',
    'bizcocho',
    'pastel',
    'galleta',
    'brownie',
    'flan',
    'natillas',
    'helado',
    'postre',
    'mousse',
    'cookie',
  ],
  DishKind.drink: [
    'batido',
    'smoothie',
    'zumo',
    'café',
    'cafe',
    'infusión',
    'limonada',
  ],
  DishKind.breakfast: [
    'tostada',
    'tortitas',
    'pancake',
    'avena',
    'porridge',
    'yogur',
    'huevos revueltos',
    'desayuno',
  ],
};

/// Elige el dibujo por las palabras del título; si no reconoce ninguna,
/// usa el tipo de comida ([mealTypes]) y, al final, un plato combinado.
DishKind dishKindFor(String title, [List<String> mealTypes = const []]) {
  final t = title.toLowerCase();
  for (final e in _kindWords.entries) {
    if (e.value.any(t.contains)) return e.key;
  }
  if (mealTypes.contains('dessert')) return DishKind.dessert;
  if (mealTypes.contains('drink')) return DishKind.drink;
  if (mealTypes.contains('breakfast')) return DishKind.breakfast;
  return DishKind.plate;
}

/// Plato visto desde arriba, dibujado en código, para las recetas sin foto.
/// El mismo título da siempre el mismo dibujo.
class DishIllustration extends StatelessWidget {
  const DishIllustration({
    super.key,
    required this.title,
    this.mealTypes = const [],
  });

  final String title;
  final List<String> mealTypes;

  @override
  Widget build(BuildContext context) {
    final kind = dishKindFor(title, mealTypes);
    return CustomPaint(
      painter: _DishPainter(
        kind: kind,
        seed: title.hashCode,
        background: _backgroundFor(kind),
        plate: AppColors.card,
        shadow: AppColors.softShadow,
      ),
      child: const SizedBox.expand(),
    );
  }

  static Color _backgroundFor(DishKind kind) => switch (kind) {
    DishKind.soup => AppColors.terracottaBg,
    DishKind.pasta || DishKind.rice || DishKind.breakfast => AppColors.goldBg,
    DishKind.salad => AppColors.sageBg,
    DishKind.dessert => AppColors.lilacBg,
    DishKind.drink => AppColors.frostBg,
    DishKind.plate => AppColors.goldBg,
  };
}

class _DishPainter extends CustomPainter {
  _DishPainter({
    required this.kind,
    required this.seed,
    required this.background,
    required this.plate,
    required this.shadow,
  });

  final DishKind kind;
  final int seed;
  final Color background;
  final Color plate;
  final Color shadow;

  // Colores de comida fijos: la comida no cambia con el modo oscuro.
  static const _rice = Color(0xFFF3E3B5);
  static const _saffron = Color(0xFFE9B949);
  static const _chicken = Color(0xFFD9893F);
  static const _brown = Color(0xFFA0522D);
  static const _green = Color(0xFF6B9A4B);
  static const _leaf = Color(0xFF8DB85C);
  static const _tomato = Color(0xFFD9502F);
  static const _pasta = Color(0xFFF0C75E);
  static const _cream = Color(0xFFFFF4D6);
  static const _berry = Color(0xFFB0476B);
  static const _chocolate = Color(0xFF6B3E26);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final rnd = math.Random(seed);
    // Un poco por encima del centro: abajo suele ir el título de la tarjeta.
    final c = Offset(size.width / 2, size.height * 0.4);
    final r = math.min(size.width * 0.36, size.height * 0.3);

    // Plato (o vaso) con sombra suave.
    canvas.drawCircle(
      c.translate(0, r * 0.06),
      r * 1.02,
      Paint()
        ..color = shadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );
    canvas.drawCircle(c, r, Paint()..color = plate);
    canvas.drawCircle(
      c,
      r * 0.78,
      Paint()
        ..color = background.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02,
    );
    final inner = r * 0.76;

    void blob(Offset o, double rad, Color color) =>
        canvas.drawCircle(o, rad, Paint()..color = color);
    Offset around(double dist, double angle) =>
        c + Offset(math.cos(angle) * dist, math.sin(angle) * dist);

    switch (kind) {
      case DishKind.soup:
        blob(c, inner, rnd.nextBool() ? _tomato : _saffron);
        for (var i = 0; i < 7; i++) {
          blob(
            around(inner * 0.6 * rnd.nextDouble(), rnd.nextDouble() * 6.3),
            inner * 0.08,
            i.isEven ? _green : _cream,
          );
        }
      case DishKind.pasta:
        final p = Paint()
          ..color = _pasta
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = inner * 0.09;
        for (var i = 0; i < 9; i++) {
          final rr = inner * (0.25 + 0.6 * rnd.nextDouble());
          final start = rnd.nextDouble() * 6.3;
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: rr),
            start,
            2.2,
            false,
            p,
          );
        }
        blob(c.translate(-inner * 0.2, -inner * 0.1), inner * 0.16, _tomato);
        blob(c.translate(inner * 0.25, inner * 0.15), inner * 0.12, _green);
      case DishKind.rice:
        blob(c, inner * 0.92, rnd.nextBool() ? _saffron : _rice);
        for (var i = 0; i < 10; i++) {
          blob(
            around(inner * 0.75 * rnd.nextDouble(), rnd.nextDouble() * 6.3),
            inner * 0.09,
            [_green, _tomato, _chicken][i % 3],
          );
        }
      case DishKind.salad:
        for (var i = 0; i < 14; i++) {
          final o = around(
            inner * 0.7 * rnd.nextDouble(),
            rnd.nextDouble() * 6.3,
          );
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(rnd.nextDouble() * 6.3);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: inner * 0.42,
              height: inner * 0.2,
            ),
            Paint()..color = i.isEven ? _green : _leaf,
          );
          canvas.restore();
        }
        for (var i = 0; i < 4; i++) {
          blob(
            around(inner * 0.5 * rnd.nextDouble(), rnd.nextDouble() * 6.3),
            inner * 0.11,
            _tomato,
          );
        }
      case DishKind.dessert:
        final slice = Path()
          ..moveTo(c.dx - inner * 0.55, c.dy + inner * 0.35)
          ..lineTo(c.dx + inner * 0.6, c.dy + inner * 0.35)
          ..lineTo(c.dx + inner * 0.1, c.dy - inner * 0.55)
          ..close();
        canvas.drawPath(
          slice,
          Paint()..color = rnd.nextBool() ? _chocolate : _cream,
        );
        canvas.drawPath(
          slice,
          Paint()
            ..color = _brown
            ..style = PaintingStyle.stroke
            ..strokeWidth = inner * 0.06
            ..strokeJoin = StrokeJoin.round,
        );
        blob(c.translate(inner * 0.1, -inner * 0.42), inner * 0.12, _berry);
      case DishKind.drink:
        blob(c, inner * 0.7, rnd.nextBool() ? _berry : _saffron);
        blob(c.translate(inner * 0.2, -inner * 0.2), inner * 0.15, _cream);
      case DishKind.breakfast:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c.translate(-inner * 0.15, 0),
              width: inner * 0.9,
              height: inner * 0.8,
            ),
            Radius.circular(inner * 0.2),
          ),
          Paint()..color = _chicken,
        );
        blob(c.translate(inner * 0.35, inner * 0.2), inner * 0.3, _cream);
        blob(c.translate(inner * 0.35, inner * 0.2), inner * 0.13, _saffron);
      case DishKind.plate:
        // Combinado: algo de proteína, guarnición y verdura.
        blob(c.translate(-inner * 0.25, -inner * 0.2), inner * 0.38, _rice);
        for (var i = 0; i < 2; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: c.translate(
                inner * 0.28,
                -inner * 0.15 + i * inner * 0.35,
              ),
              width: inner * 0.62,
              height: inner * 0.38,
            ),
            Paint()..color = i.isEven ? _chicken : _brown,
          );
        }
        for (var i = 0; i < 5; i++) {
          blob(
            c.translate(
              -inner * 0.35 + rnd.nextDouble() * inner * 0.4,
              inner * 0.35 + rnd.nextDouble() * inner * 0.2,
            ),
            inner * 0.11,
            i.isEven ? _green : _leaf,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_DishPainter old) =>
      old.kind != kind || old.seed != seed || old.background != background;
}
