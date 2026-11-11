import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/widgets/recipe_category_chips.dart';

Recipe _r(String t, List<String> types, {int? kcal}) => Recipe(
  id: t,
  homeId: 'h',
  title: t,
  servings: 1,
  mealTypes: types,
  calories: kcal,
);

void main() {
  testWidgets('una fila con "Más" que despliega el resto y tocar elige', (
    tester,
  ) async {
    String? picked;
    final recipes = [
      _r('a', ['breakfast'], kcal: 300),
      _r('b', ['lunch']),
      _r('c', ['dinner']),
      _r('d', ['dessert']),
      _r('e', ['drink']),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RecipeCategoryChips(
              recipes: recipes,
              selected: picked,
              onSelected: (c) => setState(() => picked = c),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Postre'), findsNothing);
    await tester.tap(find.text('Más'));
    await tester.pump();
    expect(find.text('Postre'), findsOneWidget);
    await tester.tap(find.text('Desayuno'));
    await tester.pump();
    expect(picked, 'breakfast');
    await tester.tap(find.text('Desayuno'));
    expect(picked, isNull);
  });
}
