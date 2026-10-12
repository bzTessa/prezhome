import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// Envoltorio que da feedback táctil al pulsar: encoge sutilmente su [child]
/// (1.0 → ~0.96) mientras el dedo está presionado y vuelve al soltar.
///
/// Pensado para botones de acceso rápido y tarjetas pulsables. Propaga el
/// gesto mediante [onTap] sin romper taps existentes.
///
/// Respeta "reducir movimiento": si [AppMotion.reduceMotionOf] es `true` no
/// escala (se queda en 1.0) pero SIGUE invocando [onTap].
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Escala a la que encoge al pulsar (1.0 = sin cambio). Por defecto 0.96.
  final double pressedScale;

  /// Comportamiento de detección de toques del [GestureDetector] interno.
  final HitTestBehavior behavior;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
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
    final bool reduceMotion = AppMotion.reduceMotionOf(context);
    // Con reduce-motion no escalamos nunca; mantenemos el estado final (1.0).
    final double scale = (!reduceMotion && _pressed)
        ? widget.pressedScale
        : 1.0;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.effectiveDuration(
          AppMotion.fast,
          reduceMotion: reduceMotion,
        ),
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
