import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/meal_prep_planner.dart';

/// Tests de la logística del meal prep (lógica pura). Usamos una SEMANA FIJA
/// (lunes 6 de octubre de 2025) para que las fechas de nevera/congelador y de
/// "sacar del congelador" sean deterministas, siguiendo el patrón de
/// test/inventory_expiry_test.dart.
void main() {
  // Lunes 6/10/2025 como inicio de semana fijo.
  final weekStart = DateTime(2025, 10, 6);
  DateTime day(int offset) => weekStart.add(Duration(days: offset));

  const lentejas = PrepRecipe(
    id: 'lentejas',
    title: 'lentejas',
    freezable: true,
    cookTimeMinutes: 60,
  );
  const pollo = PrepRecipe(
    id: 'pollo',
    title: 'pollo',
    freezable: true,
    cookTimeMinutes: 30,
  );
  const ensalada = PrepRecipe(
    id: 'ensalada',
    title: 'ensalada',
    freezable: false,
    prepTimeMinutes: 10,
  );

  final recipes = <String, PrepRecipe>{
    'lentejas': lentejas,
    'pollo': pollo,
    'ensalada': ensalada,
  };

  group('Clasificación nevera vs congelador', () {
    test('(a) plato freezable con consumo lejano va a congelador y da fecha de '
        'sacar correcta', () {
      // Cocinamos el lunes (día 0); consumo el viernes (día 4) => lejano.
      final meals = [
        PrepMeal(
          recipeId: 'pollo',
          date: day(4),
          mealType: 'lunch',
          servings: 2,
        ),
      ];
      final plan = const MealPrepPlanner().buildPlan(
        meals: meals,
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );

      expect(plan.cookingDays, hasLength(1));
      final batch = plan.cookingDays.first.batches.first;
      expect(batch.recipeId, 'pollo');
      expect(batch.freezerServings, 2);
      expect(batch.fridgeServings, 0);
      // Consumo día 4, se saca 1 día antes => día 3 (jueves).
      expect(batch.takeOutDate, day(3));
    });

    test('(b) consumo en <=3 días va a la nevera', () {
      // Cocinamos el lunes (día 0); consumo el jueves (día 3) => dentro de 3.
      final meals = [
        PrepMeal(
          recipeId: 'lentejas',
          date: day(3),
          mealType: 'lunch',
          servings: 4,
        ),
      ];
      final plan = const MealPrepPlanner().buildPlan(
        meals: meals,
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );

      final batch = plan.cookingDays.first.batches.first;
      expect(batch.fridgeServings, 4);
      expect(batch.freezerServings, 0);
      expect(batch.takeOutDate, isNull);
    });

    test('(c) una receta no freezable nunca va al congelador aunque el consumo '
        'sea lejano', () {
      final meals = [
        PrepMeal(
          recipeId: 'ensalada',
          date: day(6),
          mealType: 'dinner',
          servings: 3,
        ),
      ];
      final plan = const MealPrepPlanner().buildPlan(
        meals: meals,
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );

      final batch = plan.cookingDays.first.batches.first;
      expect(batch.freezerServings, 0);
      expect(batch.fridgeServings, 3);
      expect(batch.takeOutDate, isNull);
    });
  });

  group('Efecto del nivel de energía en los días de cocción', () {
    // Comidas repartidas por toda la semana (lunes a domingo).
    List<PrepMeal> semanaCompleta() => [
          for (var i = 0; i < 7; i++)
            PrepMeal(
              recipeId: i.isEven ? 'lentejas' : 'pollo',
              date: day(i),
              mealType: 'lunch',
              servings: 2,
            ),
        ];

    test('(d) energyLevel=0 agrupa en menos días de cocción que energyLevel=2',
        () {
      final planBajo = const MealPrepPlanner().buildPlan(
        meals: semanaCompleta(),
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );
      final planAlto = const MealPrepPlanner().buildPlan(
        meals: semanaCompleta(),
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 2,
      );

      expect(planBajo.cookingDays.length, 1);
      expect(
        planAlto.cookingDays.length,
        greaterThan(planBajo.cookingDays.length),
      );
    });
  });

  group('Resumen cozy', () {
    test('(e) el resumen menciona las raciones (xN) y el día de sacar del '
        'congelador', () {
      // Lunes: lentejas (consumo cercano, nevera) + pollo (consumo lejano,
      // congelador) para ejercitar ambas ramas en una sola frase.
      final meals = [
        PrepMeal(
          recipeId: 'lentejas',
          date: day(1),
          mealType: 'lunch',
          servings: 6,
        ),
        PrepMeal(
          recipeId: 'pollo',
          date: day(5),
          mealType: 'lunch',
          servings: 4,
        ),
      ];
      final plan = const MealPrepPlanner().buildPlan(
        meals: meals,
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );
      final resumen = resumenPlanCoccion(plan);

      // Raciones con el formato (xN).
      expect(resumen, contains('(x6)'));
      expect(resumen, contains('(x4)'));
      // Reparto nevera/congelador.
      expect(resumen, contains('a la nevera'));
      expect(resumen, contains('al congelador'));
      // Aviso de sacar del congelador: consumo día 5 (sábado) => sacar 1 día
      // antes => viernes.
      expect(resumen, contains('Saca pollo el viernes'));
    });
  });
}
