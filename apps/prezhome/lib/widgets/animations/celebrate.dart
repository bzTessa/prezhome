import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../miau_character.dart';

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
