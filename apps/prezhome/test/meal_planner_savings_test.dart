import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/meal_planner.dart';
import 'package:prezhome/services/plan_hints.dart';

Recipe _r(String id, [List<String> ings = const []]) => Recipe(
  id: id,
  homeId: 'h',
  title: 'Receta $id',
  servings: 2,
  mealTypes: const ['lunch'],
  ingredientNames: ings,
);

/// Cuántas veces sale [id] el primer día en [runs] planes.
int _firstDayHits(
  String id,
  List<Recipe> recipes, {
  Set<String> expiring = const {},
  Map<String, double> cost = const {},
  int pressure = 0,
  int runs = 400,
}) {
  var hits = 0;
  for (var seed = 0; seed < runs; seed++) {
    final plan = MealPlanner(seed: seed).generate(
      startDate: DateTime(2026, 11, 16),
      days: 1,
      mealTypes: const ['lunch'],
      recipes: recipes,
      expiringIngredients: expiring,
      costPerServing: cost,
      budgetPressure: pressure,
    );
    if (plan.values.first['lunch'] == id) hits++;
  }
  return hits;
}

void main() {
  final recipes = [
    _r('a', ['Pollo']),
    _r('b', ['Merluza']),
    _r('c', ['Lentejas']),
    _r('d', ['Espinacas', 'Sal']),
  ];

  test('Prefiere recetas que usan lo que caduca pronto', () {
    final base = _firstDayHits('d', recipes);
    final rescue = _firstDayHits(
      'd',
      recipes,
      expiring: {'espinacas frescas bolsa'},
    );
    expect(rescue, greaterThan(base * 1.4));
  });

  test('Los básicos como la sal no cuentan como caducidad', () {
    final base = _firstDayHits('d', recipes);
    final salt = _firstDayHits('d', recipes, expiring: {'sal'});
    expect(salt, base);
  });

  test('Con el mes justo tira de lo barato', () {
    final cost = {'a': 4.0, 'b': 4.0, 'c': 1.0, 'd': 4.0};
    final none = _firstDayHits('c', recipes, cost: cost);
    final mild = _firstDayHits('c', recipes, cost: cost, pressure: 1);
    final tight = _firstDayHits('c', recipes, cost: cost, pressure: 2);
    expect(mild, greaterThan(none));
    expect(tight, greaterThan(mild));
  });

  test('En la semana repite ingredientes frescos de otras recetas', () {
    // Seis recetas con cilantro y lima y seis sin nada en común: con el cilantro ya
    // comprado, deben salir más de las primeras que por puro azar.
    final shared = [
      for (var i = 0; i < 6; i++)
        _r('s$i', ['Cilantro', 'Lima', 'Ingrediente $i']),
      for (var i = 0; i < 6; i++) _r('o$i', ['Otro $i']),
    ];
    var withCilantro = 0, total = 0;
    for (var seed = 0; seed < 200; seed++) {
      final plan = MealPlanner(seed: seed).generate(
        startDate: DateTime(2026, 11, 16),
        days: 7,
        mealTypes: const ['lunch'],
        recipes: shared,
      );
      for (final day in plan.values) {
        total++;
        if (day['lunch']!.startsWith('s')) withCilantro++;
      }
    }
    expect(withCilantro / total, greaterThan(0.55));
  });

  test('Presión del presupuesto', () {
    expect(budgetPressureFor(budget: 0, spent: 50, monthProgress: .5), 0);
    expect(budgetPressureFor(budget: 400, spent: 100, monthProgress: .5), 1);
    expect(budgetPressureFor(budget: 400, spent: 300, monthProgress: .5), 2);
  });
}
