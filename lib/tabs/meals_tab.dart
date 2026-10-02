import 'package:flutter/material.dart';

import '../recipes_screen.dart';
import '../inventory_screen.dart';
import '../shopping_list_screen.dart';
import '../theme/app_theme.dart';

/// Pestaña "Comidas": agrupa Recetas, Despensa/Nevera/Congelador (Inventario)
/// y la Lista de la compra.
class MealsTab extends StatelessWidget {
  const MealsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Comidas'),
          bottom: const TabBar(
            indicatorColor: AppColors.woodDark,
            labelColor: AppColors.ink,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Recetas', icon: Icon(Icons.restaurant_menu)),
              Tab(text: 'Despensa', icon: Icon(Icons.kitchen)),
              Tab(text: 'Compra', icon: Icon(Icons.shopping_cart_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Cada pantalla trae su propio contenido y botón flotante.
            _EmbeddedRecipes(),
            _EmbeddedInventory(),
            _EmbeddedShopping(),
          ],
        ),
      ),
    );
  }
}

// Envolvemos las pantallas existentes para reutilizarlas dentro de las tabs.
class _EmbeddedRecipes extends StatelessWidget {
  const _EmbeddedRecipes();
  @override
  Widget build(BuildContext context) => const RecipesScreen(embedded: true);
}

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
