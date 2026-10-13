import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_recipe_screen.dart';
import 'discover_recipes_screen.dart';
import 'services/recipe_share.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';

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
                  color: AppColors.line,
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
              icon: Icons.edit_rounded,
              title: 'Escribe el nombre',
              subtitle: 'Se completa con ingredientes, pasos y macros',
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
              title: 'Ideas para ti',
              subtitle: 'Según tu súper, objetivo y presupuesto',
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
              title: 'A mano',
              subtitle: 'Rellena tú cada campo',
              onTap: () async {
                final r = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AddRecipeScreen(manual: true),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop(r);
              },
            ),
            _option(
              context,
              icon: Icons.qr_code_2_rounded,
              title: 'Con un código',
              subtitle: 'Guarda una receta que te han compartido',
              onTap: () async {
                final r = await _importWithCode(context);
                if (context.mounted && r) Navigator.of(context).pop(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Pide el código, enseña la receta y la guarda en tu hogar.
  Future<bool> _importWithCode(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Código de la receta'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'ABCD-EFGH'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty || !context.mounted) return false;

    final client = Supabase.instance.client;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final share = RecipeShare(client);
      final shared = await share.fetch(code);
      if (shared == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No hay ninguna receta con ese código')),
        );
        return false;
      }
      if (!context.mounted) return false;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(shared['title'] as String? ?? 'Receta'),
          content: Text(
            '${(shared['ingredients'] as List?)?.length ?? 0} ingredientes. '
            '¿La guardas en tus recetas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (ok != true) return false;
      final profile = await client
          .from('profiles')
          .select('home_id')
          .eq('id', client.auth.currentUser!.id)
          .single();
      await share.import(shared, profile['home_id'] as String);
      messenger.showSnackBar(const SnackBar(content: Text('Receta guardada')));
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
      return false;
    }
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
        borderRadius: BorderRadius.circular(24),
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
                  borderRadius: BorderRadius.circular(16),
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
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
