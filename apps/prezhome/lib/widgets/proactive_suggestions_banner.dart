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
/// Usa tokens de AppColors/AppRadius y la mascota "pensando", quieta y
/// dentro de la tarjeta.
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
        'Aprovéchalos en tu próxima cocina en lote.';
  }

  @override
  Widget build(BuildContext context) {
    // Tarjeta táctil compacta (una fila) con la mascota quieta DENTRO de la
    // tarjeta: asomada por arriba y flotando quedaba descolocada. Toda la
    // tarjeta lleva a Comidas.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: AppTheme.tactileDecoration(
          radius: AppRadius.md,
          borderWidth: 2,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
              child: Row(
                children: [
                  const MiauCharacter(
                    mood: MiauMood.curious,
                    size: 40,
                    float: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consejo del día',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.terracottaText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          bannerMessage(suggestions),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                  IconButton(
                    tooltip: 'Descartar',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
