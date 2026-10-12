import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/list_skeleton.dart';

void main() {
  testWidgets('el esqueleto se pinta y respeta reducir movimiento', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: ListSkeleton(rows: 3)),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    // Sin animación en marcha: no quedan fotogramas pendientes.
    expect(tester.hasRunningAnimations, isFalse);
  });
}
