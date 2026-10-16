import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

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

/// La mascota como elemento gráfico: muestra la pose según el contexto (solo
/// imágenes estáticas; el movimiento son transformaciones).
///
/// - Entra con una escala suave.
/// - [float]: respira flotando ±3 px en ciclos de 2,2 s, apoyada en la base.
/// - Al cambiar de [mood] da un saltito elástico con "squish".
/// - [interactive]: al tocarla se aplasta, vibra y suelta un corazón.
///
/// Nunca lleva texto con su nombre: es apoyo visual de avisos y consejos.
class MiauCharacter extends StatefulWidget {
  final MiauMood mood;
  final double size;
  final bool float; // flotación continua sutil

  /// Responde al toque (no usar dentro de algo que ya se pulsa).
  final bool interactive;

  const MiauCharacter({
    super.key,
    this.mood = MiauMood.neutral,
    this.size = 96,
    this.float = true,
    this.interactive = false,
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

  @override
  State<MiauCharacter> createState() => _MiauCharacterState();
}

class _MiauCharacterState extends State<MiauCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  /// Saltito al cambiar de estado (0 → 1).
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Aplastón al tocar y corazón que sube (0 → 1).
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.float && !AppMotion.reduceMotionOf(context);
    if (animate && !_floatCtrl.isAnimating) {
      _floatCtrl.repeat();
    } else if (!animate) {
      _floatCtrl.stop();
    }
  }

  @override
  void didUpdateWidget(MiauCharacter old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood && !AppMotion.reduceMotionOf(context)) {
      _jump.forward(from: 0);
    }
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (!AppMotion.reduceMotionOf(context)) _tap.forward(from: 0);
  }

  @override
  void dispose() {
    _entry.dispose();
    _floatCtrl.dispose();
    _jump.dispose();
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posePath = MiauCharacter._poseAssets[widget.mood];
    final entry = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);

    // Poses = PNG transparente -> se muestran limpias (contain, sin recorte).
    // Base = foto .jpg -> se recorta en cuadrado redondeado.
    final Widget image = posePath != null
        ? Image.asset(
            posePath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => _baseImage(),
          )
        : _baseImage();

    final Widget body = AnimatedBuilder(
      animation: Listenable.merge([_entry, _floatCtrl, _jump, _tap]),
      builder: (context, child) {
        final breath = _floatCtrl.isAnimating
            ? math.sin(_floatCtrl.value * 2 * math.pi)
            : 0.0;
        // Salto: sube y baja en un arco; al aterrizar se aplasta un poco.
        final j = _jump.value;
        final jumpY = _jump.isAnimating ? -10 * math.sin(math.pi * j) : 0.0;
        final squash =
            (_jump.isAnimating ? 0.12 * math.sin(2 * math.pi * j) : 0.0) +
            (_tap.isAnimating ? 0.14 * math.sin(math.pi * _tap.value) : 0.0);
        return Transform.translate(
          offset: Offset(0, -3 * breath + jumpY),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(
              entry.value * (1 + squash),
              entry.value * (1 - squash + 0.015 * breath),
              1,
            ),
            child: child,
          ),
        );
      },
      child: image,
    );

    if (!widget.interactive) return body;
    return Semantics(
      button: true,
      label: 'Mascota',
      child: GestureDetector(
        onTap: _onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            body,
            // Corazón que sube y se desvanece tras el toque.
            AnimatedBuilder(
              animation: _tap,
              builder: (context, _) {
                if (!_tap.isAnimating) return const SizedBox.shrink();
                final t = _tap.value;
                return Transform.translate(
                  offset: Offset(widget.size * 0.22, -t * widget.size * 0.35),
                  child: Opacity(
                    opacity: 1 - t,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: widget.size * 0.2,
                      color: AppColors.terracotta,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
