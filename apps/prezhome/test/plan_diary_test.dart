import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/dashboard_prefs.dart';
import 'package:prezhome/models/meal_plan_entry.dart';
import 'package:prezhome/models/nutrition_profile.dart';
import 'package:prezhome/services/plan_diary.dart';

void main() {
  // Miércoles 14/10/2026.
  final day = DateTime(2026, 10, 14);
  MealPlanEntry meal(String type, {DateTime? on, bool skipped = false}) =>
      MealPlanEntry(
        homeId: 'h',
        date: on ?? day,
        mealType: type,
        recipeId: 'r-$type',
        skipped: skipped,
      );

  group('PlanDiary.passed', () {
    final me = NutritionProfile.fromMap({'id': 'u'});
    final plan = [meal('breakfast'), meal('lunch'), meal('dinner')];

    test('solo las comidas cuya hora ya pasó', () {
      final now = DateTime(2026, 10, 14, 17);
      final due = PlanDiary.passed(plan, me, day, now);
      expect(due.map((e) => e.mealType), ['breakfast', 'lunch']);
    });

    test('no repite lo ya apuntado antes de since', () {
      final since = DateTime(2026, 10, 14, 16, 30);
      final now = DateTime(2026, 10, 14, 23, 30);
      final due = PlanDiary.passed(plan, me, since, now);
      expect(due.map((e) => e.mealType), ['dinner']);
    });

    test('salta lo saltado y lo que no come en casa', () {
      final away = NutritionProfile.fromMap({
        'id': 'u',
        'meals_at_home': {
          'lunch': [1, 2],
        },
      });
      final now = DateTime(2026, 10, 15);
      final due = PlanDiary.passed(
        [meal('breakfast', skipped: true), meal('lunch'), meal('dinner')],
        away,
        day,
        now,
      );
      expect(due.map((e) => e.mealType), ['dinner']);
    });
  });

  group('DashboardPrefs del cuestionario', () {
    test('ida y vuelta de cocinas, aparatos y calorías', () {
      final prefs = DashboardPrefs.defaults().copyWith(
        cuisines: {'mediterranea'},
        appliances: {'oven'},
        trackCalories: false,
      );
      final back = DashboardPrefs.fromJson(prefs.toJson());
      expect(back.cuisines, {'mediterranea'});
      expect(back.appliances, {'oven'});
      expect(back.trackCalories, isFalse);
    });

    test('sin responder: calorías activas y vale cualquier aparato', () {
      final prefs = DashboardPrefs.fromJson({});
      expect(prefs.trackCalories, isTrue);
      expect(prefs.appliances, isNull);
      expect(prefs.canCook('airfryer'), isTrue);
    });

    test('con aparatos elegidos, lo básico siempre vale', () {
      final prefs = DashboardPrefs.defaults().copyWith(appliances: {'oven'});
      expect(prefs.canCook('oven'), isTrue);
      expect(prefs.canCook('pot'), isTrue);
      expect(prefs.canCook('airfryer'), isFalse);
    });
  });
}
