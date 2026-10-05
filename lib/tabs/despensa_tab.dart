import 'package:flutter/material.dart';

import '../inventory_screen.dart';
import '../shopping_list_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/miau_character.dart';

/// Pestaña "Despensa": agrupa lo que hay en casa y lo que falta por comprar,
/// como hacen las apps de nevera/despensa. Tiene dos sub-tabs: Inventario
/// (Despensa/Nevera/Congelador) y Compra (lista de la compra).
class DespensaTab extends StatelessWidget {
  /// Sub-tab inicial: 0 = Inventario (por defecto), 1 = Compra.
  final int initialTab;
  const DespensaTab({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Despensa'),
          bottom: const TabBar(
            indicatorColor: AppColors.woodDark,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.inkMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'En casa', icon: Icon(Icons.kitchen_outlined)),
              Tab(text: 'Compra', icon: Icon(Icons.shopping_cart_outlined)),
            ],
          ),
        ),
        body: Column(
          children: const [
            _DespensaHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  // Cada pantalla trae su propio contenido y botón flotante.
                  _EmbeddedInventory(),
                  _EmbeddedShopping(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera cozy con Miau para dar presencia de la mascota en la sección.
/// Miau trae su propia animación de entrada y flotación suave.
class _DespensaHeader extends StatelessWidget {
  const _DespensaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        elevation: 1,
        color: AppColors.peachBg,
      ),
      child: Row(
        children: [
          const MiauCharacter(mood: MiauMood.cooking, size: 60),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lo que hay en casa', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Revisa existencias, caducidades y tu próxima compra.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Envolvemos las pantallas existentes para reutilizarlas dentro de las tabs.
class _EmbeddedInventory extends StatelessWidget {
  const _EmbeddedInventory();
  @override
  Widget build(BuildContext context) => const InventoryScreen(embedded: true);
}

class _EmbeddedShopping extends StatelessWidget {
  const _EmbeddedShopping();
  @override
  Widget build(BuildContext context) =>
      const ShoppingListScreen(embedded: true);
}
