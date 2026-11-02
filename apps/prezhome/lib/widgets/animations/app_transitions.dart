import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Transición de página de la app: la nueva pantalla entra con un fundido y
/// un pequeño deslizamiento hacia arriba; la de debajo se apaga un poco.
/// En iOS se mantiene la de Cupertino (deslizar para volver).
/// Con "reducir movimiento" la pantalla aparece sin animar.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduceMotionOf(context)) return child;
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(secondaryAnimation),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(enter),
          child: child,
        ),
      ),
    );
  }
}

/// Feedback de pulsación para los botones Material (vía tema): el contenido
/// se hunde un poco mientras se mantiene pulsado y vuelve al soltar.
Widget pressFeedbackBuilder(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final reduce = AppMotion.reduceMotionOf(context);
  return AnimatedScale(
    scale: !reduce && states.contains(WidgetState.pressed) ? 0.93 : 1,
    duration: AppMotion.fast,
    curve: AppMotion.easeOut,
    child: child,
  );
}

/// [FutureBuilder] que funde el esqueleto de carga con el contenido real en
/// vez de cambiarlo de golpe. Se usa igual que un FutureBuilder.
class FadeFutureBuilder<T> extends StatelessWidget {
  const FadeFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
  });

  final Future<T>? future;
  final AsyncWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.effectiveDuration(
      AppMotion.base,
      reduceMotion: AppMotion.reduceMotionOf(context),
    );
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) => AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.easeOut,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        // Solo cambia de clave al pasar de "cargando" a "datos/error", así
        // las recargas posteriores no vuelven a hacer el fundido.
        child: KeyedSubtree(
          key: ValueKey(snapshot.hasData || snapshot.hasError),
          child: builder(context, snapshot),
        ),
      ),
    );
  }
}

/// Aparición suave (fundido + leve subida) cada vez que [active] pasa a
/// `true`, sin reconstruir [child]: conserva su estado. Para el cambio de
/// pestaña de la barra inferior.
class FadeInOnActivate extends StatefulWidget {
  const FadeInOnActivate({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<FadeInOnActivate> createState() => _FadeInOnActivateState();
}

class _FadeInOnActivateState extends State<FadeInOnActivate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: AppMotion.easeOut,
  );

  @override
  void didUpdateWidget(FadeInOnActivate old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !AppMotion.reduceMotionOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.015),
        end: Offset.zero,
      ).animate(_curve),
      child: widget.child,
    ),
  );
}
