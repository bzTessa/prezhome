import 'package:flutter/widgets.dart';

/// Tokens y helpers de animación de PrezHome.
///
/// Esta clase es la ÚNICA fuente de verdad para duraciones y curvas de las
/// animaciones de la app. Sustituye los `Duration(milliseconds: ...)` y curvas
/// sueltas por una escala pequeña y coherente, siempre dentro de un rango
/// cómodo (~150-350 ms) con curvas medidas.
///
/// Además expone funciones PURAS y testables que respetan la preferencia de
/// accesibilidad "reducir movimiento" (`MediaQuery.disableAnimations`): todos
/// los widgets de animación consultan [reduceMotionOf] y, si es `true`, se
/// renderizan en su estado final sin animar (o con duración ~0).
class AppMotion {
  const AppMotion._();

  // --- Duraciones ------------------------------------------------------------

  /// Rápida (150 ms): feedback táctil, pulsaciones, cambios menores.
  static const Duration fast = Duration(milliseconds: 150);

  /// Base (250 ms): la mayoría de transiciones y apariciones.
  static const Duration base = Duration(milliseconds: 250);

  /// Lenta (350 ms): entradas destacadas o elementos grandes.
  static const Duration slow = Duration(milliseconds: 350);

  // --- Curvas ----------------------------------------------------------------

  /// Curva de salida suave para la mayoría de transiciones.
  static const Curve easeOut = Curves.easeOut;

  /// Rebote suave y medido para entradas con un toque de vida (sin exagerar).
  static const Curve easeOutBack = Curves.easeOutBack;

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
