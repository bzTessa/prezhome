import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

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

  /// Solo se enseña si los cambios siguen sin subir pasado un rato: con
  /// conexión se suben en menos de un segundo y la pastilla aparecía y
  /// desaparecía tras cada toque.
  static const _delay = Duration(seconds: 3);
  Timer? _timer;
  bool _visible = false;

  void _syncVisibility() {
    if (widget.pendingCount <= 0) {
      _timer?.cancel();
      _timer = null;
      _visible = false;
    } else if (!_visible && _timer == null) {
      _timer = Timer(_delay, () {
        _timer = null;
        if (mounted && widget.pendingCount > 0) setState(() => _visible = true);
      });
    }
  }

  @override
  void didUpdateWidget(PendingSyncIndicator old) {
    super.didUpdateWidget(old);
    _syncVisibility();
  }

  @override
  void initState() {
    super.initState();
    _syncVisibility();
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
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingCount <= 0 || !_visible) return const SizedBox.shrink();
    final reduceMotion = AppMotion.reduceMotionOf(context);

    final icon = Icon(
      Icons.cloud_upload_outlined,
      size: 18,
      color: AppColors.inkMuted,
    );

    return Align(
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
            Flexible(
              child: Text(
                context.l.syncSaved,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
