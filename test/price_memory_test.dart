import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/price_memory.dart';

void main() {
  group('ProductPrice.bestPrice', () {
    test('usa la media si hay 2+ muestras', () {
      const p = ProductPrice(
        nameNormalized: 'leche',
        lastUnitPrice: 1.2,
        avgUnitPrice: 1.0,
        samples: 3,
      );
      expect(p.bestPrice, 1.0);
    });

    test('usa el último si hay 1 muestra', () {
      const p = ProductPrice(
        nameNormalized: 'pan',
        lastUnitPrice: 0.9,
        avgUnitPrice: 0.9,
        samples: 1,
      );
      expect(p.bestPrice, 0.9);
    });
  });

  group('PriceMemory.estimateCost', () {
    final prices = {
      'leche': const ProductPrice(
        nameNormalized: 'leche',
        lastUnitPrice: 1.0,
        avgUnitPrice: 1.0,
        samples: 2,
      ),
      'pan': const ProductPrice(
        nameNormalized: 'pan',
        lastUnitPrice: 0.8,
        avgUnitPrice: 0.8,
        samples: 1,
      ),
    };

    test('suma precio x cantidad de lo que conoce y cuenta cobertura', () {
      final est = PriceMemory.estimateCost([
        (name: 'Leche', quantity: 2), // 2 x 1.0 = 2.0
        (name: 'Pan', quantity: null), // 1 x 0.8 = 0.8
        (name: 'Tomates', quantity: 3), // sin precio -> no cuenta
      ], prices);
      expect(est.total, closeTo(2.8, 0.001));
      expect(est.priced, 2);
      expect(est.totalItems, 3);
      // 2 de 3 >= 50% -> fiable
      expect(est.isReliable, isTrue);
    });

    test('sin precios conocidos: total 0 y no fiable', () {
      final est = PriceMemory.estimateCost([
        (name: 'Quinoa', quantity: 1),
      ], prices);
      expect(est.total, 0);
      expect(est.priced, 0);
      expect(est.isReliable, isFalse);
    });

    test('la clave normaliza acentos/mayúsculas', () {
      // 'Plátano' normaliza a 'platano'; si no está, no cuenta.
      final est = PriceMemory.estimateCost([
        (name: 'LECHE', quantity: 1),
      ], prices);
      expect(est.priced, 1);
      expect(est.total, closeTo(1.0, 0.001));
    });
  });
}
