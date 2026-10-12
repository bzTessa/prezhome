import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/ingredient.dart';
import 'package:prezhome/services/plan_shopping.dart';
import 'package:prezhome/services/product_photo_resolver.dart';

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

  group('shoppingLines', () {
    test('junta duplicados tras pasar a cantidades de súper', () {
      final lines = shoppingLines(const [
        PlanNeed(name: 'Pimienta negra', quantity: 1, unit: 'cucharadita'),
        PlanNeed(name: 'pimienta negra', quantity: 2, unit: 'pizca'),
        PlanNeed(name: 'Arroz', quantity: 200, unit: 'g'),
      ]);
      final pimienta = lines.where(
        (l) => l.name.toLowerCase() == 'pimienta negra',
      );
      expect(pimienta, hasLength(1));
      expect(lines, hasLength(2));
    });
  });

  test('isStockPhoto distingue fotos de banco de las de producto', () {
    expect(isStockPhoto('https://images.unsplash.com/photo-1'), isTrue);
    expect(isStockPhoto('https://images.pexels.com/x.jpg'), isTrue);
    expect(
      isStockPhoto('https://images.openfoodfacts.org/images/products/1.jpg'),
      isFalse,
    );
    expect(isStockPhoto(null), isFalse);
  });
}
