import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// Aparición escalonada fade + slide para un elemento de una lista o grid.
///
/// Cada [StaggeredEntrance] hace un fundido de entrada (opacidad 0 → 1) y un
/// pequeño deslizamiento vertical (translateY [slideFrom] → 0). El retardo de
/// inicio se deriva del [index] mediante la función pura
/// [AppMotion.staggerDelay], de modo que los elementos aparecen uno tras otro.
///
/// Respeta "reducir movimiento": si [AppMotion.reduceMotionOf] es `true`, el
/// elemento aparece ya en su sitio, sin animar.
///
/// Rendimiento: usa un único [TweenAnimationBuilder] que corre una sola vez por
/// construcción. No reconstruye en bucle ni interfiere con el scroll.
class StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  /// Desplazamiento vertical inicial (en px) desde el que entra el elemento.
  final double slideFrom;

  /// Duración base de cada elemento (su propia animación de entrada).
  final Duration duration;

  /// Separación entre el arranque de un elemento y el siguiente.
  final Duration step;

  /// Límite de elementos escalonados para que listas largas no acumulen
  /// retardos excesivos (ver [AppMotion.staggerDelay]).
  final int maxItems;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.slideFrom = 12,
    this.duration = AppMotion.base,
    this.step = const Duration(milliseconds: 60),
    this.maxItems = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = AppMotion.reduceMotionOf(context);

    if (reduceMotion) {
      // Sin animación: el elemento aparece directamente en su estado final.
      return child;
    }

    final Duration delay = AppMotion.staggerDelay(
      index,
      step: step,
      reduceMotion: reduceMotion,
      maxItems: maxItems,
    );

    // El retardo se simula ampliando la duración total y recortando el tramo
    // inicial: así evitamos timers y mantenemos todo dentro del propio tween.
    final Duration total = duration + delay;
    final double startFraction = total.inMicroseconds == 0
        ? 0
        : delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: AppMotion.easeOut,
      builder: (context, value, child) {
        // Mientras no llega su turno (value < startFraction) permanece oculto.
        final double local = startFraction >= 1
            ? 1
            : ((value - startFraction) / (1 - startFraction)).clamp(0.0, 1.0);
        return Opacity(
          opacity: local,
          child: Transform.translate(
            offset: Offset(0, slideFrom * (1 - local)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
