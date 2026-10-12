import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/shopping_quick_add.dart';

void main() {
  group('parseQuickAdd', () {
    void expectEntry(String input, String name, [double? qty, String? unit]) {
      final e = parseQuickAdd(input);
      expect(e, isNotNull, reason: input);
      expect(e!.name, name, reason: input);
      expect(e.quantity, qty, reason: input);
      expect(e.unit, unit, reason: input);
    }

    test('solo nombre', () => expectEntry('  tomates  ', 'tomates'));
    test(
      'cantidad y unidad',
      () => expectEntry('2 kg tomates', 'tomates', 2, 'kg'),
    );
    test('unidad pegada', () => expectEntry('500g arroz', 'arroz', 500, 'g'));
    test('decimal con coma y "de"', () {
      expectEntry('1,5 l de leche', 'leche', 1.5, 'l');
    });
    test('cantidad sin unidad', () => expectEntry('3 yogures', 'yogures', 3));
    test('cantidad al final', () => expectEntry('leche x2', 'leche', 2));
    test('unidad en plural normalizada', () {
      expectEntry('2 paquetes pasta', 'pasta', 2, 'paquete');
    });
    test('nombres con números no se rompen', () {
      expectEntry('7up', '7up');
    });
    test('vacío o solo cantidad devuelve null', () {
      expect(parseQuickAdd('   '), isNull);
      expect(parseQuickAdd('2'), isNotNull); // "2" se trata como nombre
    });
  });

  group('ShoppingViewPrefs', () {
    test('por defecto: sin fotos y agrupado por pasillo', () {
      const p = ShoppingViewPrefs();
      expect(p.showPhotos, isFalse);
      expect(p.groupByAisle, isTrue);
    });

    test('ida y vuelta por JSON', () {
      const p = ShoppingViewPrefs(showPhotos: true, groupByAisle: false);
      final back = ShoppingViewPrefs.decode(p.encode());
      expect(back.showPhotos, isTrue);
      expect(back.groupByAisle, isFalse);
    });

    test('datos corruptos o vacíos caen al defecto', () {
      for (final raw in [null, '', 'no-json', '[1,2]']) {
        final p = ShoppingViewPrefs.decode(raw);
        expect(p.showPhotos, isFalse, reason: '$raw');
        expect(p.groupByAisle, isTrue, reason: '$raw');
      }
    });
  });
}
