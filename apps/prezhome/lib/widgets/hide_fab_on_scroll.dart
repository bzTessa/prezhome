import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_motion.dart';

/// Esconde el botón flotante al bajar por la lista y lo enseña al subir.
/// Si no, tapa lo que pasa por debajo (Cena en el plan, los puntos en
/// Tareas, un producto en la Despensa).
///
/// Se pone alrededor del Scaffold, y el botón va dentro de
/// [HideFabOnScroll.fab].
class HideFabOnScroll extends StatefulWidget {
  const HideFabOnScroll({super.key, required this.child});

  final Widget child;

  /// El botón, que se aparta hacia abajo mientras se baja por la lista.
  static Widget fab(Widget child) => _HidingFab(child: child);

  @override
  State<HideFabOnScroll> createState() => _HideFabOnScrollState();
}

class _HideFabOnScrollState extends State<HideFabOnScroll> {
  final ValueNotifier<bool> _visible = ValueNotifier(true);

  @override
  void dispose() {
    _visible.dispose();
    super.dispose();
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.direction == ScrollDirection.reverse) {
      _visible.value = false;
    } else if (n.direction == ScrollDirection.forward) {
      _visible.value = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => _FabVisibility(
    notifier: _visible,
    child: NotificationListener<UserScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    ),
  );
}

class _FabVisibility extends InheritedNotifier<ValueNotifier<bool>> {
  const _FabVisibility({required super.notifier, required super.child});
}

class _HidingFab extends StatelessWidget {
  const _HidingFab({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FabVisibility>();
    final visible = scope?.notifier?.value ?? true;
    final duration = AppMotion.effectiveDuration(
      AppMotion.normal,
      reduceMotion: AppMotion.reduceMotionOf(context),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 2),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          child: child,
        ),
      ),
    );
  }
}
