import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/onboarding/onboarding_flow.dart';

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  // Deja terminar la transición entre pantallas (la saliente se retira en el
  // fotograma siguiente al fin de la animación).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('recorre el cuestionario hasta el perfil de hogar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: OnboardingFlow()));
    await tester.pump(const Duration(milliseconds: 400));

    await _tapText(tester, 'Comenzar');
    expect(find.text('¿Cuántas personas vivís?'), findsOneWidget);
    expect(find.text('2 personas'), findsOneWidget);
    await _tapText(tester, 'Continuar');

    expect(find.text('¿Qué quieres quitarte de la cabeza?'), findsOneWidget);
    // Sin respuesta no se puede continuar.
    final continueBtn = find.widgetWithText(FilledButton, 'Elige al menos una');
    expect(tester.widget<FilledButton>(continueBtn).onPressed, isNull);
    await _tapText(tester, 'La compra');
    await _tapText(tester, 'Tareas del hogar');
    await _tapText(tester, 'Continuar (2)');

    await _tapText(tester, 'Cada día');
    await _tapText(tester, 'Continuar');

    expect(find.text('¿Dónde compras?'), findsOneWidget);
    await _tapText(tester, 'Mercadona');
    await _tapText(tester, 'Ver mi hogar');

    expect(find.text('Tu perfil de hogar'), findsOneWidget);
    expect(find.text('El Dúo'), findsOneWidget);
    expect(find.text('Crear mi cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
