import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Texto del aviso sin conexión: qué sigue funcionando y qué pasa al volver.
const String kOfflineExplanation =
    'Puedes seguir usando la lista de la compra y la despensa: lo que apuntes '
    'se guarda en el móvil y se envía solo cuando vuelva. Lo demás se '
    'actualizará entonces.';

/// Aviso fijo arriba del shell cuando el servidor no responde, o cuando hay un
/// aviso de incidencias publicado. Sin rojos de error: es informativo.
class OfflineBanner extends StatelessWidget {
  /// `false` si el servidor no responde.
  final bool online;

  /// Aviso de incidencias publicado (o `null`).
  final String? notice;

  const OfflineBanner({super.key, required this.online, this.notice});

  @override
  Widget build(BuildContext context) {
    if (online && notice == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.goldBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.stroke, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              online ? Icons.campaign_outlined : Icons.cloud_off_outlined,
              size: 20,
              color: AppColors.ink,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!online)
                    Text(
                      'Sin conexión ahora mismo',
                      style: AppTextStyles.label,
                    ),
                  if (notice != null)
                    Padding(
                      padding: EdgeInsets.only(top: online ? 0 : 2),
                      child: Text(
                        notice!,
                        style: online
                            ? AppTextStyles.label
                            : AppTextStyles.bodyMuted,
                      ),
                    ),
                  if (!online)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        kOfflineExplanation,
                        style: AppTextStyles.bodyMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
