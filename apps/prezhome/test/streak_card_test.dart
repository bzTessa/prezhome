import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/services/streak.dart';
import 'package:prezhome/widgets/streak_card.dart';

void main() {
  testWidgets('StreakCard mantiene la vista estable durante refresh', (
    tester,
  ) async {
    final key = GlobalKey<StreakCardState>();
    var calls = 0;
    Completer<Streak?>? pending;

    Future<Streak?> load() {
      calls++;
      if (calls == 1) {
        return Future.value(const Streak(days: 4, doneToday: true));
      }
      pending = Completer<Streak?>();
      return pending!.future;
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: StreakCard(key: key, loader: load),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StreakView), findsOneWidget);
    final initialHeight = tester.getSize(find.byType(StreakCard)).height;
    expect(initialHeight, greaterThan(40));

    unawaited(key.currentState!.refresh());
    await tester.pump();

    expect(find.byType(StreakView), findsOneWidget);
    expect(tester.getSize(find.byType(StreakCard)).height, initialHeight);

    pending!.complete(const Streak(days: 5, doneToday: true));
    await tester.pumpAndSettle();
    expect(find.text('5/7'), findsOneWidget);
  });
}
