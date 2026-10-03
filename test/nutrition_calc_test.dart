import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/nutrition_calc.dart';

void main() {
  group('gramsOf', () {
    test('gramos directos', () => expect(gramsOf(200, 'g'), 200));
    test('ml como gramos (densidad ~1)', () => expect(gramsOf(500, 'ml'), 500));
    test('kg a gramos', () => expect(gramsOf(1, 'kg'), 1000));
    test('litros a gramos', () => expect(gramsOf(2, 'litros'), 2000));
    test('unidades contables no convertibles', () {
      expect(gramsOf(2, 'unidad'), isNull);
      expect(gramsOf(3, 'diente'), isNull);
    });
    test('sin cantidad', () => expect(gramsOf(null, 'g'), isNull));
  });

  group('computeRecipeNutrition', () {
    test('suma ingredientes con datos y divide por raciones', () {
      // 400 g garbanzos (90 kcal/100g) + 200 g espinacas (23 kcal/100g)
      // = 360 + 46 = 406 kcal totales. Para 2 raciones = 203 kcal/ración.
      final ings = [
        const NutriIngredient(
          quantity: 400,
          unit: 'g',
          per100g: Per100g(kcal: 90, protein: 5.5, carbs: 9.5, fat: 2.2),
        ),
        const NutriIngredient(
          quantity: 200,
          unit: 'g',
          per100g: Per100g(kcal: 23, protein: 2.9, carbs: 3.6, fat: 0.4),
        ),
      ];
      final r = computeRecipeNutrition(ings, 2);
      expect(r.kcal, 203);
      expect(r.covered, 2);
      expect(r.total, 2);
      expect(r.isReliable, isTrue);
    });

    test('omite ingredientes sin datos o no convertibles', () {
      final ings = [
        const NutriIngredient(
          quantity: 100,
          unit: 'g',
          per100g: Per100g(kcal: 100),
        ),
        const NutriIngredient(quantity: 2, unit: 'unidad', per100g: null),
        const NutriIngredient(
          quantity: 1,
          unit: 'diente',
          per100g: Per100g(kcal: 150),
        ), // tiene datos pero no es convertible a gramos
      ];
      final r = computeRecipeNutrition(ings, 1);
      expect(r.kcal, 100); // solo cuenta el primero
      expect(r.covered, 1);
      expect(r.total, 3);
      expect(r.isReliable, isFalse); // 1 de 3 < 60%
    });

    test('raciones minimo 1', () {
      final ings = [
        const NutriIngredient(
          quantity: 100,
          unit: 'g',
          per100g: Per100g(kcal: 200),
        ),
      ];
      final r = computeRecipeNutrition(ings, 0);
      expect(r.kcal, 200);
    });
  });
}
