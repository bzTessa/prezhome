import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';

/// CONFETI POR CÓDIGO de PrezHome (sin paquete externo ni assets).
///
/// Dibuja un puñado acotado de partículas (rectángulos de colores de la paleta)
/// que caen y rotan durante un ratito corto, con un [CustomPainter] propio
/// animado por un único [AnimationController]. Pensado como "burst" de
/// celebración al terminar la compra: se autodestruye al acabar y NUNCA bloquea
/// los toques (va envuelto en [IgnorePointer]).
///
/// Respeta "reducir movimiento": con [AppMotion.reduceMotionOf] en `true` el
/// widget no monta nada (devuelve un hueco vacío), de modo que la celebración
/// queda en su estado final estático (solo Miau + tarjeta) sin confeti.
///
/// La GENERACIÓN de partículas es DETERMINISTA (sembrando un [math.Random] con
/// [seed]) y la caída es una función PURA del progreso, para poder testear la
/// lógica sin montar la UI (ver `test/confetti_test.dart`).

/// Número de partículas del burst. Acotado para que sea ligero.
const int kConfettiParticleCount = 24;

/// Número de colores de la paleta del confeti (ver [_ConfettiPalette]).
const int kConfettiPaletteSize = 5;

/// Duración por defecto del burst (~1.6 s, dentro del rango 1.2-2 s pedido).
const Duration kConfettiDuration = Duration(milliseconds: 1600);

/// Una partícula de confeti con sus parámetros DETERMINISTAS de nacimiento.
///
/// Las coordenadas horizontales y los factores van en 0..1 (fracción del
/// ancho/alto disponible), así el mismo conjunto sirve para cualquier tamaño de
/// lienzo. La posición vertical concreta se calcula con [verticalAt].
class ConfettiParticle {
  /// Posición horizontal inicial, 0..1 (fracción del ancho).
  final double x;

  /// Desvío horizontal total durante la caída, en fracción del ancho
  /// (-0.5..0.5): da un vaivén lateral suave.
  final double drift;

  /// Retardo de salida, 0..1 (fracción de la duración): escalona el burst para
  /// que no caigan todas a la vez.
  final double delay;

  /// Velocidad de caída relativa (0.6..1.0): unas caen algo más rápido.
  final double speed;

  /// Rotación inicial en vueltas (0..1) y velocidad de giro (vueltas totales).
  final double rotation;
  final double spin;

  /// Tamaño del lado mayor, en px lógicos.
  final double size;

  /// Índice de color dentro de la paleta de confeti.
  final int colorIndex;

  const ConfettiParticle({
    required this.x,
    required this.drift,
    required this.delay,
    required this.speed,
    required this.rotation,
    required this.spin,
    required this.size,
    required this.colorIndex,
  });

  /// Progreso LOCAL de esta partícula (0..1) dado el progreso global [t] del
  /// controlador (0..1), teniendo en cuenta su [delay]. Antes de su [delay]
  /// devuelve 0 (aún no ha salido); después avanza linealmente hasta 1.
  ///
  /// Función PURA y determinista: base de la posición y el fundido.
  double localProgress(double t) {
    if (t <= delay) return 0;
    final span = 1 - delay;
    if (span <= 0) return 1;
    final p = (t - delay) / span;
    return p.clamp(0.0, 1.0);
  }

  /// Posición vertical en fracción del alto (0 = arriba, 1 = abajo) para el
  /// progreso global [t]. Incorpora [speed] para que no todas lleguen a la vez.
  /// Función PURA: útil para tests.
  double verticalAt(double t) {
    final p = localProgress(t);
    return (p * speed).clamp(0.0, 1.0);
  }
}

/// Genera un conjunto DETERMINISTA de [count] partículas a partir de [seed].
///
/// Mismo [seed] -> mismas partículas (sembramos un [math.Random]). Se extrae
/// como función pura para testear que respeta el conteo y los rangos.
List<ConfettiParticle> generateConfetti({
  int count = kConfettiParticleCount,
  int seed = 42,
  int paletteSize = kConfettiPaletteSize,
}) {
  final rnd = math.Random(seed);
  final safePalette = paletteSize <= 0 ? 1 : paletteSize;
  return List<ConfettiParticle>.generate(count, (i) {
    return ConfettiParticle(
      x: rnd.nextDouble(),
      drift: rnd.nextDouble() - 0.5,
      delay: rnd.nextDouble() * 0.35,
      speed: 0.6 + rnd.nextDouble() * 0.4,
      rotation: rnd.nextDouble(),
      spin: (rnd.nextDouble() - 0.5) * 4,
      size: 7 + rnd.nextDouble() * 7,
      colorIndex: rnd.nextInt(safePalette),
    );
  });
}

/// Paleta del confeti, SOLO con tokens cálidos de [AppColors].
class _ConfettiPalette {
  const _ConfettiPalette._();
  static const List<Color> colors = [
    AppColors.sage,
    AppColors.terracotta,
    AppColors.peach,
    AppColors.frost,
    AppColors.woodDark,
  ];
  static const int length = kConfettiPaletteSize;
}

/// Lluvia de confeti dibujada por código. Se dispara una vez al montarse y
/// llama a [onCompleted] cuando el burst termina (para autodestruirse).
///
/// Con reduce-motion activo no muestra NADA (hueco vacío), dejando el estado
/// final estático de la celebración.
class ConfettiBurst extends StatefulWidget {
  final Duration duration;
  final int seed;
  final VoidCallback? onCompleted;

  const ConfettiBurst({
    super.key,
    this.duration = kConfettiDuration,
    this.seed = 42,
    this.onCompleted,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<ConfettiParticle> _particles;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _particles = generateConfetti(seed: widget.seed);
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decidimos UNA vez si animar según la preferencia de accesibilidad.
    _reduceMotion = AppMotion.reduceMotionOf(context);
    if (_reduceMotion) {
      // Sin movimiento: no animamos ni ocupamos nada; la celebración queda
      // estática. Notificamos "completado" para no dejar el burst colgado.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCompleted?.call();
      });
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) return const SizedBox.shrink();
    // IgnorePointer => nunca bloquea la interacción con lo que hay debajo.
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pinta las partículas para un progreso dado. Las que aún no han salido
/// (progreso local 0) o ya han caído del todo con fundido 0 no se dibujan.
class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final local = p.localProgress(progress);
      if (local <= 0) continue;

      // Caída vertical y vaivén lateral.
      final dy = p.verticalAt(progress) * size.height;
      final dx = (p.x + p.drift * local) * size.width;

      // Fundido de salida en el último tramo para que no desaparezcan de golpe.
      final opacity = local > 0.8
          ? (1 - (local - 0.8) / 0.2).clamp(0.0, 1.0)
          : 1.0;
      if (opacity <= 0) continue;

      final color =
          _ConfettiPalette.colors[p.colorIndex % _ConfettiPalette.length];
      paint.color = color.withValues(alpha: opacity);

      final angle = (p.rotation + p.spin * local) * 2 * math.pi;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      final half = p.size / 2;
      // Rectángulo alargado tipo papelillo.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-half, -half * 0.5, p.size, p.size * 0.5),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.particles != particles;
}
