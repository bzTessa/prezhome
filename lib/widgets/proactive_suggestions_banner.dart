import 'package:flutter/material.dart';

import '../services/proactive_suggestions_service.dart';
import '../theme/app_theme.dart';
import 'miau_character.dart';

/// Banner cozy y DESCARTABLE del "Asistente Proactivo" (motor LOCAL, sin IA):
/// aparece sobre el body del shell cuando hay alimentos a punto de caducar
/// (<= 2 días) y propone aprovecharlos en el próximo Batch Cooking / Modo
/// cocina.
///
/// Es presentación pura: recibe las sugerencias ya calculadas por
/// [buildExpiringSuggestions] (FEAT-002) y dos callbacks (acción y descartar).
/// Usa tokens de AppColors/AppRadius y Miau "proponiendo" (MiauMood.curious).
/// Honra reduce-motion desactivando la flotación de Miau.
class ProactiveSuggestionsBanner extends StatelessWidget {
  /// Sugerencias de caducidad ya calculadas (no vacías cuando se muestra).
  final List<ExpiringSuggestion> suggestions;

  /// Acción del botón: lleva a la pestaña Comidas, donde vive el plan.
  final VoidCallback onAction;

  /// Descarta el banner (oculta hasta la próxima recarga del shell).
  final VoidCallback onDismiss;

  const ProactiveSuggestionsBanner({
    super.key,
    required this.suggestions,
    required this.onAction,
    required this.onDismiss,
  });

  /// Texto principal del banner: si hay una sola sugerencia, usa su mensaje
  /// cercano; si hay varias, un resumen honesto sin la palabra "IA".
  static String bannerMessage(List<ExpiringSuggestion> suggestions) {
    if (suggestions.isEmpty) return '';
    if (suggestions.length == 1) return suggestions.first.message;
    return '${suggestions.length} alimentos a punto de caducar. '
        'Aprovéchalos en tu próximo Batch Cooking.';
  }

  @override
  Widget build(BuildContext context) {
    // Reduce-motion: si el sistema pide menos animaciones, Miau no flota.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: AppTheme.surfaceDecoration(
          radius: AppRadius.md,
          elevation: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MiauCharacter(
              mood: MiauMood.curious,
              size: 48,
              float: !reduceMotion,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Miau te propone',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bannerMessage(suggestions),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.soonBg,
                        foregroundColor: AppColors.soon,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      // El botón navega a la pestaña Comidas (ahí vive el plan
                      // y el acceso al Modo cocina), así que la etiqueta es
                      // honesta con el destino real.
                      child: const Text(
                        'Ir a Comidas',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // X para descartar el banner.
            IconButton(
              tooltip: 'Descartar',
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.woodDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
