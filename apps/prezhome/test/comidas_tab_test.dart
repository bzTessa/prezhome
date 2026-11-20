import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/tabs/comidas_tab.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('es'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);

void main() {
  test('comidasSubTabKeys y clampComidasSubTab respetan showDiary', () {
    expect(comidasSubTabKeys(true), ['plan', 'recipes', 'diary']);
    expect(comidasSubTabKeys(false), ['plan', 'recipes']);
    expect(clampComidasSubTab(2, showDiary: true), 2);
    expect(clampComidasSubTab(2, showDiary: false), 1);
  });

  testWidgets('con showDiary false oculta Diario en SegmentedPill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ComidasTab(showDiary: false, tabBuilder: (_, i) => Text('tab-$i'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Recetas'), findsOneWidget);
    expect(find.text('Diario'), findsNothing);
    expect(find.text('tab-0'), findsOneWidget);
  });

  testWidgets(
    'al desactivar showDiary desde Diario clampa a Recetas sin error',
    (tester) async {
      await tester.pumpWidget(
        _app(
          ComidasTab(
            key: const ValueKey('comidas'),
            showDiary: true,
            tabBuilder: (_, i) => Text('tab-$i'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Diario'));
      await tester.pumpAndSettle();
      expect(find.text('tab-2'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          ComidasTab(
            key: const ValueKey('comidas'),
            showDiary: false,
            tabBuilder: (_, i) => Text('tab-$i'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diario'), findsNothing);
      expect(find.text('tab-1'), findsOneWidget);
    },
  );
}
