import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/cook_mode_screen.dart';

void main() {
  testWidgets('avanza paso a paso, ofrece temporizador y termina', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: CookModeScreen(
          title: 'Lentejas',
          steps: ['Pica la verdura.', 'Cuece 30 minutos.'],
          ingredients: ['200 g lentejas', '1 cebolla'],
        ),
      ),
    );

    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('Siguiente paso'), findsOneWidget);
    expect(find.textContaining('Temporizador'), findsNothing);

    await tester.tap(find.text('Siguiente paso'));
    await tester.pumpAndSettle();
    expect(find.text('PASO 2 DE 2'), findsOneWidget);
    expect(find.text('Temporizador 30 min'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);

    await tester.tap(find.text('Temporizador 30 min'));
    await tester.pump();
    expect(find.text('30:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('29:59'), findsOneWidget);
    await tester.tap(find.text('Parar'));
    await tester.pump();
    expect(find.text('Parar'), findsNothing);

    await tester.tap(find.text('Ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('200 g lentejas'), findsOneWidget);
    await tester.tap(find.text('200 g lentejas'));
    await tester.pump();
    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '200 g lentejas'),
    );
    expect(tile.value, isTrue);
  });
}
