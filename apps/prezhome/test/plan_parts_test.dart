import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/widgets/plan/plan_parts.dart';

void main() {
  testWidgets('la tira de días marca el elegido y avisa al tocar', (
    tester,
  ) async {
    final monday = DateTime(2026, 10, 12);
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    int? picked;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: WeekDayStrip(
            days: days,
            selected: 0,
            today: monday,
            mealsPerDay: const [2, 0, 1, 0, 0, 3, 0],
            onSelect: (i) => picked = i,
          ),
        ),
      ),
    );
    expect(find.text('LUN'), findsOneWidget);
    expect(find.text('DOM'), findsOneWidget);
    await tester.tap(find.text('17'));
    expect(picked, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hueco vacío invita a añadir y lleno muestra la receta', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: Column(
            children: [
              MealSlotCard(mealType: 'dinner', onTap: () => taps++),
              MealSlotCard(
                mealType: 'lunch',
                title: 'Lentejas con chorizo',
                onTap: () {},
                fromFreezer: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Añadir cena'), findsOneWidget);
    expect(find.text('Lentejas con chorizo'), findsOneWidget);
    expect(find.text('Del congelador'), findsOneWidget);
    await tester.tap(find.text('Añadir cena'));
    expect(taps, 1);
  });

  testWidgets('comida con postre: platos extra, añadir y quitar deslizando', (
    tester,
  ) async {
    var added = 0;
    var opened = 0;
    var removed = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: MealSlotCard(
            mealType: 'lunch',
            title: 'Lentejas con chorizo',
            onTap: () {},
            extras: [
              (
                id: 'flan',
                title: 'Flan de huevo',
                onTap: () => opened++,
                onRemove: () => removed++,
              ),
            ],
            onAddDish: () => added++,
          ),
        ),
      ),
    );
    expect(find.text('Flan de huevo'), findsOneWidget);
    await tester.tap(find.text('Añadir otro plato'));
    expect(added, 1);
    await tester.tap(find.text('Flan de huevo'));
    expect(opened, 1);
    await tester.drag(find.text('Flan de huevo'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(tester.takeException(), isNull);
  });
}
