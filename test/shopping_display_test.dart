import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/shopping_display.dart';

void main() {
  group('shoppingQtyLabel', () {
    test('gramos', () => expect(shoppingQtyLabel(300, 'g'), '300 g'));
    test('unidades -> ud', () => expect(shoppingQtyLabel(4, 'unidad'), '4 ud'));
    test('un diente (singular)', () {
      expect(shoppingQtyLabel(1, 'diente'), '1 diente');
    });
    test('dos dientes (plural)', () {
      expect(shoppingQtyLabel(2, 'diente'), '2 dientes');
    });
    test(
      'decimal con coma',
      () => expect(shoppingQtyLabel(1.5, 'kg'), '1,5 kg'),
    );
    test('al gusto sin cantidad', () {
      expect(shoppingQtyLabel(null, 'al gusto'), 'al gusto');
    });
    test('sin cantidad ni expresión -> vacío', () {
      expect(shoppingQtyLabel(null, 'g'), '');
    });
  });

  group('inventoryQtyLabel', () {
    test('una unidad (singular)', () {
      expect(inventoryQtyLabel(1, 'unidad'), '1 unidad');
    });
    test('dos unidades (plural)', () {
      expect(inventoryQtyLabel(2, 'unidades'), '2 unidades');
    });
    test('ud se expande a unidad en singular', () {
      expect(inventoryQtyLabel(1, 'ud'), '1 unidad');
    });
    test('gramos', () => expect(inventoryQtyLabel(300, 'g'), '300 g'));
    test('kg con decimal y coma', () {
      expect(inventoryQtyLabel(1.5, 'kg'), '1,5 kg');
    });
    test('un bote (singular)', () {
      expect(inventoryQtyLabel(1, 'bote'), '1 bote');
    });
    test('dos botes (plural)', () {
      expect(inventoryQtyLabel(2, 'bote'), '2 botes');
    });
    test('sin cantidad ni expresión -> vacío', () {
      expect(inventoryQtyLabel(null, 'g'), '');
    });
    test('al gusto sin cantidad', () {
      expect(inventoryQtyLabel(null, 'al gusto'), 'al gusto');
    });
    test('nunca muestra 1.0', () {
      expect(inventoryQtyLabel(1, 'unidad').contains('1.0'), isFalse);
    });
  });

  group('shoppingCleanName', () {
    test('quita la marca Hacendado', () {
      expect(shoppingCleanName('Huevos camperos Hacendado'), 'Huevos camperos');
    });
    test('quita Mercadona y capitaliza', () {
      expect(shoppingCleanName('leche mercadona'), 'Leche');
    });
    test('nombre normal se mantiene (capitalizado)', () {
      expect(shoppingCleanName('espinacas frescas'), 'Espinacas frescas');
    });
    test('si todo era marca, no vacía: devuelve original', () {
      expect(shoppingCleanName('Hacendado'), 'Hacendado');
    });
  });
}
