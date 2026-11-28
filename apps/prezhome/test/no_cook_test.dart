import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/meal_plan_entry.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/plan_prep.dart';

Recipe _r(
  String title, {
  List<String> types = const ['lunch'],
  int? prep,
  bool? noCook,
}) => Recipe(
  id: title,
  homeId: 'h',
  title: title,
  servings: 2,
  mealTypes: types,
  prepTimeMinutes: prep,
  noCook: noCook,
);

void main() {
  test('El café, el yogur y la fruta no se cocinan', () {
    expect(_r('Café con leche y tostada').needsCooking, isFalse);
    expect(_r('Yogur con fruta y granola').needsCooking, isFalse);
    expect(_r('Zumo de naranja').needsCooking, isFalse);
    expect(_r('Té verde').needsCooking, isFalse);
  });

  test('Los platos de verdad sí, aunque empiecen parecido', () {
    expect(_r('Ternera guisada').needsCooking, isTrue);
    expect(_r('Lentejas con chorizo').needsCooking, isTrue);
    expect(_r('Tortilla de patatas').needsCooking, isTrue);
  });

  test('Bebidas y lo de 5 minutos sin aparato no se cocinan', () {
    expect(_r('Agua de limón', types: ['drink']).needsCooking, isFalse);
    expect(_r('Bocadillo de pavo', prep: 5).needsCooking, isFalse);
    expect(_r('Bocadillo de pavo', prep: 15).needsCooking, isTrue);
  });

  test('Lo marcado a mano manda', () {
    expect(_r('Café', noCook: false).needsCooking, isTrue);
    expect(_r('Ensalada César', noCook: true).needsCooking, isFalse);
  });

  test('El café del desayuno no entra en la cocina en lote', () {
    final monday = DateTime(2026, 11, 30);
    final recipes = {
      'Café con leche': _r('Café con leche', types: ['breakfast']),
      'Lentejas': _r('Lentejas'),
    };
    MealPlanEntry e(String id, String type) => MealPlanEntry(
      homeId: 'h',
      date: monday,
      mealType: type,
      recipeId: id,
      servings: 2,
    );
    final plan = prepPlanForWeek(
      entries: [e('Café con leche', 'breakfast'), e('Lentejas', 'lunch')],
      recipesById: recipes,
      weekStart: monday,
    );
    final cooked = plan.cookingDays
        .expand((d) => d.batches)
        .map((b) => b.recipeId)
        .toSet();
    expect(cooked, {'Lentejas'});
  });
}
