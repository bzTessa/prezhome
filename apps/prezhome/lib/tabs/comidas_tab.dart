import 'package:flutter/material.dart';

import '../food_diary_screen.dart';
import '../meal_plan_screen.dart';
import '../recipes_screen.dart';
import '../theme/app_theme.dart';

/// Pestaña "Comidas": agrupa todo lo relacionado con comer en un mismo
/// lugar, como hacen las apps de planificación de comidas. Tiene tres
/// sub-tabs: Plan (la semana del hogar, día a día), Recetas (recetario)
/// y Diario (diario de calorías personal).
class ComidasTab extends StatelessWidget {
  const ComidasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Comidas'),
          bottom: TabBar(
            indicatorColor: AppColors.woodDark,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.line,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.inkMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Plan'),
              Tab(text: 'Recetas'),
              Tab(text: 'Diario'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Cada pantalla trae su propio contenido y botón flotante.
            MealPlanScreen(embedded: true),
            _EmbeddedRecipes(),
            _EmbeddedDiary(),
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

class _EmbeddedDiary extends StatelessWidget {
  const _EmbeddedDiary();
  @override
  Widget build(BuildContext context) => const FoodDiaryScreen(embedded: true);
}
