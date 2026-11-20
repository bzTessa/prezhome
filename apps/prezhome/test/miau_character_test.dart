import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/utils/miau_mood_resolver.dart';
import 'package:prezhome/widgets/miau_character.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('resolveHomeCatMood', () {
    test('noche o madrugada -> durmiendo', () {
      expect(
        resolveHomeCatMood(
          hour: 23,
          expiredCount: 1,
          expiringSoonCount: 3,
          pendingTasks: 2,
          doneTodayTasks: 0,
          hasMealsToday: true,
          pendingShopping: 10,
        ),
        MiauMood.sleeping,
      );
      expect(
        resolveHomeCatMood(
          hour: 5,
          expiredCount: 0,
          expiringSoonCount: 0,
          pendingTasks: 0,
          doneTodayTasks: 2,
          hasMealsToday: true,
          pendingShopping: 0,
        ),
        MiauMood.sleeping,
      );
    });

    test('caducados o varios por caducar -> preocupado', () {
      expect(
        resolveHomeCatMood(
          hour: 11,
          expiredCount: 1,
          expiringSoonCount: 0,
          pendingTasks: 0,
          doneTodayTasks: 1,
          hasMealsToday: true,
          pendingShopping: 0,
        ),
        MiauMood.worried,
      );
      expect(
        resolveHomeCatMood(
          hour: 11,
          expiredCount: 0,
          expiringSoonCount: 2,
          pendingTasks: 0,
          doneTodayTasks: 1,
          hasMealsToday: true,
          pendingShopping: 0,
        ),
        MiauMood.worried,
      );
    });

    test('todas las tareas de hoy resueltas -> celebrando', () {
      expect(
        resolveHomeCatMood(
          hour: 13,
          expiredCount: 0,
          expiringSoonCount: 0,
          pendingTasks: 0,
          doneTodayTasks: 3,
          hasMealsToday: true,
          pendingShopping: 0,
        ),
        MiauMood.celebrating,
      );
    });

    test('hora de comer o cenar con plan -> cocinando', () {
      expect(
        resolveHomeCatMood(
          hour: 13,
          expiredCount: 0,
          expiringSoonCount: 0,
          pendingTasks: 1,
          doneTodayTasks: 0,
          hasMealsToday: true,
          pendingShopping: 8,
        ),
        MiauMood.cooking,
      );
      expect(
        resolveHomeCatMood(
          hour: 20,
          expiredCount: 0,
          expiringSoonCount: 0,
          pendingTasks: 1,
          doneTodayTasks: 0,
          hasMealsToday: true,
          pendingShopping: 0,
        ),
        MiauMood.cooking,
      );
    });

    test('lista larga de la compra de día -> comprando', () {
      expect(
        resolveHomeCatMood(
          hour: 16,
          expiredCount: 0,
          expiringSoonCount: 0,
          pendingTasks: 1,
          doneTodayTasks: 0,
          hasMealsToday: false,
          pendingShopping: 6,
        ),
        MiauMood.shopping,
      );
    });

    test('día tranquilo sin avisos -> saludando', () {
      expect(
        resolveHomeCatMood(
          hour: 10,
          expiredCount: 0,
          expiringSoonCount: 1,
          pendingTasks: 2,
          doneTodayTasks: 0,
          hasMealsToday: true,
          pendingShopping: 2,
        ),
        MiauMood.greeting,
      );
    });
  });

  group('onboardingCatMood', () {
    test('asigna pose por paso del cuestionario', () {
      expect(onboardingCatMood(0), MiauMood.greeting);
      expect(onboardingCatMood(1), MiauMood.greeting);
      expect(onboardingCatMood(2, hasSelection: false), MiauMood.curious);
      expect(onboardingCatMood(2, hasSelection: true), MiauMood.celebrating);
      expect(onboardingCatMood(3), MiauMood.cooking);
      expect(onboardingCatMood(4), MiauMood.curious);
      expect(onboardingCatMood(5), MiauMood.shopping);
      expect(onboardingCatMood(6), MiauMood.celebrating);
    });
  });

  group('MiauCharacter widget', () {
    testWidgets('pinta todas las poses con float activo o desactivado', (
      tester,
    ) async {
      for (final mood in MiauMood.values) {
        await tester.pumpWidget(
          _wrap(MiauCharacter(mood: mood, size: 72, float: true)),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull, reason: 'float=true $mood');

        await tester.pumpWidget(
          _wrap(MiauCharacter(mood: mood, size: 72, float: false)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'float=false $mood');
      }
    });

    testWidgets(
      'al tocar con interactive: true dispara onTap y corazones sin errores',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(
          _wrap(
            MiauCharacter(
              mood: MiauMood.greeting,
              size: 80,
              float: false,
              interactive: true,
              onTap: () => tapped++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(MiauCharacter));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(tapped, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('cambiar de mood dispara la transición sin excepciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MiauCharacter(mood: MiauMood.curious, size: 80, float: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _wrap(
          const MiauCharacter(
            mood: MiauMood.celebrating,
            size: 80,
            float: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('con reducir movimiento activado asienta de inmediato', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MiauCharacter(
            mood: MiauMood.sleeping,
            size: 80,
            float: true,
            interactive: true,
          ),
          reduceMotion: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MiauCharacter));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
