import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/services/calendar_sync.dart';
import 'package:prezhome/services/meal_planner.dart';
import 'package:prezhome/services/meal_prep_planner.dart';

void main() {
  final day = DateTime(2026, 11, 16);
  ({DateTime start, DateTime end}) slot(int from, int to) => (
    start: day.add(Duration(hours: from)),
    end: day.add(Duration(hours: to)),
  );

  test('carga del día según las horas ocupadas', () {
    expect(CalendarSync.loadOf([slot(9, 16)], day), 2);
    expect(CalendarSync.loadOf([slot(9, 12), slot(10, 11)], day), 1);
    expect(CalendarSync.loadOf([slot(23, 24)], day), 0);
    expect(CalendarSync.loadOf(const [], day), 0);
  });

  test('tareas sin hora van al primer hueco libre sin pisarse', () {
    HomeTask t(String id) =>
        HomeTask(id: id, homeId: 'h', title: id, dueDate: day);
    final placed = CalendarSync.placeTasks(
      [t('a'), t('b')],
      day,
      day.add(const Duration(days: 1)),
      [slot(8, 18)],
      DateTime(2026, 11, 15),
    );
    expect(placed.map((e) => e.start), [
      day.add(const Duration(hours: 18)),
      day.add(const Duration(hours: 18, minutes: 30)),
    ]);
  });

  test('día cargado: rápidas y congelado arriba, largas abajo', () {
    Recipe r(int? minutes) => Recipe(
      id: '$minutes',
      homeId: 'h',
      title: 'x',
      servings: 2,
      prepTimeMinutes: minutes,
    );
    expect(MealPlanner.busyFactor(r(15), 2, false), 4);
    expect(MealPlanner.busyFactor(r(90), 2, false), 0.15);
    expect(MealPlanner.busyFactor(r(90), 2, true), 4);
    expect(MealPlanner.busyFactor(r(null), 2, false), 1);
    expect(MealPlanner.busyFactor(r(90), 0, false), 1.5);
    expect(MealPlanner.busyFactor(r(90), 1, false), 1);
  });

  test('la cocina en lote se adelanta al día más libre', () {
    String key(int i) =>
        CalendarSync.dayKey(DateTime(day.year, day.month, day.day + i));
    final meals = [
      for (var i = 0; i < 7; i++)
        PrepMeal(
          recipeId: 'lentejas',
          date: DateTime(day.year, day.month, day.day + i),
          mealType: 'lunch',
          servings: 2,
        ),
    ];
    const recipes = {
      'lentejas': PrepRecipe(
        id: 'lentejas',
        title: 'lentejas',
        freezable: true,
      ),
    };
    List<DateTime> cookDays(Map<String, int> loads) => [
      for (final d
          in const MealPrepPlanner()
              .buildPlan(
                meals: meals,
                recipesById: recipes,
                weekStart: day,
                dayLoads: loads,
              )
              .cookingDays)
        d.date,
    ];
    expect(cookDays(const {}), [day, DateTime(2026, 11, 19)]);
    // Jueves cargado y martes libre: el segundo día de cocina pasa al martes.
    expect(cookDays({key(3): 2, key(1): 0}), [day, DateTime(2026, 11, 17)]);
  });
}
