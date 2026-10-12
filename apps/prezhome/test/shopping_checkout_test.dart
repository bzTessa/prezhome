import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/shopping_checkout.dart';

void main() {
  test('isShoppingTask reconoce la tarea de hacer la compra', () {
    expect(isShoppingTask('Hacer la compra'), isTrue);
    expect(isShoppingTask('Compra semanal'), isTrue);
    expect(isShoppingTask('Ir de compras'), isTrue);
    expect(isShoppingTask('Comprobar la caldera'), isFalse);
    expect(isShoppingTask('Fregar los platos'), isFalse);
  });
}
