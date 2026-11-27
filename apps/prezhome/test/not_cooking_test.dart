import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/models/meal_plan_entry.dart';
import 'package:prezhome/models/ready_meal.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/not_cooking.dart';

InventoryItem _item(
  String name, {
  String category = 'Nevera',
  String kind = 'ingredient',
  String? recipeId,
  double qty = 1,
}) => InventoryItem(
  id: name,
  homeId: 'h',
  name: name,
  category: category,
  quantity: qty,
  unit: 'ud',
  kind: kind,
  recipeId: recipeId,
);

void main() {
  test('Tápers de la nevera antes que los del congelador', () {
    final o = NotCooking.pick(
      pantry: [
        _item('Lentejas', category: 'Congelador', kind: 'dish', recipeId: 'l'),
        _item('Arroz al horno', kind: 'dish', recipeId: 'a'),
        _item('Leche'),
      ],
      readyMeals: const [],
      recipes: const [],
    );
    expect(o.dishes.map((d) => d.name), ['Arroz al horno', 'Lentejas']);
  });

  test('Preparados que hay en casa primero; postres fuera', () {
    final o = NotCooking.pick(
      pantry: [_item('Pizza barbacoa Hacendado')],
      readyMeals: const [
        ReadyMeal(id: '1', name: 'Lasaña'),
        ReadyMeal(id: '2', name: 'Pizza barbacoa'),
        ReadyMeal(id: '3', name: 'Coulant', kind: 'dessert'),
        ReadyMeal(id: '4', name: 'Croquetas', trusted: false),
      ],
      recipes: const [],
    );
    expect(o.ready.map((r) => (r.meal.name, r.atHome)), [
      ('Pizza barbacoa', true),
      ('Lasaña', false),
    ]);
  });

  test('Algo rápido: sin cocinar o de 15 minutos, no la receta de hoy', () {
    Recipe r(String t, int? min) => Recipe(
      id: t,
      homeId: 'h',
      title: t,
      servings: 2,
      mealTypes: const ['dinner'],
      prepTimeMinutes: min,
    );
    final o = NotCooking.pick(
      pantry: const [],
      readyMeals: const [],
      recipes: [
        r('Lentejas', 60),
        r('Sándwich mixto', 10),
        r('Ensalada', 15),
        r('Tortilla', 12),
      ],
      currentRecipeId: 'Tortilla',
    );
    expect(o.quick.map((q) => q.title), ['Sándwich mixto', 'Ensalada']);
  });

  test('La receta pasa al primer día libre de esa comida', () {
    final mon = DateTime(2026, 11, 30);
    MealPlanEntry e(int day, String type) => MealPlanEntry(
      homeId: 'h',
      date: mon.add(Duration(days: day)),
      mealType: type,
    );
    final free = NotCooking.nextFreeDay(
      from: mon,
      mealType: 'dinner',
      entries: [e(1, 'dinner'), e(2, 'lunch'), e(3, 'dinner')],
    );
    expect(free, DateTime(2026, 12, 2));
    expect(
      NotCooking.nextFreeDay(
        from: mon,
        mealType: 'dinner',
        entries: [for (var i = 1; i <= 7; i++) e(i, 'dinner')],
      ),
      isNull,
    );
  });
}
