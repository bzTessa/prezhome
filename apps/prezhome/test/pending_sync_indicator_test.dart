import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/widgets/pending_sync_indicator.dart';

Widget _app(int pending) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: PendingSyncIndicator(pendingCount: pending)),
);

void main() {
  testWidgets('no aparece si los cambios se suben enseguida', (tester) async {
    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Icon), findsNothing);
    await tester.pumpWidget(_app(0));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('aparece si siguen pendientes un rato', (tester) async {
    await tester.pumpWidget(_app(2));
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(Icon), findsOneWidget);
    await tester.pumpWidget(_app(0));
    expect(find.byType(Icon), findsNothing);
  });
}
