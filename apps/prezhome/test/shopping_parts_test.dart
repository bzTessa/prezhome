import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/shopping/shopping_parts.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('el campo rápido envía el texto, se vacía y no envía vacíos', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      _host(ShoppingQuickAddBar(onSubmit: sent.add, onMore: () {})),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(sent, isEmpty);

    await tester.enterText(find.byType(TextField), '2 kg tomates');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(sent, ['2 kg tomates']);
    expect(find.text('2 kg tomates'), findsNothing);
  });

  testWidgets('la fila marca al tocar y muestra la cantidad', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(
      _host(
        ShoppingItemTile(
          name: 'Tomates',
          quantityLabel: '2 kg',
          checked: false,
          onToggle: () => toggles++,
        ),
      ),
    );
    expect(find.text('2 kg'), findsOneWidget);
    await tester.tap(find.text('Tomates'));
    expect(toggles, 1);
  });

  testWidgets('la sección pliega y despliega sus filas', (tester) async {
    var expanded = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _host(
          ShoppingSection(
            title: 'Verduras',
            count: 1,
            expanded: expanded,
            onToggle: () => setState(() => expanded = !expanded),
            children: [
              ShoppingItemTile(
                name: 'Tomates',
                checked: false,
                onToggle: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('Verduras'), findsOneWidget);

    await tester.tap(find.text('Verduras'));
    await tester.pumpAndSettle();
    expect(find.text('Tomates'), findsNothing);
  });

  testWidgets('la cabecera resume progreso y coste', (tester) async {
    await tester.pumpWidget(
      _host(
        ShoppingSummaryHeader(
          listName: 'Lista principal',
          pending: 3,
          done: 1,
          estimate: 12.4,
          onTapList: () {},
          onGenerate: () {},
          onOptions: () {},
        ),
      ),
    );
    expect(find.text('3 por comprar · 1 en el carro'), findsOneWidget);
    expect(find.text('≈ 12,40\u00A0€'), findsOneWidget);
    expect(find.byType(CartProgressBar), findsOneWidget);
  });
}
