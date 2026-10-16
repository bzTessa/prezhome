import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Tokens y helpers de animación de PrezHome.
///
/// Esta clase es la ÚNICA fuente de verdad para duraciones y curvas de las
/// animaciones de la app. Sustituye los `Duration(milliseconds: ...)` y curvas
/// sueltas por una escala pequeña y coherente, siempre dentro de un rango
/// cómodo (~120-350 ms) con curvas medidas.
///
/// Además expone funciones PURAS y testables que respetan la preferencia de
/// accesibilidad "reducir movimiento" (`MediaQuery.disableAnimations`): todos
/// los widgets de animación consultan [reduceMotionOf] y, si es `true`, se
/// renderizan en su estado final sin animar (o con duración ~0).
class AppMotion {
  const AppMotion._();

  // --- Duraciones ------------------------------------------------------------

  /// Rápida (120 ms): feedback táctil, pulsaciones, cambios menores.
  static const Duration fast = Duration(milliseconds: 120);

  /// Normal (220 ms): cross-fades y sustituto de los muelles con
  /// "reducir movimiento".
  static const Duration normal = Duration(milliseconds: 220);

  /// Base (250 ms): la mayoría de transiciones y apariciones.
  static const Duration base = Duration(milliseconds: 250);

  /// Lenta (350 ms): entradas destacadas o elementos grandes.
  static const Duration slow = Duration(milliseconds: 350);

  // --- Curvas ----------------------------------------------------------------

  /// Curva de salida suave para la mayoría de transiciones.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Rebote suave y medido para entradas con un toque de vida (sin exagerar).
  static const Curve easeOutBack = Curves.easeOutBack;

  // --- Muelles (estilo iOS, "Designing Fluid Interfaces") ------------------

  /// Convierte los parámetros de diseño de Apple ([dampingRatio] y [response]
  /// en segundos) en un [SpringDescription] de Flutter (masa 1).
  static SpringDescription appleSpring({
    double dampingRatio = 1.0,
    double response = 0.35,
  }) {
    final double stiffness = math.pow(2 * math.pi / response, 2).toDouble();
    final double damping = 4 * math.pi * dampingRatio / response;
    return SpringDescription(mass: 1, stiffness: stiffness, damping: damping);
  }

  /// Muelle por defecto: críticamente amortiguado, sin rebote.
  static final SpringDescription fluidDefault = appleSpring(
    dampingRatio: 1.0,
    response: 0.34,
  );

  /// Muelle interactivo: rebote ligero para gestos, Miau y botones.
  static final SpringDescription fluidBouncy = appleSpring(
    dampingRatio: 0.76,
    response: 0.38,
  );

  /// Muelle de Miau: más expresivo para sus cambios de estado.
  static final SpringDescription miauSpring = appleSpring(
    dampingRatio: 0.68,
    response: 0.42,
  );

  /// Curva que sigue a [spring] durante [duration], para widgets que solo
  /// aceptan curva (p. ej. `AnimatedSize`). Usa muelles sin rebote: el
  /// último tramo se recorta para terminar justo en 1.
  static Curve springCurve(
    SpringDescription spring, {
    Duration duration = slow,
  }) => _SpringCurve(spring, duration.inMicroseconds / 1e6);

  /// Rubber-banding de Apple: cuánto se mueve algo arrastrado [overshoot]
  /// píxeles más allá de su límite, en un contenedor de tamaño [dimension].
  static double rubberBand(
    double overshoot,
    double dimension, {
    double constant = 0.55,
  }) {
    return (overshoot * dimension * constant) /
        (dimension + constant * overshoot.abs());
  }

  /// Proyección de momento de Apple: hasta dónde llegaría por inercia algo
  /// soltado a [velocity] px/s con la deceleración de un scroll de iOS
  /// ([decelerationRate] por milisegundo). Decide el destino de un gesto según
  /// la fuerza del lanzamiento (p. ej. a qué paso ir).
  static double projectMomentum(
    double velocity, {
    double decelerationRate = 0.998,
  }) => (velocity / 1000) * decelerationRate / (1 - decelerationRate);

  // --- Lógica pura (testable) ------------------------------------------------

  /// Devuelve la duración EFECTIVA de una animación según [reduceMotion].
  ///
  /// Si [reduceMotion] es `true` devuelve [Duration.zero] (sin animación, el
  /// widget salta a su estado final). Si es `false` devuelve [desired] tal
  /// cual. Función pura: no depende del contexto ni de ningún estado global.
  static Duration effectiveDuration(
    Duration desired, {
    required bool reduceMotion,
  }) {
    return reduceMotion ? Duration.zero : desired;
  }

  /// Calcula el delay/escalonado de inicio para el elemento [index] de una
  /// lista o grid con aparición escalonada.
  ///
  /// Cada elemento arranca [step] más tarde que el anterior (index * step),
  /// opcionalmente limitado por [maxItems] para que listas largas no acumulen
  /// retardos enormes. Si [reduceMotion] es `true` devuelve [Duration.zero]
  /// para TODOS los índices (aparecen de golpe, en su sitio).
  ///
  /// Función pura: ideal para tests unitarios.
  static Duration staggerDelay(
    int index, {
    Duration step = const Duration(milliseconds: 60),
    required bool reduceMotion,
    int maxItems = 8,
  }) {
    if (reduceMotion || index <= 0) return Duration.zero;
    final int clamped = index > maxItems ? maxItems : index;
    return step * clamped;
  }

  /// Interpola linealmente entre [begin] y [end] según [t] (0..1).
  ///
  /// Se usa como base del contador animado y se extrae como función pura para
  /// poder testear los valores intermedios sin montar un widget.
  static double lerpDouble(double begin, double end, double t) {
    final double clampedT = t < 0
        ? 0
        : t > 1
        ? 1
        : t;
    return begin + (end - begin) * clampedT;
  }

  /// Lee si el sistema pide reducir las animaciones.
  ///
  /// Centraliza la lectura de `MediaQuery.disableAnimations`. Si no hay
  /// `MediaQuery` disponible (contexto fuera del árbol), asume `false`.
  /// TODOS los widgets de animación de la app consultan este helper.
  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve(this.spring, this.seconds);

  final SpringDescription spring;
  final double seconds;

  @override
  double transformInternal(double t) =>
      SpringSimulation(spring, 0, 1, 0).x(t * seconds);
}
