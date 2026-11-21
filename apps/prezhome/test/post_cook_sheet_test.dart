import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/pantry_usage.dart';
import 'package:prezhome/widgets/post_cook_sheet.dart';

Recipe _recipe() => Recipe(
  id: 'rec-1',
  homeId: 'h',
  title: 'Pollo al horno',
  servings: 4,
  freezable: true,
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('es'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'con ingredientes: permite descontar y repartir raciones a nevera y congelador',
    (tester) async {
      PostCookChoice? chosen;
      var called = false;
      final uses = [
        PantryUse(
          InventoryItem(
            id: '1',
            homeId: 'h',
            name: 'Pechuga de pollo',
            category: 'Nevera',
            quantity: 1,
            unit: 'kg',
          ),
          600,
          unit: 'g',
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PostCookSheetContent(
            recipe: _recipe(),
            servingsCooked: 4,
            uses: uses,
            onDone: (c) {
              called = true;
              chosen = c;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isTrue);

      await tester.tap(find.byKey(const ValueKey('post-cook-fridge-plus')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('post-cook-fridge-plus')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('post-cook-freezer-plus')));
      await tester.pump();

      await tester.tap(find.text('Guardar en En casa'));
      await tester.pump();

      expect(called, isTrue);
      expect(chosen, isNotNull);
      expect(chosen!.deductPantry, isTrue);
      expect(chosen!.fridgeServings, 2);
      expect(chosen!.freezerServings, 1);
    },
  );

  testWidgets(
    'sin ingredientes ni sobras: botón Listo cierra devolviendo null',
    (tester) async {
      PostCookChoice? chosen = const PostCookChoice(
        deductPantry: true,
        fridgeServings: 1,
        freezerServings: 1,
      );
      var called = false;

      await tester.pumpWidget(
        _wrap(
          PostCookSheetContent(
            recipe: _recipe(),
            servingsCooked: 2,
            uses: const [],
            onDone: (c) {
              called = true;
              chosen = c;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No hay ingredientes que descontar en En casa.'),
        findsOneWidget,
      );
      expect(find.text('Listo'), findsOneWidget);

      await tester.tap(find.text('Listo'));
      await tester.pump();

      expect(called, isTrue);
      expect(chosen, isNull);
    },
  );

  testWidgets('sin diario no se ofrece apuntarlo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PostCookSheetContent(
          recipe: _recipe(),
          servingsCooked: 4,
          uses: const [],
          onDone: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('post-cook-diary')), findsNothing);
  });

  testWidgets('con diario: apuntar solo eso cambia el botón y lo devuelve', (
    tester,
  ) async {
    PostCookChoice? chosen;
    await tester.pumpWidget(
      _wrap(
        PostCookSheetContent(
          recipe: _recipe(),
          servingsCooked: 4,
          uses: const [],
          diaryKcal: 450,
          onDone: (c) => chosen = c,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('450 kcal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('post-cook-diary')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apuntar en mi diario').last);
    await tester.pump();
    expect(chosen?.logToDiary, isTrue);
    expect(chosen?.deductPantry, isFalse);
  });
}
