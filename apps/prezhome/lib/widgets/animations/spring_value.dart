import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// Anima un número hacia [value] con un muelle físico.
///
/// Es interrumpible: si [value] cambia a mitad de camino, el muelle sale
/// desde donde está y con la velocidad que lleva (no salta ni reinicia).
/// Con "reducir movimiento" va directo al valor final.
class SpringValue extends StatefulWidget {
  const SpringValue({
    super.key,
    required this.value,
    required this.builder,
    this.spring,
    this.from,
    this.child,
  });

  final double value;

  /// Muelle a usar; por defecto [AppMotion.fluidDefault].
  final SpringDescription? spring;

  /// Valor inicial al montarse (por defecto, [value]: sin animar la entrada).
  final double? from;

  final ValueWidgetBuilder<double> builder;
  final Widget? child;

  @override
  State<SpringValue> createState() => _SpringValueState();
}

class _SpringValueState extends State<SpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: widget.from ?? widget.value,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value != widget.value && !_c.isAnimating) _go();
  }

  @override
  void didUpdateWidget(SpringValue old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _go();
  }

  void _go() {
    if (AppMotion.reduceMotionOf(context)) {
      _c.value = widget.value;
      return;
    }
    _c.animateWith(
      SpringSimulation(
        widget.spring ?? AppMotion.fluidDefault,
        _c.value,
        widget.value,
        _c.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => widget.builder(context, _c.value, child),
    child: widget.child,
  );
}

/// Escala de un "pop" para un muelle que va de 0 a 1: empieza en [rest],
/// crece hasta ~[peak] a mitad de camino y se asienta en 1.
double popScale(double t, {double rest = 1, double peak = 1.2}) {
  final base = rest + (1 - rest) * t;
  // t·(1−t) vale 0.25 en el centro: el pico queda en base + bulge/4.
  final bulge = 4 * (peak - (rest + 1) / 2);
  return base + bulge * t * (1 - t);
}
