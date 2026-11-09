import 'package:flutter/material.dart';

import '../services/proactive_suggestions_service.dart';
import '../theme/app_theme.dart';
import 'miau_character.dart';

/// Aviso de "caduca pronto" (motor LOCAL, sin IA) en lo alto de Comida: dice
/// QUÉ caduca y CUÁNDO, y lleva a ideas de recetas con lo que hay en casa.
/// Una sola fila compacta; se descarta hasta el día siguiente.
class ProactiveSuggestionsBanner extends StatelessWidget {
  /// Sugerencias de caducidad ya calculadas (no vacías cuando se muestra).
  final List<ExpiringSuggestion> suggestions;

  /// Abre ideas de recetas con lo que hay en la despensa.
  final VoidCallback onAction;

  /// Oculta el aviso hasta mañana.
  final VoidCallback onDismiss;

  const ProactiveSuggestionsBanner({
    super.key,
    required this.suggestions,
    required this.onAction,
    required this.onDismiss,
  });

  /// Título: "Caduca pronto" / "Caducan pronto".
  static String bannerTitle(List<ExpiringSuggestion> suggestions) =>
      suggestions.length == 1 ? 'Caduca pronto' : 'Caducan pronto';

  /// "Leche hoy · Yogur mañana · +3": lo más urgente primero.
  static String bannerMessage(List<ExpiringSuggestion> suggestions) {
    String when(int d) => switch (d) {
      0 => 'hoy',
      1 => 'mañana',
      _ => 'en $d días',
    };
    final shown = [
      for (final s in suggestions.take(2))
        '${s.name} ${when(s.daysUntilExpiry)}',
    ];
    final rest = suggestions.length - shown.length;
    return [...shown, if (rest > 0) '+$rest'].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: AppColors.goldBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                const MiauCharacter(
                  mood: MiauMood.curious,
                  size: 36,
                  float: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bannerTitle(suggestions),
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.restaurant_rounded, size: 16),
                  label: const Text('Ideas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.onBrand,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ocultar hasta mañana',
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
    );
  }
}
