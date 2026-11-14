import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/widgets/shopping/store_comparison_sheet.dart';
import 'package:prezhome/services/product_search_service.dart';
import 'package:prezhome/services/store_comparison.dart';

SupermarketProduct p(String store, String name, double price, {String? size}) =>
    SupermarketProduct(
      code: '$store:$name$size',
      name: name,
      quantity: size,
      price: price,
    );

void main() {
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
      expect(line.cost, closeTo(2.8, 1e-9));
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
  });

  group('compareBaskets', () {
    final items = <BasketItem>[
      (name: 'Leche', quantity: null, unit: null),
      (name: 'Pan', quantity: null, unit: null),
      (name: 'Tomate', quantity: null, unit: null),
    ];

    test('ordena por el total de lo que hay en todos', () {
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
      // El tomate solo está en uno: no cuenta para comparar, sí en su total.
      expect(c.ranked.last.total, closeTo(4.2, 1e-9));
    });

    test('los súpers con muy pocos productos van aparte', () {
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
      expect(compareBaskets(items, {'x': {}}).isEmpty, isTrue);
    });
  });

  test('homeKeyForCatalog quita el país', () {
    expect(homeKeyForCatalog('lidl_fr'), 'lidl');
    expect(homeKeyForCatalog('mercadona'), 'mercadona');
  });

  testWidgets('la hoja enseña el ranking y el detalle al tocar', (
    tester,
  ) async {
    final c = compareBaskets(
      [
        (name: 'Leche', quantity: null, unit: null),
        (name: 'Pan', quantity: null, unit: null),
      ],
      {
        'consum': {
          0: [p('consum', 'Leche', 1.2)],
          1: [p('consum', 'Pan', 1.0)],
        },
        'mercadona': {
          0: [p('mercadona', 'Leche', 0.9)],
          1: [p('mercadona', 'Pan', 0.8)],
        },
      },
    );
    String? picked;
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mercadona'), findsOneWidget);
    expect(find.text('Lo más barato'), findsOneWidget);
    expect(find.textContaining('0,50'), findsOneWidget);
    await tester.tap(find.text('Consum'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar aquí'));
    expect(picked, 'consum');
  });
}
