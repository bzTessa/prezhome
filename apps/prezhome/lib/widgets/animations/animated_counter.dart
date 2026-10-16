import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// Firma del formateador del contador: recibe el valor numérico actual
/// (interpolado durante la animación) y devuelve el texto a mostrar.
///
/// Permite reutilizar los formatos que ya usa la app sin inventar ninguno,
/// p. ej. `(v) => '${v.toStringAsFixed(2)} €'` para euros o
/// `(v) => '${v.round()} kcal'` para calorías.
typedef CounterFormatter = String Function(double value);

/// Muestra un valor numérico que se anima de su valor anterior al nuevo.
///
/// Interpola entre el valor previo y [value] con [AppMotion.base] /
/// [AppMotion.easeOut] y, a la vez, el número sube un poco al crecer y baja al
/// decrecer (dirección semántica vertical). El texto se construye con
/// [formatter], de modo que el llamante controla el formato (euros, kcal,
/// puntos...).
///
/// Respeta "reducir movimiento": si [AppMotion.reduceMotionOf] es `true`
/// muestra directamente el valor final sin animar.
class AnimatedCounter extends StatefulWidget {
  /// Valor objetivo a mostrar.
  final double value;

  /// Formateador del número → texto. Obligatorio para no inventar formatos.
  final CounterFormatter formatter;

  /// Estilo de texto del número.
  final TextStyle? style;

  /// Duración de la animación (por defecto [AppMotion.base]).
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = AppMotion.base,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  late double _from = widget.value;

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = AppMotion.reduceMotionOf(context);
    final Duration effective = AppMotion.effectiveDuration(
      widget.duration,
      reduceMotion: reduceMotion,
    );
    final double to = widget.value;
    // Al subir entra desde abajo; al bajar, desde arriba.
    final double dir = to > _from ? 1 : -1;

    // TweenAnimationBuilder parte del valor que estaba mostrando cuando
    // [value] cambia; `begin` solo cuenta en el primer render.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: to, end: to),
      duration: effective,
      curve: AppMotion.easeOut,
      builder: (context, v, child) {
        final double left = to == _from ? 0 : ((to - v) / (to - _from));
        return Transform.translate(
          offset: Offset(0, dir * 6 * left.clamp(0.0, 1.0)),
          child: Text(widget.formatter(v), style: widget.style),
        );
      },
    );
  }
}
