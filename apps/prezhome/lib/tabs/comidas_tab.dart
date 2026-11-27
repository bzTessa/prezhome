import 'package:flutter/material.dart';

import '../food_diary_screen.dart';
import '../l10n/l10n.dart';
import '../meal_plan_screen.dart';
import '../recipes_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/app_transitions.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/warm_tab_header.dart';

/// Claves de sub-pestaña visibles en [ComidasTab] según si está activo el
/// diario de calorías. Lógica pura reutilizable en UI y tests.
List<String> comidasSubTabKeys(bool showDiary) => [
  'plan',
  'recipes',
  if (showDiary) 'diary',
];

/// Clampa un índice de sub-pestaña al rango válido actual de [ComidasTab].
int clampComidasSubTab(int index, {required bool showDiary}) =>
    index.clamp(0, showDiary ? 2 : 1);

/// Pestaña "Comidas": agrupa Plan semanal, Recetas y (si está activado en las
/// preferencias de calorías) Diario en la misma pastilla segmentada que
/// [CompraTab], evitando conflictos de gestos horizontales.
class ComidasTab extends StatefulWidget {
  const ComidasTab({
    super.key,
    this.initialSubTab = 0,
    this.showDiary = true,
    this.tabBuilder,
  });

  final int initialSubTab;
  final bool showDiary;

  /// Constructor opcional de cada sub-vista (índice 0=Plan, 1=Recetas, 2=Diario),
  /// útil para pruebas sin inicializar Supabase.
  final Widget Function(BuildContext context, int index)? tabBuilder;

  @override
  State<ComidasTab> createState() => ComidasTabState();
}

class ComidasTabState extends State<ComidasTab> {
  late int _subTab = clampComidasSubTab(
    widget.initialSubTab,
    showDiary: widget.showDiary,
  );
  final Set<int> _opened = {};

  int get currentSubTab => _subTab;

  @override
  void didUpdateWidget(ComidasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      showSubTab(widget.initialSubTab);
    } else if (oldWidget.showDiary != widget.showDiary) {
      final clamped = clampComidasSubTab(_subTab, showDiary: widget.showDiary);
      if (clamped != _subTab) {
        _subTab = clamped;
        _opened.add(_subTab);
      }
    }
  }

  /// Cambia entre Plan (0), Recetas (1) y Diario (2, si está visible).
  void showSubTab(int index) {
    final next = clampComidasSubTab(index, showDiary: widget.showDiary);
    if (next == _subTab && _opened.contains(next)) return;
    setState(() {
      _subTab = next;
      _opened.add(next);
    });
  }

  Widget _buildChild(BuildContext context, int index) {
    if (widget.tabBuilder != null) return widget.tabBuilder!(context, index);
    return switch (index) {
      0 => const MealPlanScreen(embedded: true),
      1 => const RecipesScreen(embedded: true),
      _ => const FoodDiaryScreen(embedded: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final keys = comidasSubTabKeys(widget.showDiary);
    final safeIndex = clampComidasSubTab(_subTab, showDiary: widget.showDiary);
    _opened.add(safeIndex);

    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            WarmTabHeader(title: context.l.tabLabel('comidas')),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SegmentedPill(
                labels: [for (final k in keys) context.l.comidasTab(k)],
                selected: safeIndex,
                onChanged: showSubTab,
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: safeIndex,
                children: [
                  for (var i = 0; i < keys.length; i++)
                    TickerMode(
                      enabled: safeIndex == i,
                      child: _opened.contains(i)
                          ? FadeInOnActivate(
                              active: safeIndex == i,
                              child: _buildChild(context, i),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
