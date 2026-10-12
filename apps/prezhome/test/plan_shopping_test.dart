import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/ingredient.dart';
import 'package:prezhome/services/plan_shopping.dart';

Ingredient ing(String name, double? qty, String? unit) =>
    Ingredient(name: name, quantity: qty, unit: unit);

void main() {
  group('planShoppingNeeds', () {
    test('suma el mismo ingrediente de varias recetas', () {
      final needs = planShoppingNeeds([
        ing('Arroz', 200, 'g'),
        ing('arroz', 300, 'g'),
        ing('Cebolla', 1, 'unidad'),
      ], const []);
      expect(needs, hasLength(2));
      final arroz = needs.firstWhere((n) => n.name == 'Arroz');
      expect(arroz.quantity, 500);
      expect(arroz.unit, 'g');
    });

    test('sin cantidad en alguna receta no inventa la suma', () {
      final needs = planShoppingNeeds([
        ing('Perejil', null, null),
        ing('Perejil', 1, null),
      ], const []);
      expect(needs.single.quantity, isNull);
    });

    test('descuenta lo que hay en casa con la misma unidad', () {
      final needs = planShoppingNeeds(
        [ing('Lentejas', 600, 'g'), ing('Leche', 1, 'l')],
        const [
          PantryStock(name: 'lentejas', quantity: 400, unit: 'g'),
          PantryStock(name: 'Leche', quantity: 2, unit: 'l'),
        ],
      );
      expect(needs.single.name, 'Lentejas');
      expect(needs.single.quantity, 200);
    });

    test('con unidades distintas no descuenta (mejor de más)', () {
      final needs = planShoppingNeeds(
        [ing('Tomate', 3, 'unidad')],
        const [PantryStock(name: 'Tomate', quantity: 500, unit: 'g')],
      );
      expect(needs.single.quantity, 3);
    });

    test('los básicos "siempre en casa" no se compran', () {
      final needs = planShoppingNeeds(
        [ing('Sal', 1, 'pizca'), ing('Aceite de oliva', 2, 'cucharadas')],
        const [PantryStock(name: 'Sal', isStaple: true)],
      );
      expect(needs.map((n) => n.name), ['Aceite de oliva']);
    });
  });
}
