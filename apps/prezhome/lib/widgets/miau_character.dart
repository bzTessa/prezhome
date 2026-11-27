import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_motion.dart';

/// Estados de ánimo de la mascota. Cada uno mapea a una imagen.
/// Si aún no tienes la imagen específica, cae a la imagen por defecto.
enum MiauMood {
  greeting,
  celebrating,
  sleeping,
  cooking,
  curious,
  shopping,
  worried,
  neutral,
}

/// La mascota como elemento gráfico limpio: muestra la ilustración según el
/// contexto, cambia de pose con transición suave y responde al toque cuando
/// [interactive] es true.
///
/// [float] y [showEffects] se conservan por compatibilidad con llamadas
/// existentes, evitando movimientos continuos o partículas dibujadas encima.
class MiauCharacter extends StatefulWidget {
  final MiauMood mood;
  final double size;
  final bool float;
  final bool interactive;
  final bool showEffects;
  final VoidCallback? onTap;

  const MiauCharacter({
    super.key,
    this.mood = MiauMood.neutral,
    this.size = 96,
    this.float = true,
    this.interactive = false,
    this.showEffects = true,
    this.onTap,
  });

  static const String _base = 'assets/images/presidente_prezhome.jpg';

  static const Map<MiauMood, String> _poseAssets = {
    MiauMood.greeting: 'assets/images/miau_saludando.png',
    MiauMood.celebrating: 'assets/images/miau_celebrando.png',
    MiauMood.sleeping: 'assets/images/miau_durmiendo.png',
    MiauMood.cooking: 'assets/images/miau_cocinando.png',
    MiauMood.curious: 'assets/images/miau_pensando.png',
    MiauMood.shopping: 'assets/images/miau_comprando.png',
    MiauMood.worried: 'assets/images/miau_triste.png',
    MiauMood.neutral: 'assets/images/miau_saludando.png',
  };

  @override
  State<MiauCharacter> createState() => _MiauCharacterState();
}

class _MiauCharacterState extends State<MiauCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _tapScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.91,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.91,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 60,
    ),
  ]).animate(_tap);

  void _onTap() {
    HapticFeedback.lightImpact();
    if (!AppMotion.reduceMotionOf(context)) {
      _tap.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotionOf(context);
    final posePath = MiauCharacter._poseAssets[widget.mood];
    final image = KeyedSubtree(
      key: ValueKey(widget.mood),
      child: posePath != null
          ? Image.asset(
              posePath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => _baseImage(),
            )
          : _baseImage(),
    );

    final Widget switcher = AnimatedSwitcher(
      duration: AppMotion.effectiveDuration(
        AppMotion.normal,
        reduceMotion: reduce,
      ),
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: image,
    );

    final Widget body = SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.interactive
          ? ScaleTransition(scale: _tapScale, child: switcher)
          : switcher,
    );

    if (!widget.interactive) return body;
    return Semantics(
      button: true,
      label: context.l.mascot,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: body,
      ),
    );
  }

  Widget _baseImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size * 0.28),
      child: Image.asset(
        MiauCharacter._base,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      ),
    );
  }
}
