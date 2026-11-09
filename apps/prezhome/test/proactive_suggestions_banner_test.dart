import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/proactive_suggestions_service.dart';
import 'package:prezhome/widgets/proactive_suggestions_banner.dart';

/// Tests de LÓGICA PURA del helper [ProactiveSuggestionsBanner.bannerMessage]:
/// decide el texto del banner a partir de las sugerencias ya calculadas. No
/// monta widgets ni requiere plugins nativos ni Supabase.
void main() {
  group('ProactiveSuggestionsBanner.bannerMessage', () {
    test('dice qué caduca y cuándo', () {
      const sugs = [ExpiringSuggestion(name: 'Yogur', daysUntilExpiry: 0)];
      expect(ProactiveSuggestionsBanner.bannerTitle(sugs), 'Caduca pronto');
      expect(ProactiveSuggestionsBanner.bannerMessage(sugs), 'Yogur hoy');
    });

    test('con muchas, las dos más urgentes y cuántas más', () {
      const sugs = [
        ExpiringSuggestion(name: 'Pollo', daysUntilExpiry: 1),
        ExpiringSuggestion(name: 'Espinacas', daysUntilExpiry: 2),
        ExpiringSuggestion(name: 'Queso', daysUntilExpiry: 2),
        ExpiringSuggestion(name: 'Pan', daysUntilExpiry: 2),
      ];
      expect(ProactiveSuggestionsBanner.bannerTitle(sugs), 'Caducan pronto');
      expect(
        ProactiveSuggestionsBanner.bannerMessage(sugs),
        'Pollo mañana · Espinacas en 2 días · +2',
      );
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
    expect(find.text('Caduca pronto'), findsOneWidget);
    expect(find.text('Ideas'), findsOneWidget);
    expect(find.textContaining('Miau'), findsNothing);
  });
}
