import 'package:flutter/material.dart';

import '../inventory_screen.dart';
import '../shopping_list_screen.dart';
import '../theme/app_theme.dart';

/// Pestaña "Despensa": agrupa lo que hay en casa y lo que falta por comprar,
/// como hacen las apps de nevera/despensa. Tiene dos sub-tabs: Inventario
/// (Despensa/Nevera/Congelador) y Compra (lista de la compra).
class DespensaTab extends StatelessWidget {
  const DespensaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Despensa'),
          bottom: const TabBar(
            indicatorColor: AppColors.woodDark,
            labelColor: AppColors.ink,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Inventario', icon: Icon(Icons.kitchen)),
              Tab(text: 'Compra', icon: Icon(Icons.shopping_cart_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Cada pantalla trae su propio contenido y botón flotante.
            _EmbeddedInventory(),
            _EmbeddedShopping(),
          ],
        ),
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
