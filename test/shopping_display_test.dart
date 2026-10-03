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
