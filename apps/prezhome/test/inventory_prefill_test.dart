import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/food_facts_service.dart';
import 'package:prezhome/services/inventory_prefill.dart';
import 'package:prezhome/services/shelf_life.dart';

void main() {
  group('inventoryPrefillFromFoodFacts', () {
    test('found:false devuelve null (alta manual vacía)', () {
      expect(inventoryPrefillFromFoodFacts(FoodFacts.notFound), isNull);
    });

    test('producto encontrado mapea nombre, cantidad, unidad y ubicación', () {
      const facts = FoodFacts(
        found: true,
        productName: 'Leche entera',
        packageQuantity: 1000,
        packageUnit: 'ml',
      );
      final pre = inventoryPrefillFromFoodFacts(facts);
      expect(pre, isNotNull);
      expect(pre!.name, 'Leche entera');
      expect(pre.quantity, 1000);
      expect(pre.unit, 'ml');
      // La ubicación/categoría salen del helper real de la app.
      final expected = ShelfLife.suggestLocation('Leche entera');
      expect(pre.location, expected);
      expect(pre.category, expected);
    });

    test('unidad g se conserva como g', () {
      const facts = FoodFacts(
        found: true,
        productName: 'Garbanzos cocidos',
        packageQuantity: 400,
        packageUnit: 'g',
      );
      final pre = inventoryPrefillFromFoodFacts(facts);
      expect(pre!.unit, 'g');
      expect(pre.quantity, 400);
    });

    test('unidad nula o desconocida cae a "unidades"', () {
      const nullUnit = FoodFacts(found: true, productName: 'Atún en lata');
      expect(inventoryPrefillFromFoodFacts(nullUnit)!.unit, 'unidades');

      const unknownUnit = FoodFacts(
        found: true,
        productName: 'Pack de yogures',
        packageUnit: 'cl',
      );
      expect(inventoryPrefillFromFoodFacts(unknownUnit)!.unit, 'unidades');
    });

    test('nombre vacío o en blanco: name null y categoría por defecto', () {
      const blank = FoodFacts(found: true, productName: '   ');
      final pre = inventoryPrefillFromFoodFacts(blank);
      expect(pre, isNotNull);
      expect(pre!.name, isNull);
      expect(pre.location, isNull);
      expect(pre.category, 'Despensa');
    });
  });
}
