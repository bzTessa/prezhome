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

      // Seis días en la nevera es demasiado: se cocina el mismo día.
      expect(plan.cookingDays.single.date, day(6));
      final batch = plan.cookingDays.first.batches.first;
      expect(batch.freezerServings, 0);
      expect(batch.fridgeServings, 3);
      expect(batch.takeOutDate, isNull);
    });

    test('lo no congelable que no aguanta en la nevera se cocina otro día', () {
      final meals = [
        PrepMeal(
          recipeId: 'lentejas',
          date: day(0),
          mealType: 'lunch',
          servings: 2,
        ),
        PrepMeal(
          recipeId: 'ensalada',
          date: day(1),
          mealType: 'dinner',
          servings: 2,
        ),
        PrepMeal(
          recipeId: 'lentejas',
          date: day(5),
          mealType: 'lunch',
          servings: 2,
        ),
        PrepMeal(
          recipeId: 'ensalada',
          date: day(5),
          mealType: 'dinner',
          servings: 2,
        ),
      ];
      final plan = const MealPrepPlanner().buildPlan(
        meals: meals,
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );

      expect([for (final d in plan.cookingDays) d.date], [day(0), day(5)]);
      for (final d in plan.cookingDays) {
        for (final b in d.batches) {
          for (final eat in b.fridgeByDay.keys) {
            expect(
              eat.difference(d.date).inDays,
              lessThanOrEqualTo(kDiasNevera),
            );
          }
        }
      }
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

    test(
      '(d) energyLevel=0 agrupa en menos días de cocción que energyLevel=2',
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
      },
    );

    test('(f) energía alta con días de comida muy dispersos: ningún día de '
        'cocción queda sin tandas', () {
      // Solo tres días con comida, muy separados (lunes, miércoles y domingo).
      // Con energía alta (hasta 3 días de cocción) los bloques podrían caer en
      // días sin comidas propias; el plan NO debe incluir días vacíos.
      final meals = [
        PrepMeal(
          recipeId: 'lentejas',
          date: day(0),
          mealType: 'lunch',
          servings: 2,
        ),
        PrepMeal(
          recipeId: 'pollo',
          date: day(2),
          mealType: 'lunch',
          servings: 2,
        ),
        PrepMeal(
          recipeId: 'lentejas',
          date: day(6),
          mealType: 'dinner',
          servings: 2,
        ),
      ];
      final plan = const MealPrepPlanner().buildPlan(
        meals: meals,
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 2,
      );

      // Todos los días de cocción tienen al menos una tanda y raciones > 0.
      expect(plan.cookingDays, isNotEmpty);
      for (final d in plan.cookingDays) {
        expect(d.batches, isNotEmpty);
        expect(d.totalServings, greaterThan(0));
      }
      // Cada comida se cuece en un día de cocción que no es posterior a ella.
      for (final m in meals) {
        final cocinado = plan.cookingDays.any(
          (d) => !d.date.isAfter(m.date) && d.batches.isNotEmpty,
        );
        expect(cocinado, isTrue);
      }
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

  group('Agenda de la cocina en lote', () {
    test('compra la víspera, nevera/congelador por táper y qué sacar', () {
      final meals = [
        PrepMeal(
          recipeId: 'pollo',
          date: day(0),
          mealType: 'lunch',
          servings: 2,
        ),
        PrepMeal(
          recipeId: 'pollo',
          date: day(5),
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
      final agenda = prepAgenda(plan);
      expect(agenda.map((e) => e.kind), [
        PrepEventKind.compra,
        PrepEventKind.cocina,
        PrepEventKind.sacar,
      ]);
      expect(agenda[0].date, day(-1));
      expect(
        agenda[1].lines.first,
        'Pollo: recién hecho · congelador para el sáb',
      );
      expect(agenda[2].date, day(4));
      expect(agenda[2].lines.single, 'Pollo: 2 tápers para el sábado');
    });

    test('lo que ya pasó no sale en la agenda', () {
      final plan = const MealPrepPlanner().buildPlan(
        meals: [
          PrepMeal(recipeId: 'pollo', date: day(0), mealType: 'lunch'),
          PrepMeal(recipeId: 'pollo', date: day(2), mealType: 'lunch'),
        ],
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );
      expect(prepAgenda(plan, earliest: day(1)), isEmpty);
    });

    test('la compra nunca cae antes de hoy', () {
      final plan = const MealPrepPlanner().buildPlan(
        meals: [PrepMeal(recipeId: 'pollo', date: day(0), mealType: 'lunch')],
        recipesById: recipes,
        weekStart: weekStart,
      );
      final agenda = prepAgenda(plan, earliest: day(0));
      expect(agenda.first.kind, PrepEventKind.compra);
      expect(agenda.first.date, day(0));
    });
  });

  group('Recetas repetidas', () {
    test('una receta que aguanta se cocina toda el primer día', () {
      final plan = const MealPrepPlanner().buildPlan(
        meals: [
          PrepMeal(recipeId: 'lentejas', date: day(0), mealType: 'lunch'),
          PrepMeal(recipeId: 'pollo', date: day(1), mealType: 'lunch'),
          PrepMeal(recipeId: 'pollo', date: day(3), mealType: 'lunch'),
          PrepMeal(recipeId: 'lentejas', date: day(3), mealType: 'lunch'),
          PrepMeal(recipeId: 'ensalada', date: day(5), mealType: 'lunch'),
          PrepMeal(recipeId: 'ensalada', date: day(6), mealType: 'lunch'),
        ],
        recipesById: recipes,
        weekStart: weekStart,
      );
      expect(plan.cookingDays, hasLength(2));
      final first = plan.cookingDays.first.batches.map((b) => b.recipeId);
      final second = plan.cookingDays.last.batches.map((b) => b.recipeId);
      // Lentejas y pollo aguantan en la nevera: se hacen una vez. La ensalada
      // va en su tanda.
      expect(first, containsAll(['lentejas', 'pollo']));
      expect(second, ['ensalada']);
    });
  });

  group('Tápers automáticos', () {
    test('se guardan, se descongelan la víspera y se quitan al comerlos', () {
      final plan = const MealPrepPlanner().buildPlan(
        meals: [
          PrepMeal(
            recipeId: 'pollo',
            date: day(0),
            mealType: 'lunch',
            servings: 2,
          ),
          PrepMeal(
            recipeId: 'pollo',
            date: day(2),
            mealType: 'lunch',
            servings: 2,
          ),
          PrepMeal(
            recipeId: 'pollo',
            date: day(5),
            mealType: 'lunch',
            servings: 2,
          ),
        ],
        recipesById: recipes,
        weekStart: weekStart,
        energyLevel: 0,
      );
      final moves = taperMoves(plan, cookMinute: 13 * 60, thawMinute: 21 * 60);
      expect(
        [for (final m in moves) (m.step, m.at, m.frozen, m.name)],
        [
          (
            TaperStep.guardar,
            DateTime(2025, 10, 6, 13),
            false,
            'Pollo (mié 8)',
          ),
          (
            TaperStep.guardar,
            DateTime(2025, 10, 6, 13),
            true,
            'Pollo (sáb 11)',
          ),
          (TaperStep.comido, DateTime(2025, 10, 9), false, 'Pollo (mié 8)'),
          (
            TaperStep.descongelar,
            DateTime(2025, 10, 10, 21),
            true,
            'Pollo (sáb 11)',
          ),
          (TaperStep.comido, DateTime(2025, 10, 12), true, 'Pollo (sáb 11)'),
        ],
      );
    });
  });
}
