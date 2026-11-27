import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/services/product_search_service.dart';
import 'package:prezhome/services/store_comparison.dart';
import 'package:prezhome/widgets/shopping/store_comparison_sheet.dart';

SupermarketProduct p(
  String store,
  String name,
  double price, {
  String? size,
  double? unitPrice,
  String? unit,
  String? brand,
  String? ean,
}) => SupermarketProduct(
  code: '$store:$name$size',
  name: name,
  brand: brand,
  quantity: size,
  price: price,
  unitPrice: unitPrice,
  unit: unit,
  ean: ean,
);

void main() {
  group('comparisonSearchQuery y comparisonRelaxedQuery', () {
    test('quita marcas blancas y porciones iniciales conservando variante', () {
      expect(
        comparisonSearchQuery('Aceite de oliva virgen extra Hacendado'),
        'aceite de oliva virgen extra',
      );
      expect(
        comparisonSearchQuery('Huevos camperos Milbona'),
        'huevos camperos',
      );
      expect(comparisonSearchQuery('Diente de ajo'), 'ajo');
      expect(
        comparisonSearchQuery('Bote de garbanzos cocidos Consum'),
        'garbanzos cocidos',
      );
    });

    test('relaja modificadores opcionales sin tocar palabras clave', () {
      expect(comparisonRelaxedQuery('espinacas frescas'), 'espinacas');
      expect(
        comparisonRelaxedQuery('garbanzos cocidos de bote'),
        'garbanzos cocidos',
      );
      expect(comparisonRelaxedQuery('leche'), isNull);
    });
  });

  group('effectiveMeasure y effectiveUnitPrice', () {
    test('lee tamaño desde size, nombre o price/unitPrice', () {
      final m1 = effectiveMeasure(p('m', 'Leche', 0.9, size: '1 l'));
      expect(m1, (qty: 1000.0, unit: 'ml'));

      final m2 = effectiveMeasure(p('consum', 'Arroz Redondo 1 Kg', 1.25));
      expect(m2, (qty: 1000.0, unit: 'g'));

      final m3 = effectiveMeasure(
        p('consum', 'Aceite Oliva', 7.94, unitPrice: 15.88, unit: 'l'),
      );
      expect(m3!.unit, 'ml');
      expect(m3.qty, closeTo(500.0, 1e-3));
    });

    test('usa unitPrice del catálogo o lo calcula desde el envase', () {
      final up1 = effectiveUnitPrice(
        p('m', 'Aceite 1 L', 4.10, unitPrice: 4.10, unit: 'l'),
      );
      expect(up1, (pricePerBase: 4.10, displayUnit: 'L'));

      final up2 = effectiveUnitPrice(p('ahorramas', 'Arroz 500 g', 0.90));
      expect(up2!.displayUnit, 'kg');
      expect(up2.pricePerBase, closeTo(1.80, 1e-6));
    });
  });

  group('packsNeeded', () {
    test('a peso o volumen: cantidad entre envase, hacia arriba', () {
      expect(
        packsNeeded((
          name: 'Leche',
          quantity: 2,
          unit: 'l',
        ), p('m', 'Leche entera', 0.9, size: '1 l')),
        2,
      );
      expect(
        packsNeeded((
          name: 'Arroz',
          quantity: 1500,
          unit: 'g',
        ), p('m', 'Arroz redondo', 1.2, size: '1 kg')),
        2,
      );
    });

    test('sin formato, el tamaño se lee del nombre (Consum)', () {
      expect(
        packsNeeded((
          name: 'Leche',
          quantity: 2,
          unit: 'l',
        ), p('consum', 'Leche Entera Brik 1 L', 0.96)),
        2,
      );
    });

    test('unidades con formato de varias: "6 huevos" es una docena', () {
      expect(
        packsNeeded((
          name: 'Huevos',
          quantity: 6,
          unit: 'ud',
        ), p('m', 'Huevos grandes', 2.5, size: '12 ud')),
        1,
      );
    });

    test('sin cantidad o con precio de ticket, un envase', () {
      expect(
        packsNeeded((
          name: 'Pan',
          quantity: null,
          unit: null,
        ), p('m', 'Pan', 1)),
        1,
      );
      final ticket = SupermarketProduct(
        code: 'dia:ticket:huevos',
        name: 'huevos',
        price: 2.8,
      );
      expect(isTicketPrice(ticket), isTrue);
      expect(packsNeeded((name: 'Huevos', quantity: 6, unit: 'ud'), ticket), 1);
    });
  });

  group('pickBasketLine', () {
    test('elige el más barato para la cantidad pedida', () {
      final line = pickBasketLine(
        0,
        (name: 'Leche', quantity: 3, unit: 'l'),
        [
          p('m', 'Leche', 1.0, size: '1 l'),
          p('m', 'Leche', 1.4, size: '1.5 l'),
        ],
      );
      // 3 × 1,00 = 3,00 frente a 2 × 1,40 = 2,80.
      expect(line!.product.price, 1.4);
      expect(line.packs, 2);
      expect(line.checkoutCost, closeTo(2.8, 1e-9));
    });

    test('nada que no sea el producto', () {
      expect(
        pickBasketLine(
          0,
          (name: 'Leche', quantity: null, unit: null),
          [p('m', 'Chocolate con leche', 1.0)],
        ),
        isNull,
      );
    });

    test('prefiere variante normal antes que especialidad si existe', () {
      final line = pickBasketLine(
        0,
        (name: 'Leche semidesnatada Hacendado', quantity: null, unit: null),
        [
          p('consum', 'Leche Sin Lactosa Semidesnatada 1 L', 0.90, size: '1 l'),
          p('consum', 'Leche Semidesnatada Brik 1 L', 0.95, size: '1 l'),
        ],
      );
      expect(line!.product.name, 'Leche Semidesnatada Brik 1 L');
    });
  });

  group('compareBaskets (misma cantidad y formato)', () {
    test('no deja que un mini-envase de 200 ml gane a 1 L y normaliza €/L', () {
      final items = <BasketItem>[
        (
          name: 'Aceite de oliva virgen extra Hacendado',
          quantity: 1,
          unit: 'ud',
        ),
        (name: 'Leche semidesnatada', quantity: null, unit: null),
      ];
      final c = compareBaskets(items, {
        'mercadona': {
          0: [
            p(
              'mercadona',
              'Aceite de oliva virgen extra Hacendado',
              2.60,
              size: '0.2 l',
              unitPrice: 13.0,
              unit: 'l',
            ),
            p(
              'mercadona',
              'Aceite de oliva virgen extra Hacendado',
              4.10,
              size: '1 l',
              unitPrice: 4.10,
              unit: 'l',
            ),
            p(
              'mercadona',
              'Aceite de oliva virgen extra Hacendado',
              11.25,
              size: '3 l',
              unitPrice: 3.75,
              unit: 'l',
            ),
          ],
          1: [
            p(
              'mercadona',
              'Leche semidesnatada Hacendado',
              0.88,
              size: '1 l',
              unitPrice: 0.88,
              unit: 'l',
            ),
          ],
        },
        'consum': {
          0: [
            p(
              'consum',
              'Atún Claro Aceite Oliva Virgen Extra 3 x 52 Gr',
              4.49,
              unitPrice: 28.78,
              unit: 'kg',
            ),
            p(
              'consum',
              'Aceite de Oliva Virgen Extra 1 L',
              7.15,
              unitPrice: 7.15,
              unit: 'l',
            ),
          ],
          1: [
            p(
              'consum',
              'Leche Semidesnatada Brik 1 L',
              0.83,
              unitPrice: 0.83,
              unit: 'l',
            ),
          ],
        },
        'lidl': {
          0: [
            p(
              'lidl',
              'Aceite de oliva virgen extra 500 ml',
              4.59,
              size: '500 ml',
            ),
          ],
          1: [p('lidl', 'Leche semidesnatada 1 L', 0.90, size: '1 l')],
        },
      });

      final mLine = c.ranked
          .firstWhere((b) => b.store == 'mercadona')
          .lines[0]!;
      expect(mLine.product.quantity, '1 l');
      expect(mLine.cost, closeTo(4.10, 1e-6));

      final lLine = c.ranked.firstWhere((b) => b.store == 'lidl').lines[0]!;
      expect(lLine.sizeAdjusted, isTrue);
      expect(lLine.packs, 2);
      expect(lLine.cost, closeTo(9.18, 1e-6));
    });

    test('normaliza envases distintos (500 g vs 1 kg) en Misma cantidad', () {
      final items = <BasketItem>[
        (name: 'Arroz', quantity: null, unit: null),
        (name: 'Tomate', quantity: null, unit: null),
      ];
      final c = compareBaskets(items, {
        'a': {
          0: [p('a', 'Arroz 500 g', 0.90)], // 1,80 €/kg
          1: [p('a', 'Tomate 1 kg', 1.50)],
        },
        'b': {
          0: [p('b', 'Arroz 1 kg', 1.30)], // 1,30 €/kg
          1: [p('b', 'Tomate 1 kg', 1.50)],
        },
      });
      final b = c.rankedFor(CompareBasis.sameQuantity);
      expect(b.first.store, 'b');
    });

    test('ordena por el total de lo que hay en todos', () {
      final items = <BasketItem>[
        (name: 'Leche', quantity: null, unit: null),
        (name: 'Pan', quantity: null, unit: null),
        (name: 'Tomate', quantity: null, unit: null),
      ];
      final c = compareBaskets(items, {
        'caro': {
          0: [p('caro', 'Leche', 1.2)],
          1: [p('caro', 'Pan', 1.0)],
          2: [p('caro', 'Tomate', 2.0)],
        },
        'barato': {
          0: [p('barato', 'Leche', 0.9)],
          1: [p('barato', 'Pan', 0.8)],
        },
      });
      expect(c.ranked.map((b) => b.store), ['barato', 'caro']);
      expect(c.common, {0, 1});
      expect(c.comparableTotal(c.ranked.first), closeTo(1.7, 1e-9));
      expect(c.extraOver(c.ranked.last), closeTo(0.5, 1e-9));
      expect(c.ranked.last.total, closeTo(4.2, 1e-9));
    });

    test('los súpers con muy pocos productos van aparte', () {
      final items = <BasketItem>[
        (name: 'Leche', quantity: null, unit: null),
        (name: 'Pan', quantity: null, unit: null),
        (name: 'Tomate', quantity: null, unit: null),
      ];
      final c = compareBaskets(items, {
        'completo': {
          0: [p('completo', 'Leche', 1)],
          1: [p('completo', 'Pan', 1)],
          2: [p('completo', 'Tomate', 1)],
        },
        'ofertas': {
          0: [p('ofertas', 'Leche', 0.5)],
        },
      });
      expect(c.ranked.map((b) => b.store), ['completo']);
      expect(c.partial.map((b) => b.store), ['ofertas']);
      expect(c.common, isEmpty);
    });

    test('sin nada encontrado, vacío', () {
      expect(
        compareBaskets(
          [(name: 'Leche', quantity: null, unit: null)],
          {'x': {}},
        ).isEmpty,
        isTrue,
      );
    });
  });

  group('computeTwoStoreSplit', () {
    test('elige la pareja óptima y calcula ahorro real sobre comunes', () {
      final items = <BasketItem>[
        (name: 'Aceite', quantity: null, unit: null),
        (name: 'Leche', quantity: null, unit: null),
        (name: 'Pollo', quantity: null, unit: null),
      ];
      final c = compareBaskets(items, {
        'mercadona': {
          0: [
            p(
              'mercadona',
              'Aceite 1 L',
              4.00,
              size: '1 l',
              unitPrice: 4.0,
              unit: 'l',
            ),
          ],
          1: [
            p(
              'mercadona',
              'Leche 1 L',
              1.10,
              size: '1 l',
              unitPrice: 1.1,
              unit: 'l',
            ),
          ],
          2: [
            p(
              'mercadona',
              'Pollo 1 kg',
              6.50,
              size: '1 kg',
              unitPrice: 6.5,
              unit: 'kg',
            ),
          ],
        },
        'consum': {
          0: [
            p(
              'consum',
              'Aceite 1 L',
              5.20,
              size: '1 l',
              unitPrice: 5.2,
              unit: 'l',
            ),
          ],
          1: [
            p(
              'consum',
              'Leche 1 L',
              0.80,
              size: '1 l',
              unitPrice: 0.8,
              unit: 'l',
            ),
          ],
          2: [
            p(
              'consum',
              'Pollo 1 kg',
              7.00,
              size: '1 kg',
              unitPrice: 7.0,
              unit: 'kg',
            ),
          ],
        },
        'bonarea': {
          0: [
            p(
              'bonarea',
              'Aceite 1 L',
              4.80,
              size: '1 l',
              unitPrice: 4.8,
              unit: 'l',
            ),
          ],
          1: [
            p(
              'bonarea',
              'Leche 1 L',
              0.90,
              size: '1 l',
              unitPrice: 0.9,
              unit: 'l',
            ),
          ],
          2: [
            p(
              'bonarea',
              'Pollo 1 kg',
              5.20,
              size: '1 kg',
              unitPrice: 5.2,
              unit: 'kg',
            ),
          ],
        },
      });

      // Mejor pareja: mercadona (Aceite 4.00) + bonarea (Leche 0.90 + Pollo 5.20) = 10.10
      // vs comprar los 3 en bonarea (10.90) -> ahorras 0.80 €!
      final split = computeTwoStoreSplit(c)!;
      expect({split.storeA, split.storeB}, {'mercadona', 'bonarea'});
      expect(split.combinedTotal, closeTo(10.10, 1e-6));
      expect(split.savings, closeTo(0.80, 1e-6));
    });

    test('respeta pareja manual aunque no sea la más barata', () {
      final items = <BasketItem>[
        (name: 'Leche', quantity: null, unit: null),
        (name: 'Pan', quantity: null, unit: null),
      ];
      final c = compareBaskets(items, {
        'mercadona': {
          0: [p('mercadona', 'Leche 1 L', 1.00, size: '1 l')],
          1: [p('mercadona', 'Pan', 0.80)],
        },
        'consum': {
          0: [p('consum', 'Leche 1 L', 0.85, size: '1 l')],
          1: [p('consum', 'Pan', 1.10)],
        },
        'bonarea': {
          0: [p('bonarea', 'Leche 1 L', 0.95, size: '1 l')],
          1: [p('bonarea', 'Pan', 0.95)],
        },
      });
      final custom = computeTwoStoreSplit(
        c,
        storeA: 'consum',
        storeB: 'bonarea',
      )!;
      expect(custom.storeA, 'consum');
      expect(custom.storeB, 'bonarea');
      expect(custom.linesA.single.chosen.product.store, 'consum');
      expect(custom.linesB.single.chosen.product.store, 'bonarea');
    });
  });

  test('homeKeyForCatalog quita el país', () {
    expect(homeKeyForCatalog('lidl_fr'), 'lidl');
    expect(homeKeyForCatalog('mercadona'), 'mercadona');
  });

  testWidgets(
    'la hoja enseña 1 súper, Repartir en 2 y llama a onSplitIntoTwoLists',
    (tester) async {
      final c = compareBaskets(
        [
          (name: 'Leche', quantity: null, unit: null),
          (name: 'Pan', quantity: null, unit: null),
        ],
        {
          'consum': {
            0: [
              p(
                'consum',
                'Leche 1 L',
                0.85,
                size: '1 l',
                unitPrice: 0.85,
                unit: 'l',
              ),
            ],
            1: [p('consum', 'Pan', 1.20)],
          },
          'mercadona': {
            0: [
              p(
                'mercadona',
                'Leche 1 L',
                1.05,
                size: '1 l',
                unitPrice: 1.05,
                unit: 'l',
              ),
            ],
            1: [p('mercadona', 'Pan', 0.80)],
          },
        },
      );
      String? picked;
      TwoStoreSplit? splitResult;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoreComparisonSheet(
              load: () async => c,
              itemNames: const ['Leche', 'Pan'],
              currentStore: 'mercadona',
              onPickStore: (k) => picked = k,
              onSplitIntoTwoLists: (s) async => splitResult = s,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mercadona'), findsOneWidget);
      expect(find.text('Lo más barato'), findsOneWidget);
      expect(find.text('Misma cantidad'), findsOneWidget);
      expect(find.text('En caja'), findsOneWidget);

      await tester.tap(find.text('Consum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprar aquí'));
      expect(picked, 'consum');

      // Cambiar a la pestaña "Repartir en 2".
      await tester.tap(find.text('Repartir en 2'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ahorras ≈ 0,20'), findsOneWidget);
      await tester.tap(find.text('Separar en 2 listas'));
      await tester.pumpAndSettle();
      expect(splitResult, isNotNull);
      expect(splitResult!.linesA.length + splitResult!.linesB.length, 2);
    },
  );
}
