import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prez_ui/prez_ui.dart';

const _items = [
  FloatingNavItem(icon: Icons.today_outlined, label: 'Hoy'),
  FloatingNavItem(icon: Icons.check_circle_outline, label: 'Tareas'),
  FloatingNavItem(icon: Icons.restaurant_menu_outlined, label: 'Meal Prep'),
  FloatingNavItem(icon: Icons.kitchen_outlined, label: 'Despensa'),
  FloatingNavItem(icon: Icons.settings_outlined, label: 'Hogar'),
];

Widget _host({
  required int selected,
  ValueChanged<int>? onSelected,
  FloatingNavAction? action,
  List<FloatingNavItem> items = _items,
}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FloatingNavBar(
          items: items,
          selectedIndex: selected,
          onSelected: onSelected ?? (_) {},
          action: action,
        ),
      ),
    ),
  );
}

Future<void> _setWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('solo la pestaña activa muestra su texto', (tester) async {
    await _setWidth(tester, 412);
    await tester.pumpWidget(_host(selected: 2));
    await tester.pumpAndSettle();

    expect(find.text('Meal Prep'), findsOneWidget);
    expect(find.text('Hoy'), findsNothing);
    expect(find.text('Despensa'), findsNothing);
  });

  testWidgets('tocar una pestaña avisa con su índice', (tester) async {
    await _setWidth(tester, 412);
    int? tapped;
    await tester.pumpWidget(_host(selected: 0, onSelected: (i) => tapped = i));

    await tester.tap(find.byIcon(Icons.kitchen_outlined));
    expect(tapped, 3);
  });

  testWidgets('la pestaña activa se expande al cambiar de selección', (
    tester,
  ) async {
    await _setWidth(tester, 412);
    await tester.pumpWidget(_host(selected: 0));
    await tester.pumpAndSettle();
    final hoyBefore = tester.getSize(find.byIcon(Icons.today_outlined).first);
    final hoyTile = find.ancestor(
      of: find.byIcon(Icons.today_outlined),
      matching: find.byType(AnimatedContainer),
    );
    final wideBefore = tester.getSize(hoyTile.first).width;

    await tester.pumpWidget(_host(selected: 1));
    await tester.pumpAndSettle();

    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Hoy'), findsNothing);
    expect(tester.getSize(hoyTile.first).width, lessThan(wideBefore));
    expect(tester.getSize(find.byIcon(Icons.today_outlined)), hoyBefore);
  });

  testWidgets('el botón de acción es independiente y se puede pulsar', (
    tester,
  ) async {
    await _setWidth(tester, 412);
    var pressed = 0;
    await tester.pumpWidget(
      _host(
        selected: 0,
        action: FloatingNavAction(
          icon: Icons.add,
          tooltip: 'Añadir',
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    expect(pressed, 1);
    expect(find.bySemanticsLabel('Añadir'), findsOneWidget);
  });

  testWidgets('expone cada pestaña a lectores de pantalla', (tester) async {
    await _setWidth(tester, 412);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(selected: 0));

    for (final item in _items) {
      expect(find.bySemanticsLabel(item.label), findsOneWidget);
    }
    semantics.dispose();
  });

  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('no desborda a ${width.toInt()} px con 5 pestañas y botón', (
      tester,
    ) async {
      await _setWidth(tester, width);
      for (var selected = 0; selected < _items.length; selected++) {
        await tester.pumpWidget(
          _host(
            selected: selected,
            action: FloatingNavAction(
              icon: Icons.add,
              tooltip: 'Añadir',
              onPressed: () {},
            ),
          ),
        );
        // Recorre también los fotogramas intermedios de la animación.
        for (var f = 0; f < 10; f++) {
          await tester.pump(const Duration(milliseconds: 30));
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
