import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/price_memory.dart';
import 'package:prezhome/utils/approx_price.dart';

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
        (name: 'Leche', quantity: 2, unit: 'ud'), // 2 x 1.0 = 2.0
        (name: 'Pan', quantity: null, unit: null), // 1 x 0.8 = 0.8
        (name: 'Agua', quantity: 3, unit: 'l'), // sin precio -> no cuenta
      ], prices);
      expect(est.total, closeTo(2.8, 0.001));
      expect(est.priced, 2);
      expect(est.totalItems, 3);
      // 2 de 3 >= 50% -> fiable
      expect(est.isReliable, isTrue);
    });

    test('sin precios conocidos: total 0 y no fiable', () {
      final est = PriceMemory.estimateCost([
        (name: 'Agua', quantity: 1, unit: 'l'),
      ], prices);
      expect(est.total, 0);
      expect(est.priced, 0);
      expect(est.isReliable, isFalse);
    });

    test('en gramos cuenta un paquete, no precio x gramos', () {
      // Antes: 900 g x 5,60 € = 5.040 €.
      final est = PriceMemory.estimateCost(
        [(name: 'Pechuga de pollo', quantity: 900, unit: 'g')],
        {
          'pechuga de pollo': const ProductPrice(
            nameNormalized: 'pechuga de pollo',
            lastUnitPrice: 5.6,
            samples: 1,
          ),
        },
      );
      expect(est.total, closeTo(5.6, 0.001));
    });

    test('sin ticket usa el aproximado y descarta lo absurdo', () {
      final est = PriceMemory.estimateCost(
        [
          (name: 'Arroz', quantity: 500, unit: 'g'), // 1,3 €/kg -> 0,65 €
          (name: 'Sal', quantity: 1, unit: 'ud'), // 0,50 €
          (name: 'Caviar', quantity: 1, unit: 'ud'), // 100 € (ticket) -> fuera
        ],
        {
          'caviar': const ProductPrice(
            nameNormalized: 'caviar',
            lastUnitPrice: 100,
          ),
        },
      );
      expect(est.total, closeTo(1.15, 0.001));
      expect(est.priced, 2);
    });

    test('la clave normaliza acentos/mayúsculas', () {
      // 'Plátano' normaliza a 'platano'; si no está, no cuenta.
      final est = PriceMemory.estimateCost([
        (name: 'LECHE', quantity: 1, unit: 'ud'),
      ], prices);
      expect(est.priced, 1);
      expect(est.total, closeTo(1.0, 0.001));
    });
  });

  group('computeRecipeCost', () {
    final prices = {
      'leche': const ProductPrice(
        nameNormalized: 'leche',
        lastUnitPrice: 1.0,
        avgUnitPrice: 1.0,
        samples: 2,
      ),
    };
    double? approx(String name, double? q, String? u) =>
        PriceMemory.keyFor(name) == 'leche' ? null : 2.0;

    test('usa precio real si lo hay y aproximado si no (approx=true)', () {
      final cost = computeRecipeCost(
        ingredients: [
          (name: 'Leche', quantity: 2, unit: 'unidad'),
          (name: 'Harina', quantity: 500, unit: 'g'),
        ],
        prices: prices,
        servings: 2,
        approxOf: approx,
      );
      expect(cost.total, closeTo(4.0, 0.001));
      expect(cost.perServing, closeTo(2.0, 0.001));
      expect(cost.approx, isTrue);
    });

    test('solo precios reales: approx=false', () {
      final cost = computeRecipeCost(
        ingredients: [(name: 'Leche', quantity: 3, unit: 'unidad')],
        prices: prices,
        servings: 3,
        approxOf: approx,
      );
      expect(cost.total, closeTo(3.0, 0.001));
      expect(cost.perServing, closeTo(1.0, 0.001));
      expect(cost.approx, isFalse);
    });

    test('en gramos no multiplica el precio del ticket por los gramos', () {
      final cost = computeRecipeCost(
        ingredients: [(name: 'Leche', quantity: 400, unit: 'ml')],
        prices: prices,
        servings: 2,
        approxOf: (_, _, _) => 0.4,
      );
      expect(cost.total, closeTo(0.4, 0.001));
      expect(cost.approx, isTrue);
    });
  });

  group('PriceMemory.mergeShared', () {
    test('rellena los que faltan y no pisa el precio propio', () {
      final own = {
        'leche': const ProductPrice(
          nameNormalized: 'leche',
          lastUnitPrice: 1.1,
          samples: 1,
        ),
      };
      PriceMemory.mergeShared(own, [
        {'name_normalized': 'leche', 'median_unit_price': 0.9, 'homes': 5},
        {'name_normalized': 'pan', 'median_unit_price': 0.85, 'homes': 3},
        {'name_normalized': '', 'median_unit_price': 1, 'homes': 3},
      ]);
      expect(own['leche']!.bestPrice, 1.1);
      expect(own['pan']!.bestPrice, 0.85);
      expect(own.length, 2);
    });
  });

  group('Precios de mercado (Open Prices)', () {
    tearDown(() => ApproxPrice.market = null);

    test('marketFrom agrupa por unidad e ignora filas raras', () {
      final m = PriceMemory.marketFrom([
        {'keyword': 'tomate', 'unit': 'kg', 'median_price': 2.85},
        {'keyword': 'leche', 'unit': 'l', 'median_price': 1.1},
        {'keyword': 'aguacate', 'unit': 'ud', 'median_price': 0.9},
        {'keyword': 'x', 'unit': 'caja', 'median_price': 1},
        {'keyword': '', 'unit': 'kg', 'median_price': 1},
      ]);
      expect(m.kg, {'tomate': 2.85});
      expect(m.l, {'leche': 1.1});
      expect(m.ud, {'aguacate': 0.9});
    });

    test('ApproxPrice usa el precio de mercado antes que la tabla fija', () {
      final fixed = ApproxPrice.estimate('Tomate', 1000, 'g')!;
      ApproxPrice.market = (kg: {'tomate': 3.0}, l: {}, ud: {});
      expect(ApproxPrice.estimate('Tomate', 1000, 'g'), closeTo(3.0, 1e-9));
      expect(fixed, isNot(closeTo(3.0, 1e-9)));
      // Sin precio de mercado para ese alimento, sigue la tabla fija.
      expect(ApproxPrice.estimate('Cebolla', 1000, 'g'), closeTo(1.3, 1e-9));
    });
  });
}
