import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/practical_quantity.dart';

void main() {
  group('makePractical', () {
    test('gramos grandes se redondean a múltiplos de 50', () {
      final r = makePractical('garbanzos cocidos de bote', 1060, 'g');
      expect(r.unit, 'g');
      // 1060 -> múltiplo de 50 más cercano = 1050
      expect(r.quantity, 1050);
    });

    test('gramos cuadran al formato de venta cuando se conoce', () {
      // Bote de 400 g: 1060 g -> 1200 g (3 botes), cantidad comprable.
      final r = makePractical(
        'garbanzos cocidos de bote',
        1060,
        'g',
        packageGrams: 400,
      );
      expect(r.unit, 'g');
      expect(r.quantity, 1200);
    });

    test('aceite en ml pequeño pasa a cucharadas', () {
      final r = makePractical('aceite de oliva virgen extra', 53, 'ml');
      expect(r.unit, 'cucharada');
      // 53 / 15 ≈ 3.5 -> 4 cucharadas
      expect(r.quantity, 4);
    });

    test('dientes de ajo se redondean a entero', () {
      final r = makePractical('ajo', 5.5, 'diente');
      expect(r.unit, 'diente');
      expect(r.quantity, 6);
    });

    test('cantidad null (al gusto) se mantiene', () {
      final r = makePractical('sal', null, 'al gusto');
      expect(r.quantity, isNull);
      expect(r.unit, 'al gusto');
    });

    test('unidades contables nunca bajan de 1', () {
      final r = makePractical('huevo', 0.3, 'unidad');
      expect(r.quantity, 1);
      expect(r.unit, 'unidad');
    });

    test('gramos medianos se redondean a 25', () {
      final r = makePractical('jamón serrano en taquitos', 121, 'g');
      expect(r.unit, 'g');
      // 121 -> múltiplo de 25 más cercano = 125
      expect(r.quantity, 125);
    });

    test('cucharaditas de especia se redondean a medios', () {
      final r = makePractical('pimentón dulce', 2.4, 'cucharadita');
      expect(r.unit, 'cucharadita');
      expect(r.quantity, 2.5);
    });
  });
}
