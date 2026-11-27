import 'package:flutter/material.dart';

import '../inventory_screen.dart';
import '../l10n/l10n.dart';
import '../shopping_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/app_transitions.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/warm_tab_header.dart';

/// Pestaña "Compra": agrupa todo lo que entra y sale de casa en dos sub-vistas
/// ("Lista" y "En casa"), sin competir con el deslizamiento de filas ni del
/// shell principal.
class CompraTab extends StatefulWidget {
  const CompraTab({super.key, this.initialSubTab = 0});

  final int initialSubTab;

  @override
  State<CompraTab> createState() => CompraTabState();
}

class CompraTabState extends State<CompraTab> {
  late int _subTab = widget.initialSubTab.clamp(0, 1);
  final Set<int> _opened = {};

  int get currentSubTab => _subTab;

  @override
  void didUpdateWidget(CompraTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      showSubTab(widget.initialSubTab);
    }
  }

  /// Cambia entre "Lista" (0) y "En casa" (1).
  void showSubTab(int index) {
    final next = index.clamp(0, 1);
    if (next == _subTab && _opened.contains(next)) return;
    setState(() {
      _subTab = next;
      _opened.add(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    _opened.add(_subTab);
    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            WarmTabHeader(title: context.l.tabLabel('compra')),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SegmentedPill(
                labels: [context.l.compraSubList, context.l.compraSubHome],
                selected: _subTab,
                onChanged: showSubTab,
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _subTab,
                children: [
                  TickerMode(
                    enabled: _subTab == 0,
                    child: _opened.contains(0)
                        ? FadeInOnActivate(
                            active: _subTab == 0,
                            child: const ShoppingListScreen(embedded: true),
                          )
                        : const SizedBox.shrink(),
                  ),
                  TickerMode(
                    enabled: _subTab == 1,
                    child: _opened.contains(1)
                        ? FadeInOnActivate(
                            active: _subTab == 1,
                            child: const InventoryScreen(embedded: true),
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
