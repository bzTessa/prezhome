import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/empty_state.dart';

void main() {
  testWidgets('muestra título, mensaje y lanza la acción', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: EmptyState(
              title: 'Tu lista está vacía',
              message: 'Escribe arriba lo que necesitas.',
              actionLabel: 'Desde el plan',
              onAction: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Tu lista está vacía'), findsOneWidget);
    expect(find.text('Escribe arriba lo que necesitas.'), findsOneWidget);
    await tester.tap(find.text('Desde el plan'));
    expect(tapped, isTrue);
  });
}
