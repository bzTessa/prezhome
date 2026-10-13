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
      MaterialApp(
        home: CookModeScreen(
          title: 'Lentejas',
          steps: [
            CookStep.fromText('Pica la verdura.'),
            CookStep.fromText('Cuece 30 minutos.'),
          ],
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
    await tester.tap(find.text('Parar'));
    await tester.pump();
    expect(find.text('Parar'), findsNothing);

    await tester.tap(find.byTooltip('Ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('200 g lentejas'), findsOneWidget);
    await tester.tap(find.text('200 g lentejas'));
    await tester.pump();
    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '200 g lentejas'),
    );
    expect(tile.value, isTrue);
  });

  testWidgets('en tanda lleva varios temporizadores a la vez', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: CookModeScreen(
          title: 'Cocina en tanda',
          steps: [
            CookStep(
              'Enciende el horno para lasaña',
              note: 'Horno · lasaña',
              minutes: 40,
            ),
            CookStep('Lava el arroz', note: 'arroz · Mientras tanto'),
            CookStep(
              'Enciende la olla para arroz',
              note: 'Olla · arroz',
              minutes: 18,
            ),
          ],
          ingredients: [],
        ),
      ),
    );

    expect(find.text('Horno · lasaña'), findsOneWidget);
    expect(find.text('Lava el arroz'), findsOneWidget); // "Luego"
    await tester.tap(find.text('Temporizador 40 min'));
    await tester.pump();
    await tester.tap(find.text('Siguiente paso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente paso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temporizador 18 min'));
    await tester.pump();

    expect(find.text('Parar'), findsNWidgets(2));
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('40:00'), findsOneWidget);
    await tester.tap(find.text('Parar').first);
    await tester.pump();
    expect(find.text('Parar'), findsOneWidget);
  });
}
