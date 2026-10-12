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
/// Usa [TweenAnimationBuilder] para interpolar entre el valor previo y
/// [value] con [AppMotion.base] / [AppMotion.easeOut]. El texto se construye
/// con [formatter], de modo que el llamante controla el formato (euros, kcal,
/// puntos...).
///
/// Respeta "reducir movimiento": si [AppMotion.reduceMotionOf] es `true`
/// muestra directamente el valor final sin animar.
class AnimatedCounter extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool reduceMotion = AppMotion.reduceMotionOf(context);
    final Duration effective = AppMotion.effectiveDuration(
      duration,
      reduceMotion: reduceMotion,
    );

    // TweenAnimationBuilder recuerda el `end` anterior y lo usa como `begin`
    // cuando [value] cambia, animando del valor previo al nuevo. Dejamos
    // `begin` por si es el primer render (así parte del valor final).
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: effective,
      curve: AppMotion.easeOut,
      builder: (context, animatedValue, child) {
        return Text(formatter(animatedValue), style: style);
      },
    );
  }
}
