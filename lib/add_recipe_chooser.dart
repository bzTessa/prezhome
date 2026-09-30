import 'package:flutter/material.dart';

import 'add_recipe_screen.dart';
import 'discover_recipes_screen.dart';
import 'theme/app_theme.dart';

/// Hoja para elegir cómo añadir una receta:
///  - Manual: formulario vacío
///  - Escribir receta deseada: pega/describe y la IA la completa
///  - Ideas personalizadas: la IA propone recetas según tus parámetros
class AddRecipeChooser extends StatelessWidget {
  const AddRecipeChooser({super.key});

  /// Devuelve true si se creó/guardó alguna receta (para recargar la lista).
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AddRecipeChooser(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Añadir receta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _option(
              context,
              icon: Icons.auto_awesome,
              title: 'Escribir receta deseada',
              subtitle:
                  'Pega o describe la receta y la IA la completa con macros, '
                  'ingredientes y pasos.',
              onTap: () async {
                final r = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AddRecipeScreen(startWithAI: true),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop(r);
              },
            ),
            _option(
              context,
              icon: Icons.storefront_outlined,
              title: 'Ideas personalizadas',
              subtitle:
                  'Elige supermercado, objetivo, dieta y presupuesto, y la IA '
                  'te propone ideas de recetas.',
              onTap: () async {
                final r = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const DiscoverRecipesScreen(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop(r);
              },
            ),
            _option(
              context,
              icon: Icons.edit_note,
              title: 'Introducir manualmente',
              subtitle: 'Rellena tú la receta paso a paso, sin IA.',
              onTap: () async {
                final r = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
                );
                if (context.mounted) Navigator.of(context).pop(r);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.wood,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
