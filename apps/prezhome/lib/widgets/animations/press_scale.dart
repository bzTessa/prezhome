import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';
import 'spring_value.dart';

/// Envoltorio que da feedback táctil al pulsar: encoge sutilmente su [child]
/// (1.0 → ~0.96) desde que el dedo toca y vuelve al soltar con un muelle.
///
/// Pensado para botones de acceso rápido y tarjetas pulsables. Propaga el
/// gesto mediante [onTap] sin romper taps existentes.
///
/// Respeta "reducir movimiento": si [AppMotion.reduceMotionOf] es `true` no
/// escala (se queda en 1.0) pero SIGUE invocando [onTap].
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Escala a la que encoge al pulsar (1.0 = sin cambio). Por defecto 0.96.
  final double pressedScale;

  /// Comportamiento de detección de toques del [GestureDetector] interno.
  final HitTestBehavior behavior;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Encoge en cuanto el dedo toca (pointer-down, sin esperar al tap) y
    // vuelve con un muelle con rebote. Con reduce-motion no escala nunca.
    final bool reduceMotion = AppMotion.reduceMotionOf(context);
    final double scale = (!reduceMotion && _pressed)
        ? widget.pressedScale
        : 1.0;

    return Listener(
      behavior: widget.behavior,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: SpringValue(
          value: scale,
          spring: AppMotion.fluidBouncy,
          builder: (context, s, child) =>
              Transform.scale(scale: s, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}
