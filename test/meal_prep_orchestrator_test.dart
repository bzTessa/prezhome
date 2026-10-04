import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/meal_prep_orchestrator.dart';

/// Tests del orquestador de batch cooking (lógica pura). Usamos recetas con
/// datos FIJOS para que la agrupación por aparato, el orden y las duraciones
/// sean deterministas, siguiendo el patrón de test/meal_prep_planner_test.dart.
void main() {
  const orquestador = MealPrepOrchestrator();

  // Dos platos al horno con tiempos de cocción distintos.
  const lasana = OrchestratorRecipe(
    id: 'lasana',
    title: 'lasaña',
    appliance: 'oven',
    prepTimeMinutes: 20,
    cookTimeMinutes: 40,
    instructions: '1. Haz la bechamel\n2. Monta las capas',
  );
  const polloHorno = OrchestratorRecipe(
    id: 'pollo',
    title: 'pollo asado',
    appliance: 'oven',
    prepTimeMinutes: 10,
    cookTimeMinutes: 50,
    instructions: 'Salpimenta el pollo',
  );
  const arrozOlla = OrchestratorRecipe(
    id: 'arroz',
    title: 'arroz',
    appliance: 'pot',
    prepTimeMinutes: 5,
    cookTimeMinutes: 18,
    instructions: 'Lava el arroz',
  );
  const ensalada = OrchestratorRecipe(
    id: 'ensalada',
    title: 'ensalada',
    appliance: 'none',
    prepTimeMinutes: 10,
    instructions: '- Corta los tomates\n- Aliña',
  );

  group('Agrupación de cocción por aparato', () {
    test('(1) dos recetas con horno se fusionan en UN bloque con ambos títulos '
        'y duración = el máximo de las cocciones', () {
      final plan = orquestador.buildTimeline(
        recipes: const [lasana, polloHorno],
      );

      final bloques = plan.steps
          .where((s) => !s.isPrep && s.appliance == 'oven')
          .toList();
      expect(bloques, hasLength(1));
      final bloque = bloques.first;
      expect(bloque.recipeTitles, containsAll(['lasaña', 'pollo asado']));
      expect(bloque.recipeTitles, hasLength(2));
      // Máximo de 40 y 50 => 50, NO la suma (90).
      expect(bloque.durationMinutes, 50);
      expect(bloque.agrupaVariasRecetas, isTrue);
    });

    test('(2) recetas con aparatos distintos NO se fusionan', () {
      final plan = orquestador.buildTimeline(
        recipes: const [lasana, arrozOlla],
      );

      final cocciones = plan.steps.where((s) => !s.isPrep).toList();
      expect(cocciones, hasLength(2));
      final aparatos = cocciones.map((s) => s.appliance).toSet();
      expect(aparatos, containsAll(['oven', 'pot']));
      // Ningún bloque agrupa varias recetas.
      expect(cocciones.every((s) => s.recipeTitles.length == 1), isTrue);
    });
  });

  group('Paralelismo y orden', () {
    test('(3) una preparación se marca canRunInParallel mientras un aparato '
        'está ocupado', () {
      final plan = orquestador.buildTimeline(
        recipes: const [polloHorno, ensalada],
      );

      // La ensalada (appliance none) debe poder solapar con el pollo al horno.
      final pasosEnsalada = plan.steps
          .where((s) => s.isPrep && s.recipeTitles.contains('ensalada'))
          .toList();
      expect(pasosEnsalada, isNotEmpty);
      expect(pasosEnsalada.every((s) => s.canRunInParallel), isTrue);
    });

    test('(4) orden determinista: lo que más tarda va primero', () {
      // pollo total = 60, lasaña total = 60, arroz total = 23. A igualdad de
      // tiempo (pollo/lasaña = 60) desempata por id ('lasana' < 'pollo').
      final plan = orquestador.buildTimeline(
        recipes: const [arrozOlla, polloHorno, lasana],
      );

      final cocciones = plan.steps.where((s) => !s.isPrep).toList();
      // El bloque del horno (lasaña+pollo, los de mayor tiempo) va antes que la
      // olla del arroz.
      expect(cocciones.first.appliance, 'oven');
      expect(cocciones.last.appliance, 'pot');
    });

    test('(5) totalEstimatedMinutes refleja el solape (menor que la suma en '
        'serie)', () {
      final plan = orquestador.buildTimeline(
        recipes: const [lasana, polloHorno],
      );

      // Suma ingenua en serie de todas las duraciones.
      final sumaSerie = plan.steps.fold<int>(
        0,
        (s, step) => s + step.durationMinutes,
      );
      expect(plan.totalEstimatedMinutes, lessThan(sumaSerie));
      // El bloque de cocción (50) sí cuenta; las preparaciones solapan y no.
      expect(plan.totalEstimatedMinutes, 50);
    });

    test('(5b) con preparación dominante el total NO baja del tiempo de prep '
        'real (el solape se acota al tiempo de aparato disponible)', () {
      // Mucha preparación (60 min) y poca cocción (10 min): la prep no cabe
      // en los 10 min de aparato, así que el total debe reflejar la prep real,
      // no quedarse en los 10 min de cocción.
      const prepDominante = OrchestratorRecipe(
        id: 'guiso',
        title: 'guiso lento',
        appliance: 'pot',
        prepTimeMinutes: 60,
        cookTimeMinutes: 10,
        instructions: 'Pica mucha verdura',
      );
      final plan = orquestador.buildTimeline(recipes: const [prepDominante]);

      // Solo cabe solapar 10 min de prep dentro de la cocción; el resto va en
      // serie. total = max(cocción 10, prep 60) = 60, nunca 10.
      expect(plan.totalEstimatedMinutes, 60);
      expect(plan.totalEstimatedMinutes, greaterThan(10));
    });
  });

  group('Derivación de pasos sin inventar', () {
    test('(6) receta sin instructions produce un paso "Preparar <título>"', () {
      const sinPasos = OrchestratorRecipe(
        id: 'crema',
        title: 'crema',
        appliance: 'none',
        prepTimeMinutes: 15,
      );
      final plan = orquestador.buildTimeline(recipes: const [sinPasos]);

      final prep = plan.steps.where((s) => s.isPrep).toList();
      expect(prep, hasLength(1));
      expect(prep.first.title, 'Preparar crema');
      expect(prep.first.durationMinutes, 15);
    });

    test(
      '(6b) las instrucciones se dividen por líneas quitando numeración',
      () {
        final plan = orquestador.buildTimeline(recipes: const [lasana]);
        final prep = plan.steps
            .where((s) => s.isPrep && s.recipeTitles.contains('lasaña'))
            .toList();
        expect(prep, hasLength(2));
        expect(
          prep.map((s) => s.title),
          containsAll(['Haz la bechamel', 'Monta las capas']),
        );
      },
    );
  });

  group('Casos borde', () {
    test('(7) appliance "none" nunca se agrupa por aparato', () {
      const otra = OrchestratorRecipe(
        id: 'gazpacho',
        title: 'gazpacho',
        appliance: 'none',
        prepTimeMinutes: 10,
        instructions: 'Tritura todo',
      );
      final plan = orquestador.buildTimeline(recipes: const [ensalada, otra]);

      // No hay pasos de cocción (todo es prep sin aparato).
      final cocciones = plan.steps.where((s) => !s.isPrep).toList();
      expect(cocciones, isEmpty);
      // Y ningún paso agrupa varias recetas.
      expect(plan.steps.every((s) => s.recipeTitles.length == 1), isTrue);
    });

    test('(8) una sola receta produce una timeline directa sin agrupación', () {
      final plan = orquestador.buildTimeline(recipes: const [lasana]);

      final cocciones = plan.steps.where((s) => !s.isPrep).toList();
      expect(cocciones, hasLength(1));
      expect(cocciones.first.agrupaVariasRecetas, isFalse);
      expect(cocciones.first.recipeTitles, ['lasaña']);
    });

    test('(9) recetas sin tiempos: duraciones a 0 y total 0', () {
      const sinTiempos = OrchestratorRecipe(
        id: 'sopa',
        title: 'sopa',
        appliance: 'pot',
        instructions: 'Hierve el agua',
      );
      final plan = orquestador.buildTimeline(recipes: const [sinTiempos]);

      expect(plan.steps.every((s) => s.durationMinutes == 0), isTrue);
      expect(plan.totalEstimatedMinutes, 0);
    });

    test('(10) sin recetas devuelve una timeline vacía', () {
      final plan = orquestador.buildTimeline(recipes: const []);
      expect(plan.isEmpty, isTrue);
      expect(plan.totalEstimatedMinutes, 0);
    });
  });

  group('Resumen cercano', () {
    test(
      '(11) el resumen menciona el aparato compartido y nunca dice "IA"',
      () {
        final plan = orquestador.buildTimeline(
          recipes: const [lasana, polloHorno],
        );
        final resumen = resumenTimeline(plan);

        expect(resumen, contains('el horno'));
        expect(resumen, contains('lasaña'));
        expect(resumen, contains('pollo asado'));
        expect(resumen.toLowerCase(), isNot(contains('inteligencia')));
        expect(resumen, isNot(contains('IA')));
        expect(resumen, isNot(contains('AI')));
      },
    );

    test(
      '(12) el resumen de un plan vacío usa lenguaje de "plan de cocina"',
      () {
        final resumen = resumenTimeline(const TimelinePlan(steps: []));
        expect(resumen, contains('plan de cocina'));
        expect(resumen, isNot(contains('IA')));
      },
    );
  });
}
