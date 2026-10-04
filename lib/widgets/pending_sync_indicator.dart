import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Indicador DISCRETO y cozy de "cambios por sincronizar" (Paso 7).
///
/// Aparece como una pastilla suave cuando hay cambios guardados en el
/// dispositivo que todavía no se han enviado al servidor (p. ej. porque la
/// usuaria está en el súper sin cobertura). Desaparece sola en cuanto la cola
/// se vacía al volver la conexión.
///
/// Diseño (steering design-system):
/// - Radio 16 ([AppRadius.md]) y superficie [AppTheme.surfaceDecoration].
/// - Tonos cozy: [AppColors.inkMuted] para el texto, sin rojos de error.
/// - Texto CERCANO y sin tecnicismos (nada de "cola", "sync" ni "IA").
/// - Honra "reducir movimiento": con [AppMotion.reduceMotionOf] en `true` se
///   muestra ESTÁTICO (sin el pulso suave del icono).
class PendingSyncIndicator extends StatefulWidget {
  /// Número de cambios pendientes de sincronizar. Si es 0, no se pinta nada.
  final int pendingCount;

  const PendingSyncIndicator({super.key, required this.pendingCount});

  @override
  State<PendingSyncIndicator> createState() => _PendingSyncIndicatorState();
}

class _PendingSyncIndicatorState extends State<PendingSyncIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Pulso MUY suave del iconito (ida y vuelta) para sugerir "en camino" sin
    // distraer. Se detiene si el sistema pide reducir movimiento (se gestiona
    // en build/didChangeDependencies).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationWithMotionPref();
  }

  void _syncAnimationWithMotionPref() {
    final reduceMotion = AppMotion.reduceMotionOf(context);
    if (reduceMotion) {
      // Estado estático: paramos el bucle y dejamos el icono asentado.
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingCount <= 0) return const SizedBox.shrink();
    final reduceMotion = AppMotion.reduceMotionOf(context);

    final icon = Icon(
      Icons.cloud_upload_outlined,
      size: 18,
      color: AppColors.inkMuted,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: AppTheme.surfaceDecoration(radius: AppRadius.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reduceMotion)
                icon
              else
                FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.45,
                    end: 1,
                  ).animate(_controller),
                  child: icon,
                ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Guardado. Se sincronizará al volver la conexión.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
