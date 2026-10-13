import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Estados de ánimo de Presidente Miau. Cada uno mapea a una imagen.
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

/// Presidente Miau como "personaje": muestra la pose según el contexto y
/// aparece con una animación sutil (escala + leve flotación) para dar vida.
///
/// Las imágenes de pose (PNG con fondo transparente) se guardan en
/// assets/images/. Mientras no existan, se usa la imagen base (recortada).
class MiauCharacter extends StatefulWidget {
  final MiauMood mood;
  final double size;
  final bool float; // flotación continua sutil

  const MiauCharacter({
    super.key,
    this.mood = MiauMood.neutral,
    this.size = 96,
    this.float = true,
  });

  static const String _base = 'assets/images/presidente_prezhome.jpg';

  // Mapa de mood -> ruta de imagen de pose (PNG transparente).
  // neutral usa "saludando" como pose limpia por defecto del personaje.
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

  /// Fotogramas del saludo (parpadea y mueve la pata). Mismo encuadre.
  static final List<String> _greetingFrames = [
    for (var i = 1; i <= 12; i++) 'assets/images/miau_saludo_$i.png',
  ];

  @override
  State<MiauCharacter> createState() => _MiauCharacterState();
}

class _MiauCharacterState extends State<MiauCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _floatCtrl;
  // Ciclo del saludo: los 4 fotogramas al principio y luego quieto.
  late final AnimationController _frameCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  bool get _animatesFrames => widget.mood == MiauMood.greeting;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.float) _floatCtrl.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animatesFrames) return;
    for (final f in MiauCharacter._greetingFrames) {
      precacheImage(AssetImage(f), context);
    }
    if (AppMotion.reduceMotionOf(context)) {
      _frameCtrl.stop();
    } else if (!_frameCtrl.isAnimating) {
      _frameCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _frameCtrl.dispose();
    _entry.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posePath = MiauCharacter._poseAssets[widget.mood];
    final scale = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);

    // Poses = PNG transparente -> se muestran limpias (contain, sin recorte).
    // Base = foto .jpg -> se recorta en cuadrado redondeado.
    final Widget image = _animatesFrames
        ? AnimatedBuilder(
            animation: _frameCtrl,
            builder: (context, _) {
              // Cada fotograma dura 3,5 % del ciclo (~110 ms); el resto, el 1.º.
              final i = (_frameCtrl.value / 0.035).floor();
              final frames = MiauCharacter._greetingFrames;
              return Image.asset(
                frames[i < frames.length ? i : 0],
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stack) => _baseImage(),
              );
            },
          )
        : posePath != null
        ? Image.asset(
            posePath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => _baseImage(),
          )
        : _baseImage();

    return AnimatedBuilder(
      animation: Listenable.merge([_entry, _floatCtrl]),
      builder: (context, child) {
        final floatOffset = widget.float
            ? (0.5 - (_floatCtrl.value - 0.5).abs()) * 8
            : 0.0;
        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.scale(scale: scale.value, child: child),
        );
      },
      child: image,
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
