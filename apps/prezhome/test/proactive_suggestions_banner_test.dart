import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/proactive_suggestions_service.dart';
import 'package:prezhome/widgets/proactive_suggestions_banner.dart';

/// Tests de LÓGICA PURA del helper [ProactiveSuggestionsBanner.bannerMessage]:
/// decide el texto del banner a partir de las sugerencias ya calculadas. No
/// monta widgets ni requiere plugins nativos ni Supabase.
void main() {
  group('ProactiveSuggestionsBanner.bannerMessage', () {
    test('sin sugerencias devuelve cadena vacía', () {
      expect(ProactiveSuggestionsBanner.bannerMessage(const []), '');
    });

    test('con una sugerencia usa su mensaje cercano', () {
      const sugs = [ExpiringSuggestion(name: 'Yogur', daysUntilExpiry: 0)];
      expect(
        ProactiveSuggestionsBanner.bannerMessage(sugs),
        'Cocina Yogur antes de que caduque (caduca hoy)',
      );
    });

    test('con varias sugerencias resume la cantidad (sin la palabra IA)', () {
      const sugs = [
        ExpiringSuggestion(name: 'Pollo', daysUntilExpiry: 1),
        ExpiringSuggestion(name: 'Espinacas', daysUntilExpiry: 2),
      ];
      final msg = ProactiveSuggestionsBanner.bannerMessage(sugs);
      expect(msg, contains('2 alimentos a punto de caducar'));
      expect(msg.toLowerCase(), isNot(contains('ia')));
    });
  });

  testWidgets('el aviso cabe en un móvil estrecho y no nombra a la mascota', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProactiveSuggestionsBanner(
            suggestions: const [
              ExpiringSuggestion(name: 'Pechuga de pollo', daysUntilExpiry: 1),
            ],
            onAction: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Consejo del día'), findsOneWidget);
    expect(find.textContaining('Miau'), findsNothing);
  });
}
