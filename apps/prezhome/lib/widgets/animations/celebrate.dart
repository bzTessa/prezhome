import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../miau_character.dart';
import 'spring_value.dart';

/// Micro-celebración ligera y reutilizable de PrezHome.
///
/// Muestra brevemente (≤600 ms) un pequeño "pop" (escala + fundido) de
/// Presidente Miau en modo celebrando, por encima de todo mediante un
/// [OverlayEntry] que se autodestruye. Pensada para feedback positivo al
/// completar una tarea (y, en el futuro, favorita / compra terminada).
///
/// No bloquea la interacción (el overlay ignora los toques) y respeta
/// "reducir movimiento": con [AppMotion.reduceMotionOf] en `true` no hace nada
/// visible (ni siquiera monta el overlay), de modo que la celebración es
/// puramente decorativa y opcional.
class Celebrate {
  const Celebrate._();

  /// Dispara la micro-celebración de forma imperativa sobre el [context] dado.
  ///
  /// Es seguro llamarla desde un `onPressed`/`onTap`: si no hay [Overlay] o si
  /// está activo "reducir movimiento", simplemente no hace nada.
  static void show(BuildContext context, {double size = 120}) {
    if (AppMotion.reduceMotionOf(context)) return;

    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) =>
          _CelebrationBurst(size: size, onCompleted: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  /// Tarea hecha: un check grueso que se dibuja a mano y, si hay [points],
  /// una insignia dorada "+N" que destella. No bloquea toques y no se
  /// muestra con "reducir movimiento".
  static void check(BuildContext context, {int? points}) {
    if (AppMotion.reduceMotionOf(context)) return;
    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) =>
          _CheckBurst(points: points, onCompleted: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _CheckBurst extends StatefulWidget {
  const _CheckBurst({required this.points, required this.onCompleted});

  final int? points;
  final VoidCallback onCompleted;

  @override
  State<_CheckBurst> createState() => _CheckBurstState();
}

class _CheckBurstState extends State<_CheckBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1100),
        )
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onCompleted();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material transparente: el texto del overlay usa el estilo de la app.
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              // Trazo en el primer 40 %, pausa y fundido en el último 25 %.
              final draw = Curves.easeOutCubic.transform((t / 0.4).clamp(0, 1));
              final fade =
                  1 - Curves.easeIn.transform(((t - 0.75) / 0.25).clamp(0, 1));
              final badge = ((t - 0.3) / 0.35).clamp(0.0, 1.0);
              return Opacity(
                opacity: fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.stroke, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.stroke,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _CheckPainter(draw, AppColors.done),
                      ),
                    ),
                    if (widget.points case final p? when p > 0) ...[
                      const SizedBox(height: 12),
                      Transform.scale(
                        scale: badge == 0
                            ? 0
                            : popScale(
                                Curves.easeOut.transform(badge),
                                rest: 0.5,
                                peak: 1.25,
                              ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.gold, width: 2),
                            // Destello dorado que se apaga.
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(
                                  alpha: 0.7 * (1 - badge),
                                ),
                                blurRadius: 24 * badge,
                                spreadRadius: 6 * badge,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 20,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+$p',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Check grueso con un trazo algo irregular, como el del logo. [progress] va
/// de 0 (nada) a 1 (dibujado entero).
class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.27, w * 0.53)
      ..quadraticBezierTo(w * 0.36, w * 0.6, w * 0.44, w * 0.7)
      ..quadraticBezierTo(w * 0.57, w * 0.48, w * 0.75, w * 0.31);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

/// Burst visual auto-contenido: pop de escala + fundido entrada/salida en
/// ≤600 ms. Se destruye llamando a [onCompleted] cuando termina.
class _CelebrationBurst extends StatefulWidget {
  final double size;
  final VoidCallback onCompleted;

  const _CelebrationBurst({required this.size, required this.onCompleted});

  @override
  State<_CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<_CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: AppMotion.easeOutBack);
    // Fundido: entra en el primer tramo y sale al final.
    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer => nunca bloquea la interacción con la pantalla debajo.
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: MiauCharacter(
              mood: MiauMood.celebrating,
              size: widget.size,
              float: false,
            ),
          ),
        ),
      ),
    );
  }
}
