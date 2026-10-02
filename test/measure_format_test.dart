import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/measure_format.dart';

void main() {
  group('formatQuantityUnit', () {
    test('singular con quantity 1', () {
      expect(formatQuantityUnit(1, 'unidad'), '1 unidad');
    });

    test('pluraliza unidades contables cuando quantity != 1', () {
      expect(formatQuantityUnit(2, 'unidad'), '2 unidades');
      expect(formatQuantityUnit(3, 'cucharadita'), '3 cucharaditas');
      expect(formatQuantityUnit(2, 'diente'), '2 dientes');
    });

    test('cucharadita en singular con quantity 1', () {
      expect(formatQuantityUnit(1, 'cucharadita'), '1 cucharadita');
    });

    test('quantity null devuelve solo la expresion de la unidad', () {
      expect(formatQuantityUnit(null, 'al gusto'), 'al gusto');
      expect(formatQuantityUnit(null, 'a ojo'), 'a ojo');
    });

    test('unidades de peso/volumen nunca se pluralizan', () {
      expect(formatQuantityUnit(200, 'g'), '200 g');
      expect(formatQuantityUnit(500, 'ml'), '500 ml');
      expect(formatQuantityUnit(2, 'kg'), '2 kg');
      expect(formatQuantityUnit(2, 'l'), '2 l');
      expect(formatQuantityUnit(3, 'litros'), '3 litros');
    });

    test('unidad desconocida se deja igual', () {
      expect(formatQuantityUnit(2, 'manojo'), '2 manojo');
    });

    test('entero sin decimales', () {
      expect(formatQuantityUnit(2.0, 'unidad'), '2 unidades');
      expect(formatQuantityUnit(200.0, 'g'), '200 g');
    });

    test('cantidad con decimales se conserva', () {
      expect(formatQuantityUnit(1.5, 'taza'), '1.5 tazas');
    });

    test('sin unidad devuelve solo la cantidad', () {
      expect(formatQuantityUnit(2, ''), '2');
      expect(formatQuantityUnit(2, null), '2');
    });

    test('normaliza acentos: punado/puñado', () {
      expect(formatQuantityUnit(2, 'puñado'), '2 puñados');
      expect(formatQuantityUnit(2, 'punado'), '2 puñados');
    });
  });

  group('pluralizeUnit', () {
    test('pluraliza con quantity != 1', () {
      expect(pluralizeUnit('loncha', 3), 'lonchas');
      expect(pluralizeUnit('rodaja', 2), 'rodajas');
    });

    test('respeta singular con quantity 1', () {
      expect(pluralizeUnit('loncha', 1), 'loncha');
    });

    test('invariables se dejan igual', () {
      expect(pluralizeUnit('g', 5), 'g');
      expect(pluralizeUnit('ml', 5), 'ml');
    });

    test('unidad vacia se deja igual', () {
      expect(pluralizeUnit('', 5), '');
    });
  });
}
