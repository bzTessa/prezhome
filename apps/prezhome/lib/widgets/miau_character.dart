import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Estados de ánimo de la mascota. Cada uno mapea a una imagen.
/// Si aún no tienes la imagen específica, cae a la imagen por defecto.
enum MiauMood {
  greeting,
  celebrating,
  sleeping,
  cooking,
  curious,
  shopping,
  worried,
  neutral,
}

/// La mascota como elemento gráfico: muestra la pose según el contexto (solo
/// imágenes estáticas; la vida viene de transformaciones y trazos sutiles).
///
/// - Entra con un pequeño rebote suave.
/// - [float]: coreografía continua adaptada a cada [mood] (apagarla con
///   `float: false` en pantallas donde los tests esperan que todo se pose).
/// - Al cambiar de [mood] da un saltito con anticipación y aterrizaje elástico.
/// - [showEffects]: detalles suaves por pose (Zz, vapor, confeti geométrico…).
/// - [interactive]: al tocarla se aplasta, vibra, lanza 3 corazones y ejecuta
///   [onTap].
///
/// Nunca lleva texto con su nombre: es apoyo visual de avisos y consejos.
class MiauCharacter extends StatefulWidget {
  final MiauMood mood;
  final double size;
  final bool float;
  final bool interactive;
  final bool showEffects;
  final VoidCallback? onTap;

  const MiauCharacter({
    super.key,
    this.mood = MiauMood.neutral,
    this.size = 96,
    this.float = true,
    this.interactive = false,
    this.showEffects = true,
    this.onTap,
  });

  static const String _base = 'assets/images/presidente_prezhome.jpg';

  static const Map<MiauMood, String> _poseAssets = {
    MiauMood.greeting: 'assets/images/miau_saludando.png',
    MiauMood.celebrating: 'assets/images/miau_celebrando.png',
    MiauMood.sleeping: 'assets/images/miau_durmiendo.png',
    MiauMood.cooking: 'assets/images/miau_cocinando.png',
    MiauMood.curious: 'assets/images/miau_pensando.png',
    MiauMood.shopping: 'assets/images/miau_comprando.png',
    MiauMood.worried: 'assets/images/miau_triste.png',
    MiauMood.neutral: 'assets/images/miau_saludando.png',
  };

  @override
  State<MiauCharacter> createState() => _MiauCharacterState();
}

class _MiauCharacterState extends State<MiauCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduceMotionOf(context);
    _syncAnimations();
  }

  @override
  void didUpdateWidget(MiauCharacter old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood && !_reduceMotion) {
      _jump.forward(from: 0);
    }
    if (old.float != widget.float || old.mood != widget.mood) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (_reduceMotion) {
      _entry.value = 1;
      _floatCtrl.stop();
      _jump.stop();
      _tap.stop();
      return;
    }
    if (!_entry.isCompleted && !_entry.isAnimating) {
      _entry.forward();
    }
    if (widget.float && !_floatCtrl.isAnimating) {
      _floatCtrl.repeat();
    } else if (!widget.float && _floatCtrl.isAnimating) {
      _floatCtrl.stop();
    }
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (!_reduceMotion) _tap.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _entry.dispose();
    _floatCtrl.dispose();
    _jump.dispose();
    _tap.dispose();
    super.dispose();
  }

  static ({double dx, double dy, double sx, double sy, double rot}) _idlePose(
    double t,
    MiauMood mood,
  ) {
    final w = 2 * math.pi * t;
    switch (mood) {
      case MiauMood.sleeping:
        final b = 0.5 - 0.5 * math.cos(w);
        return (
          dx: 0,
          dy: -1.2 * math.sin(w),
          sx: 1 + 0.016 * b,
          sy: 1 + 0.038 * b,
          rot: 0.025 + 0.015 * math.sin(w),
        );
      case MiauMood.cooking:
        final bob = math.sin(w * 2).abs();
        return (
          dx: 0,
          dy: -3.5 * bob,
          sx: 1 + 0.014 * (1 - bob),
          sy: 1 - 0.014 * (1 - bob),
          rot: 0.045 * math.sin(w),
        );
      case MiauMood.celebrating:
        final hop = math.sin(w * 2).abs();
        final land = (1 - hop) * (1 - hop);
        return (
          dx: 0,
          dy: -5.5 * hop,
          sx: 1 + 0.035 * land - 0.015 * hop,
          sy: 1 - 0.03 * land + 0.02 * hop,
          rot: 0.055 * math.sin(w),
        );
      case MiauMood.shopping:
        final step = math.sin(w * 2).abs();
        return (
          dx: 0,
          dy: -3.0 * step,
          sx: 1,
          sy: 1 + 0.015 * step,
          rot: 0.048 * math.sin(w),
        );
      case MiauMood.curious:
        final pulse = math.pow(math.max(0.0, math.sin(w)), 2).toDouble();
        return (
          dx: 0,
          dy: -2.2 * math.sin(w),
          sx: 1,
          sy: 1 + 0.015 * math.sin(w),
          rot: 0.058 * pulse - 0.012,
        );
      case MiauMood.worried:
        final b = 0.5 - 0.5 * math.cos(w);
        return (
          dx: 1.1 * math.sin(w * 3),
          dy: 1.4 * b,
          sx: 1 + 0.012 * b,
          sy: 1 - 0.016 * b,
          rot: -0.02 + 0.012 * math.sin(w),
        );
      case MiauMood.greeting:
      case MiauMood.neutral:
        final s = math.sin(w);
        return (
          dx: 0,
          dy: -3.2 * s,
          sx: 1 - 0.012 * s,
          sy: 1 + 0.022 * s,
          rot: 0.032 * math.sin(w + 0.4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final posePath = MiauCharacter._poseAssets[widget.mood];
    final Widget image = posePath != null
        ? Image.asset(
            posePath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => _baseImage(),
          )
        : _baseImage();

    final entryCurve = CurvedAnimation(
      parent: _entry,
      curve: Curves.easeOutBack,
    );

    final Widget animatedCat = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entry, _floatCtrl, _jump, _tap]),
        builder: (context, child) {
          final idle = _floatCtrl.isAnimating
              ? _idlePose(_floatCtrl.value, widget.mood)
              : (dx: 0.0, dy: 0.0, sx: 1.0, sy: 1.0, rot: 0.0);

          final eScale = _reduceMotion ? 1.0 : (0.86 + 0.14 * entryCurve.value);
          final eOpacity = _reduceMotion ? 1.0 : _entry.value.clamp(0.0, 1.0);

          var dx = idle.dx;
          var dy = idle.dy;
          var sx = idle.sx * eScale;
          var sy = idle.sy * eScale;
          var rot = idle.rot;

          if (_jump.isAnimating) {
            final j = _jump.value;
            if (j < 0.15) {
              final a = j / 0.15;
              dy += 2.0 * a;
              sx += 0.08 * a;
              sy -= 0.08 * a;
            } else {
              final air = (j - 0.15) / 0.85;
              final arc = math.sin(math.pi * air);
              dy += -12.0 * arc;
              rot += 0.06 * math.sin(3 * math.pi * air);
              if (j > 0.7) {
                final l = math.sin(math.pi * (j - 0.7) / 0.3);
                sx += 0.11 * l;
                sy -= 0.09 * l;
              } else {
                sx -= 0.03 * arc;
                sy += 0.04 * arc;
              }
            }
          }

          if (_tap.isAnimating) {
            final p = _tap.value;
            if (p < 0.18) {
              final a = math.sin(math.pi * 0.5 * (p / 0.18));
              sx += 0.16 * a;
              sy -= 0.14 * a;
              dy += 2.0 * a;
            } else {
              final b = ((p - 0.18) / 0.82).clamp(0.0, 1.0);
              final bounce = math.sin(math.pi * b);
              dy += -9.0 * bounce;
              rot += 0.08 * math.sin(4 * math.pi * p) * (1 - p);
              sx -= 0.04 * bounce;
              sy += 0.05 * bounce;
            }
          }

          return Opacity(
            opacity: eOpacity,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..rotateZ(rot)
                  ..scaleByDouble(sx, sy, 1, 1),
                child: child,
              ),
            ),
          );
        },
        child: image,
      ),
    );

    final showAmbient =
        widget.showEffects && widget.size >= 40 && !_reduceMotion;
    final Widget layered = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          animatedCat,
          if (showAmbient)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_floatCtrl, _jump]),
                    builder: (context, _) {
                      if (!_floatCtrl.isAnimating && !_jump.isAnimating) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        painter: _MiauAmbientPainter(
                          mood: widget.mood,
                          t: _floatCtrl.value,
                          jump: _jump.value,
                          isJumping: _jump.isAnimating,
                          frost: AppColors.frost,
                          inkMuted: AppColors.inkMuted,
                          terracotta: AppColors.terracotta,
                          gold: AppColors.gold,
                          sage: AppColors.sage,
                          woodDark: AppColors.woodDark,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (widget.interactive)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _tap,
                    builder: (context, _) {
                      if (!_tap.isAnimating) return const SizedBox.shrink();
                      return CustomPaint(
                        painter: _TapHeartsPainter(
                          progress: _tap.value,
                          terracotta: AppColors.terracotta,
                          gold: AppColors.gold,
                          peach: AppColors.peach,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!widget.interactive) return layered;
    return Semantics(
      button: true,
      label: context.l.mascot,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: layered,
      ),
    );
  }

  Widget _baseImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size * 0.28),
      child: Image.asset(
        MiauCharacter._base,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MiauAmbientPainter extends CustomPainter {
  const _MiauAmbientPainter({
    required this.mood,
    required this.t,
    required this.jump,
    required this.isJumping,
    required this.frost,
    required this.inkMuted,
    required this.terracotta,
    required this.gold,
    required this.sage,
    required this.woodDark,
  });

  final MiauMood mood;
  final double t;
  final double jump;
  final bool isJumping;
  final Color frost;
  final Color inkMuted;
  final Color terracotta;
  final Color gold;
  final Color sage;
  final Color woodDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (mood) {
      case MiauMood.sleeping:
        _paintZ(canvas, size, 'z', (t) % 1.0, Offset(w * 0.72, h * 0.30), 0.14);
        _paintZ(
          canvas,
          size,
          'Z',
          (t + 0.5) % 1.0,
          Offset(w * 0.80, h * 0.24),
          0.18,
        );
      case MiauMood.cooking:
        _paintSteam(canvas, size, Offset(w * 0.25, h * 0.28), t);
        _paintSteam(canvas, size, Offset(w * 0.75, h * 0.24), (t + 0.45) % 1.0);
      case MiauMood.celebrating:
        final colors = [terracotta, gold, sage];
        final burst = isJumping ? math.sin(math.pi * jump) : 0.0;
        for (var i = 0; i < 6; i++) {
          final p = (t + i / 6) % 1.0;
          final angle = (i * math.pi / 3) + t * 0.8;
          final dist = w * (0.38 + 0.12 * math.sin(p * math.pi) + 0.10 * burst);
          final cx = w * 0.5 + math.cos(angle) * dist;
          final cy = h * 0.44 + math.sin(angle) * dist * 0.78;
          final alpha = (0.35 + 0.55 * math.sin(p * math.pi)).clamp(0.0, 1.0);
          final paint = Paint()..color = colors[i % 3].withValues(alpha: alpha);
          final r = w * 0.032;
          if (i.isEven) {
            canvas.drawCircle(Offset(cx, cy), r, paint);
          } else {
            _drawDiamond(canvas, Offset(cx, cy), r * 1.45, paint);
          }
        }
      case MiauMood.curious:
        for (var i = 0; i < 3; i++) {
          final p = (t + i * 0.18) % 1.0;
          final alpha = (math.sin(p * math.pi) * 0.55).clamp(0.0, 1.0);
          final cx = w * (0.76 + i * 0.07);
          final cy = h * (0.28 - i * 0.08 - 0.05 * p);
          canvas.drawCircle(
            Offset(cx, cy),
            w * (0.024 + i * 0.011),
            Paint()..color = woodDark.withValues(alpha: alpha),
          );
        }
      case MiauMood.worried:
        final alpha = (0.45 + 0.4 * math.sin(t * 2 * math.pi)).clamp(0.0, 1.0);
        final dropCenter = Offset(
          w * 0.82,
          h * (0.28 + 0.06 * ((t * 2) % 1.0)),
        );
        _drawTeardrop(
          canvas,
          dropCenter,
          w * 0.065,
          Paint()..color = frost.withValues(alpha: alpha),
        );
      case MiauMood.shopping:
        for (var i = 0; i < 2; i++) {
          final p = (t * 2 + i * 0.5) % 1.0;
          final alpha = (0.35 + 0.55 * math.sin(p * math.pi)).clamp(0.0, 1.0);
          final cx = w * (i == 0 ? 0.18 : 0.84);
          final cy = h * (0.24 - 0.07 * math.sin(p * math.pi));
          canvas.drawCircle(
            Offset(cx, cy),
            w * 0.03,
            Paint()..color = gold.withValues(alpha: alpha),
          );
        }
      case MiauMood.greeting:
      case MiauMood.neutral:
        for (var i = 0; i < 2; i++) {
          final p = (t + i * 0.4) % 1.0;
          final alpha = (0.25 + 0.5 * math.sin(p * math.pi)).clamp(0.0, 1.0);
          final cx = w * (0.78 + i * 0.10);
          final cy = h * (0.24 - i * 0.07 - 0.03 * math.sin(p * math.pi));
          canvas.drawCircle(
            Offset(cx, cy),
            w * (0.026 - i * 0.005),
            Paint()..color = gold.withValues(alpha: alpha),
          );
        }
    }
  }

  void _paintZ(
    Canvas canvas,
    Size size,
    String glyph,
    double p,
    Offset origin,
    double scale,
  ) {
    final alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
    if (alpha <= 0.02) return;
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: size.width * scale,
          fontWeight: FontWeight.w800,
          color: (glyph == 'Z' ? frost : inkMuted).withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = Offset(
      origin.dx + p * size.width * 0.12 - tp.width / 2,
      origin.dy - p * size.height * 0.22 - tp.height / 2,
    );
    tp.paint(canvas, pos);
  }

  void _paintSteam(Canvas canvas, Size size, Offset origin, double p) {
    final alpha = (math.sin(p * math.pi) * 0.65).clamp(0.0, 1.0);
    if (alpha <= 0.02) return;
    final h = size.height;
    final w = size.width;
    final rise = h * 0.16 * p;
    final sway = w * 0.04 * math.sin(p * 2 * math.pi);
    final path = Path()
      ..moveTo(origin.dx, origin.dy - rise * 0.2)
      ..quadraticBezierTo(
        origin.dx - w * 0.045 + sway,
        origin.dy - h * 0.08 - rise * 0.5,
        origin.dx + sway * 0.5,
        origin.dy - h * 0.14 - rise,
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.025)
      ..strokeCap = StrokeCap.round
      ..color = terracotta.withValues(alpha: alpha);
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.72, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.72, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawTeardrop(Canvas canvas, Offset top, double s, Paint paint) {
    final path = Path()
      ..moveTo(top.dx, top.dy - s)
      ..quadraticBezierTo(top.dx + s, top.dy + s * 0.2, top.dx, top.dy + s)
      ..quadraticBezierTo(top.dx - s, top.dy + s * 0.2, top.dx, top.dy - s)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MiauAmbientPainter old) =>
      old.mood != mood ||
      old.t != t ||
      old.jump != jump ||
      old.isJumping != isJumping ||
      old.frost != frost ||
      old.terracotta != terracotta;
}

class _TapHeartsPainter extends CustomPainter {
  const _TapHeartsPainter({
    required this.progress,
    required this.terracotta,
    required this.gold,
    required this.peach,
  });

  final double progress;
  final Color terracotta;
  final Color gold;
  final Color peach;

  @override
  void paint(Canvas canvas, Size size) {
    final specs = [
      (delay: 0.0, dx: 0.26, sway: -0.06, scale: 0.16, color: terracotta),
      (delay: 0.14, dx: 0.68, sway: 0.08, scale: 0.13, color: gold),
      (delay: 0.28, dx: 0.48, sway: -0.04, scale: 0.12, color: peach),
    ];
    for (final s in specs) {
      final local = ((progress - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final alpha = (1 - local).clamp(0.0, 1.0);
      final pop = local < 0.2 ? Curves.easeOutBack.transform(local / 0.2) : 1.0;
      final cx = size.width * (s.dx + s.sway * math.sin(local * math.pi * 2.5));
      final cy = size.height * (0.28 - 0.36 * local);
      final r = size.width * s.scale * pop;
      _drawHeart(
        canvas,
        Offset(cx, cy),
        r,
        Paint()..color = s.color.withValues(alpha: alpha),
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    final s = size * 0.55;
    path.moveTo(x, y + s * 0.9);
    path.cubicTo(
      x - s * 1.4,
      y - s * 0.1,
      x - s * 0.7,
      y - s * 1.1,
      x,
      y - s * 0.35,
    );
    path.cubicTo(
      x + s * 0.7,
      y - s * 1.1,
      x + s * 1.4,
      y - s * 0.1,
      x,
      y + s * 0.9,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TapHeartsPainter old) => old.progress != progress;
}
