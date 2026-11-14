import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/inventory_prefill.dart';
import 'package:prezhome/services/product_search_service.dart';

void main() {
  test('fila del catálogo con precio Lidl Plus y fecha', () {
    final p = catalogProductFromRow('lidl', {
      'product_id': '11333174',
      'name': 'Chips extra crujientes Snack Day 180 g',
      'brand': 'Snack Day',
      'size': '180 g',
      'price': 1.49,
      'image_url': 'https://www.lidl.es/assets/a.png',
      'member_price': 1.19,
      'price_starts_at': '2026-11-19T23:00:00+00:00',
    });
    expect(p.code, 'lidl:11333174');
    expect(p.store, 'lidl');
    expect(p.price, 1.49);
    expect(p.memberPrice, 1.19);
    expect(p.priceStartsAt, DateTime.utc(2026, 11, 19, 23));
  });

  test('sin columnas nuevas (otros súpers) no falla', () {
    final p = catalogProductFromRow('mercadona', {
      'product_id': '4241',
      'name': 'Aceite de oliva',
      'price': 16.75,
    });
    expect(p.memberPrice, isNull);
    expect(p.priceStartsAt, isNull);
  });

  test('la fecha solo cuenta si aún no ha llegado', () {
    final p = SupermarketProduct(
      code: 'lidl:1',
      name: 'Turrón',
      price: 1.99,
      priceStartsAt: DateTime.utc(2026, 11, 22),
    );
    expect(p.upcomingPriceFrom(DateTime.utc(2026, 11, 14)), isNotNull);
    expect(p.upcomingPriceFrom(DateTime.utc(2026, 11, 23)), isNull);
  });

  test('escanear un producto del catálogo precarga nombre y formato', () {
    final pre = inventoryPrefillFromCatalog(
      const SupermarketProduct(
        code: 'lidl:1',
        name: 'Café natural Marcilla 500 g',
        quantity: '500 g',
      ),
    );
    expect(pre.name, 'Café natural Marcilla');
    expect(pre.quantity, 500);
    expect(pre.unit, 'g');

    final litro = inventoryPrefillFromCatalog(
      const SupermarketProduct(code: 'lidl:2', name: 'Leche', quantity: '1 L'),
    );
    expect((litro.quantity, litro.unit), (1000, 'ml'));

    final suelto = inventoryPrefillFromCatalog(
      const SupermarketProduct(code: 'lidl:3', name: 'Boniato A granel'),
    );
    expect((suelto.quantity, suelto.unit), (null, 'unidades'));
  });
}
