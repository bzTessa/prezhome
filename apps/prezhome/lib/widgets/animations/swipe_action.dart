import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import 'spring_value.dart';

/// Acción que se lanza deslizando una tarjeta hacia un lado.
class SwipeSide {
  const SwipeSide({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTrigger,
  });

  final IconData icon;
  final Color color;

  /// Nombre de la acción (también para lectores de pantalla).
  final String label;
  final VoidCallback onTrigger;
}

/// Desliza [child] para lanzar una acción, al estilo iOS: la tarjeta sigue al
/// dedo, se vuelve elástica pasado el umbral (rubber-banding), el icono hace
/// un "pop" y vibra al armarse, y al soltar vuelve a su sitio con un muelle
/// que conserva la velocidad del gesto. La tarjeta no desaparece: quien la
/// pinta decide qué pasa con ella.
class SwipeAction extends StatefulWidget {
  const SwipeAction({
    super.key,
    required this.child,
    this.toRight,
    this.toLeft,
    this.threshold = 72,
    this.radius = 14,
  });

  final Widget child;

  /// Acción al deslizar hacia la derecha.
  final SwipeSide? toRight;

  /// Acción al deslizar hacia la izquierda.
  final SwipeSide? toLeft;

  /// Distancia que hay que recorrer para armar la acción.
  final double threshold;
  final double radius;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

/// Desplazamiento que se ve para un arrastre [raw]: libre hasta [limit] y,
/// a partir de ahí, elástico con [AppMotion.rubberBand].
@visibleForTesting
double swipeDisplayOffset(double raw, double limit, double dimension) {
  final a = raw.abs();
  if (a <= limit) return raw;
  return raw.sign * (limit + AppMotion.rubberBand(a - limit, dimension));
}

class _SwipeActionState extends State<SwipeAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  );
  double _raw = 0;
  bool _armed = false;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  SwipeSide? get _side => _offset.value > 0
      ? widget.toRight
      : _offset.value < 0
      ? widget.toLeft
      : null;

  void _update(DragUpdateDetails d, double width) {
    _raw += d.primaryDelta ?? 0;
    if (widget.toRight == null && _raw > 0) _raw = 0;
    if (widget.toLeft == null && _raw < 0) _raw = 0;
    _offset.value = swipeDisplayOffset(_raw, widget.threshold * 1.25, width);
    final armed = _offset.value.abs() >= widget.threshold;
    if (armed != _armed) {
      if (armed) HapticFeedback.mediumImpact();
      setState(() => _armed = armed);
    }
  }

  void _end(DragEndDetails d) {
    final side = _side;
    if (_armed && side != null) side.onTrigger();
    _raw = 0;
    setState(() => _armed = false);
    if (AppMotion.reduceMotionOf(context)) {
      _offset.value = 0;
      return;
    }
    _offset.animateWith(
      SpringSimulation(
        AppMotion.fluidBouncy,
        _offset.value,
        0,
        d.primaryVelocity ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      customSemanticsActions: {
        if (widget.toRight case final s?)
          CustomSemanticsAction(label: s.label): s.onTrigger,
        if (widget.toLeft case final s?)
          CustomSemanticsAction(label: s.label): s.onTrigger,
      },
      child: LayoutBuilder(
        builder: (context, c) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            _offset.stop();
            _raw = _offset.value;
          },
          onHorizontalDragUpdate: (d) => _update(d, c.maxWidth),
          onHorizontalDragEnd: _end,
          onHorizontalDragCancel: () => _end(DragEndDetails()),
          child: AnimatedBuilder(
            animation: _offset,
            child: widget.child,
            builder: (context, child) {
              final dx = _offset.value;
              final side = _side;
              return Stack(
                children: [
                  if (side != null)
                    Positioned.fill(child: _background(side, dx > 0)),
                  Transform.translate(offset: Offset(dx, 0), child: child),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _background(SwipeSide side, bool fromLeft) {
    return Container(
      decoration: BoxDecoration(
        color: side.color,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
      // 0.8 en reposo; al armarse, pop elástico 0.8 → 1.2 → 1.0.
      child: SpringValue(
        value: _armed ? 1 : 0,
        spring: AppMotion.fluidBouncy,
        builder: (context, t, child) =>
            Transform.scale(scale: popScale(t, rest: 0.8), child: child),
        child: Icon(side.icon, color: AppColors.onBrand, size: 28),
      ),
    );
  }
}
