import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/widgets/kitchen/pantry_review_card.dart';

void main() {
  testWidgets('pregunta por el caducado y cada botón responde', (t) async {
    final now = DateTime.now();
    final item = InventoryItem(
      id: 'n1',
      homeId: 'h',
      name: 'Nata para cocinar',
      category: 'Lácteos',
      quantity: 1,
      unit: 'ud',
      expirationDate: DateTime(now.year, now.month, now.day - 2),
    );
    final taps = <String>[];
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: PantryReviewCard(
            item: item,
            position: 1,
            total: 3,
            onStillGood: () => taps.add('ok'),
            onUsedUp: () => taps.add('used'),
            onThrown: () => taps.add('bin'),
          ),
        ),
      ),
    );
    expect(find.text('¿Sigue bien: Nata para cocinar?'), findsOneWidget);
    expect(find.text('Caducó hace 2 días'), findsOneWidget);
    expect(find.text('REPASO RÁPIDO · 1 DE 3'), findsOneWidget);
    await t.tap(find.text('Sigue bien'));
    await t.tap(find.text('Se acabó'));
    await t.tap(find.text('A la basura'));
    expect(taps, ['ok', 'used', 'bin']);
  });
}
