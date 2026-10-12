import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/dashboard_prefs.dart';
import 'package:prezhome/models/onboarding_answers.dart';

void main() {
  group('perfil de hogar', () {
    test('dos personas = El Dúo', () {
      expect(const OnboardingAnswers(people: 2).profile.name, 'El Dúo');
    });
    test('una persona = En Solitario', () {
      expect(const OnboardingAnswers(people: 1).profile.name, 'En Solitario');
    });
    test('piso compartido manda sobre el número de personas', () {
      const a = OnboardingAnswers(people: 4, housing: HousingType.compartido);
      expect(a.profile.name, 'El Piso Compartido');
    });
    test('familia grande', () {
      expect(const OnboardingAnswers(people: 4).profile.name, 'La Familia');
      expect(const OnboardingAnswers(people: 6).profile.name, 'La Tribu');
    });
    test('la carga con la app es menor y ambas entre 1 y 10', () {
      const a = OnboardingAnswers(
        people: 3,
        goals: {HomeGoal.comidas, HomeGoal.compra, HomeGoal.tareas},
      );
      final p = a.profile;
      expect(p.loadToday, inInclusiveRange(1, 10));
      expect(p.loadWithApp, inInclusiveRange(1, 10));
      expect(p.loadWithApp, lessThan(p.loadToday));
    });
  });

  group('aplicar a las preferencias', () {
    final base = DashboardPrefs.defaults();

    test('sin objetivos deja todo visible', () {
      final p = const OnboardingAnswers().applyTo(base);
      expect(p.enabledModules, base.enabledModules);
      expect(p.hidden, isEmpty);
    });

    test('solo compra y despensa: sin tareas ni cocina en lote', () {
      final p = const OnboardingAnswers(
        goals: {HomeGoal.compra, HomeGoal.despensa},
        cooking: CookingHabit.diario,
      ).applyTo(base);
      expect(p.enabledModules, isEmpty);
      expect(p.hidden, contains(DashboardCard.tasks));
      expect(p.hidden, contains(DashboardCard.spending));
      expect(p.hidden, isNot(contains(DashboardCard.expiry)));
      expect(p.quick.first, QuickAction.shopping);
      expect(p.cookingStyle, CookingStyle.daily);
    });

    test(
      'tareas en pareja activa puntos; cocinar en lote activa el módulo',
      () {
        final p = const OnboardingAnswers(
          people: 2,
          goals: {HomeGoal.tareas},
          cooking: CookingHabit.lote,
        ).applyTo(base);
        expect(p.enabledModules, {
          HomeModule.tasks,
          HomeModule.points,
          HomeModule.batchCooking,
        });
        expect(p.cookingStyle, CookingStyle.batch);
      },
    );

    test('tareas viviendo solo no activa puntos', () {
      final p = const OnboardingAnswers(
        people: 1,
        goals: {HomeGoal.tareas},
      ).applyTo(base);
      expect(p.enabledModules, {HomeModule.tasks});
    });
  });

  group('guardado', () {
    test('ida y vuelta', () {
      const a = OnboardingAnswers(
        housing: HousingType.casa,
        people: 3,
        goals: {HomeGoal.comidas, HomeGoal.gastos},
        cooking: CookingHabit.mixto,
        supermarkets: ['mercadona', 'lidl'],
        shopping: ShoppingFrequency.semanal,
        reminders: false,
      );
      final b = OnboardingAnswers.decode(a.encode())!;
      expect(b.housing, HousingType.casa);
      expect(b.people, 3);
      expect(b.goals, {HomeGoal.comidas, HomeGoal.gastos});
      expect(b.cooking, CookingHabit.mixto);
      expect(b.supermarkets, ['mercadona', 'lidl']);
      expect(b.shopping, ShoppingFrequency.semanal);
      expect(b.reminders, isFalse);
    });

    test('datos corruptos o vacíos devuelven null', () {
      expect(OnboardingAnswers.decode(null), isNull);
      expect(OnboardingAnswers.decode(''), isNull);
      expect(OnboardingAnswers.decode('xx'), isNull);
    });
  });
}
