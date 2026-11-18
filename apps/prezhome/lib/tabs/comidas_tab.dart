import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../food_diary_screen.dart';
import '../main_shell.dart';
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
          title: Text(context.l.meals),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              // Selector en pastilla, como en el concepto (antes, una raya
              // bajo la pestaña activa que se leía como un fallo de dibujo).
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.iconTile,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.ink,
                  unselectedLabelColor: AppColors.inkMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  splashBorderRadius: AppRadius.pillRadius,
                  tabs: [
                    Tab(text: context.l.comidasTab('plan')),
                    Tab(text: context.l.comidasTab('recipes')),
                    Tab(text: context.l.comidasTab('diary')),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const _SwipeToShell(
          child: TabBarView(
            children: [
              // Cada pantalla trae su propio contenido y botón flotante.
              MealPlanScreen(embedded: true),
              _EmbeddedRecipes(),
              _EmbeddedDiary(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deslizar más allá de Plan (a la derecha) o de Diario (a la izquierda) pasa
/// a la pestaña de al lado de la app: si no, las sub-pestañas se quedaban el
/// gesto y desde Comida no se podía ir a Hoy ni a Compra deslizando.
class _SwipeToShell extends StatefulWidget {
  const _SwipeToShell({required this.child});

  final Widget child;

  @override
  State<_SwipeToShell> createState() => _SwipeToShellState();
}

class _SwipeToShellState extends State<_SwipeToShell> {
  double _over = 0;
  bool _done = false;

  bool _onNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.horizontal || n.depth != 0) return false;
    if (n is ScrollStartNotification) {
      _over = 0;
      _done = false;
    } else if (n is OverscrollNotification && n.dragDetails != null) {
      // Android: el borde se nota como overscroll.
      _over += n.overscroll;
    } else if (n is ScrollUpdateNotification && n.dragDetails != null) {
      // iOS: rebota, así que se mira cuánto se pasa del borde.
      final m = n.metrics;
      if (m.pixels < m.minScrollExtent) _over = m.pixels - m.minScrollExtent;
      if (m.pixels > m.maxScrollExtent) _over = m.pixels - m.maxScrollExtent;
    }
    if (n is OverscrollNotification || n is ScrollUpdateNotification) {
      if (!_done && _over.abs() > 48) {
        _done = true;
        context.findAncestorStateOfType<MainShellState>()?.stepTab(
          _over > 0 ? 1 : -1,
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: widget.child,
      );
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
