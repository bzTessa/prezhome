import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/meal_planner.dart';
import 'package:prezhome/services/plan_prefs.dart';

Recipe _r(String id, String title) => Recipe(
  id: id,
  homeId: 'h',
  title: title,
  servings: 2,
  mealTypes: const ['lunch', 'dinner'],
);

void main() {
  test('Clasifica por grupo: legumbre gana a carne', () {
    expect(
      proteinGroupOf(_r('a', 'Garbanzos salteados con espinacas y jamón')),
      ProteinGroup.legumbre,
    );
    expect(proteinGroupOf(_r('b', 'Merluza al horno')), ProteinGroup.pescado);
    expect(proteinGroupOf(_r('c', 'Tortilla de patatas')), ProteinGroup.huevo);
    expect(proteinGroupOf(_r('d', 'Bowl de pollo')), ProteinGroup.carne);
    expect(proteinGroupOf(_r('e', 'Crema de calabaza')), ProteinGroup.otro);
  });

  final recipes = [
    _r('l1', 'Lentejas'),
    _r('l2', 'Garbanzos'),
    _r('p1', 'Merluza'),
    _r('p2', 'Salmón'),
    _r('h1', 'Tortilla'),
    _r('c1', 'Pollo asado'),
    _r('c2', 'Albóndigas'),
    _r('c3', 'Lomo'),
    _r('c4', 'Pavo'),
    _r('c5', 'Ternera'),
  ];

  Map<String, String> flat(Map<DateTime, Map<String, String>> plan) => {
    for (final d in plan.entries)
      for (final m in d.value.entries) '${d.key}-${m.key}': m.value,
  };

  test('Semana sin lo mismo dos veces el mismo día y sin abusar de carne', () {
    var carneTotal = 0;
    var maxUses = 0;
    for (var seed = 0; seed < 40; seed++) {
      final plan = MealPlanner(seed: seed).generate(
        startDate: DateTime(2026, 10, 12),
        days: 7,
        mealTypes: const ['lunch', 'dinner'],
        recipes: recipes,
      );
      for (final day in plan.values) {
        expect(day['lunch'] == day['dinner'], isFalse);
      }
      final ids = flat(plan).values.toList();
      carneTotal += ids.where((id) => id.startsWith('c')).length;
      for (final r in recipes) {
        final n = ids.where((id) => id == r.id).length;
        if (n > maxUses) maxUses = n;
      }
    }
    // Media de carne por semana cerca de la pauta, no la mitad de las comidas
    // (5 de 10 recetas son carne).
    expect(carneTotal / 40, lessThan(6));
    expect(maxUses, lessThanOrEqualTo(4));
  });

  test('Plan de 4 semanas: la pauta se cumple también la última semana', () {
    var legumbreUltima = 0;
    for (var seed = 0; seed < 200; seed++) {
      final plan = MealPlanner(seed: seed).generate(
        startDate: DateTime(2026, 10, 12),
        days: 28,
        mealTypes: const ['lunch', 'dinner'],
        recipes: recipes,
      );
      expect(plan.length, 28);
      final ultima = [
        for (final e in plan.entries)
          if (!e.key.isBefore(DateTime(2026, 11, 2))) ...e.value.values,
      ];
      legumbreUltima += ultima.where((id) => id.startsWith('l')).length;
    }
    // Pauta de 3 legumbres por semana; sin contar por semana bajaba de 3.
    expect(legumbreUltima / 200, greaterThan(3));
  });

  test('Tandas para un mes: tira más de lo que se congela bien', () {
    final mix = [
      _r('a', 'Caldo de pollo'),
      _r('b', 'Lentejas estofadas'),
      _r('c', 'Ensalada de pasta'),
      _r('d', 'Tortilla francesa'),
      _r('e', 'Merluza al horno'),
      _r('f', 'Pollo a la plancha'),
      _r('g', 'Wok de verduras'),
      _r('h', 'Salmón con patatas'),
    ];
    double congelables({required int days}) {
      var n = 0;
      for (var seed = 0; seed < 100; seed++) {
        final plan = MealPlanner(seed: seed).generate(
          startDate: DateTime(2026, 11, 2),
          days: days,
          mealTypes: const ['lunch', 'dinner'],
          recipes: mix,
          batch: true,
        );
        n += flat(plan).values.where((id) => id == 'a' || id == 'b').length;
      }
      return n / days;
    }

    expect(mix.where((r) => r.freezesWell).map((r) => r.id), ['a', 'b']);
    // Por día, un mes en tandas lleva más platos congelables que una semana.
    expect(congelables(days: 28), greaterThan(congelables(days: 7) * 1.1));
  });

  test('Plan sin comidas ocultas', () {
    const prefs = PlanPrefs(hidden: {'snack', 'breakfast'});
    expect(prefs.planned(['breakfast', 'lunch', 'snack', 'dinner']), [
      'lunch',
      'dinner',
    ]);
    expect(const PlanPrefs().planned(['breakfast', 'lunch']), [
      'breakfast',
      'lunch',
    ]);
  });
}
