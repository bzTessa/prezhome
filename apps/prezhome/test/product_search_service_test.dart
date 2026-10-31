import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prezhome/services/product_search_service.dart';

Map<String, dynamic> _off(List<Map<String, dynamic>> products) => {
  'count': products.length,
  'hits': products,
};

void main() {
  setUp(ProductSearchService.resetForTest);

  group('buildProductSearchUri', () {
    test('filtra por España y, si se pide, por tienda', () {
      final uri = buildProductSearchUri('leche', storeTag: 'mercadona');
      expect(uri.host, 'search.openfoodfacts.org');
      expect(
        uri.queryParameters['q'],
        'leche countries_tags:"en:spain" stores:"mercadona"',
      );
      expect(uri.queryParameters['langs'], 'es');
    });

    test('sin tienda no filtra por tienda y limpia la sintaxis', () {
      final uri = buildProductSearchUri('jamón: "serrano"');
      expect(
        uri.queryParameters['q'],
        'jamón serrano countries_tags:"en:spain"',
      );
    });
  });

  test('offStoreTag traduce las claves del hogar', () {
    expect(offStoreTag('elcorteingles'), 'el-corte-ingles');
    expect(offStoreTag('mercadona'), 'mercadona');
    expect(offStoreTag('otro'), isNull);
    expect(offStoreTag(null), isNull);
  });

  test(
    'parseProductSearch prefiere el nombre en español, limpia y deduplica',
    () {
      final products = parseProductSearch(
        _off([
          {
            'code': '1',
            'product_name_es': 'Leche semidesnatada',
            'product_name': 'Semi-skimmed milk',
            'brands': 'Hacendado, Mercadona',
            'quantity': '1 l',
            'image_front_small_url': 'https://img/1.jpg',
          },
          {'code': '2', 'product_name': '', 'brands': 'X'},
          {
            'code': '3',
            'product_name_es': 'Leche semidesnatada',
            'brands': 'Hacendado',
          },
          {'code': '4', 'product_name': 'Yogur griego'},
        ]),
      );
      expect(products.map((p) => p.code), ['1', '4']);
      expect(products.first.brand, 'Hacendado');
      expect(products.first.displayName, 'Leche semidesnatada · Hacendado');
      expect(products.first.imageUrl, 'https://img/1.jpg');
      expect(products.last.displayName, 'Yogur griego');
    },
  );

  test('parseProductSearch acepta marcas en lista (search-a-licious)', () {
    final products = parseProductSearch(
      _off([
        {
          'code': '1',
          'product_name': 'Jamón serrano',
          'brands': ['Hacendado', 'Mercadona'],
        },
      ]),
    );
    expect(products.single.brand, 'Hacendado');
  });

  test('parsePackageQuantity entiende los formatos habituales', () {
    expect(parsePackageQuantity('1 l'), (quantity: 1.0, unit: 'litros'));
    expect(parsePackageQuantity('500 g'), (quantity: 500.0, unit: 'g'));
    expect(parsePackageQuantity('1,5 kg'), (quantity: 1.5, unit: 'kg'));
    expect(parsePackageQuantity('33 cl'), (quantity: 330.0, unit: 'ml'));
    expect(parsePackageQuantity('pack de 6'), isNull);
    expect(parsePackageQuantity('6 x 125 g'), isNull);
    expect(parsePackageQuantity(null), isNull);
  });

  group('ProductSearchService.search', () {
    test('si el súper no tiene resultados, busca en todos', () async {
      final calls = <Uri>[];
      final client = MockClient((req) async {
        calls.add(req.url);
        final inStore = req.url.queryParameters['q']!.contains('stores:');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(
              _off(
                !inStore
                    ? [
                        {'code': '9', 'product_name': 'Kéfir'},
                      ]
                    : [],
              ),
            ),
          ),
          200,
        );
      });
      final r = await ProductSearchService(
        client: client,
      ).search('kéfir', supermarketKey: 'lidl');
      expect(calls, hasLength(2));
      expect(r.filteredByStore, isFalse);
      expect(r.products.single.name, 'Kéfir');
    });

    test('cachea y frena las búsquedas seguidas', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(jsonEncode(_off([])), 200);
      });
      final service = ProductSearchService(client: client);
      await service.search('pan');
      await service.search('pan');
      expect(calls, 1);
      for (var i = 0; i < 7; i++) {
        await service.search('producto $i');
      }
      expect(calls, 8);
      final r = await service.search('uno más');
      expect(r.throttled, isTrue);
      expect(calls, 8);
    });

    test('las fotos en segundo plano no agotan las búsquedas', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(jsonEncode(_off([])), 200);
      });
      final service = ProductSearchService(client: client);
      for (var i = 0; i < 10; i++) {
        await service.search('foto $i', background: true);
      }
      expect(calls, 4);
      final r = await service.search('zanahoria');
      expect(r.throttled, isFalse);
      expect(calls, 5);
    });

    test('sin conexión no lanza y lo dice', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('sin red'),
      );
      final r = await ProductSearchService(client: client).search('arroz');
      expect(r.failed, isTrue);
      expect(r.offline, isTrue);
      expect(r.products, isEmpty);
    });

    test('si OFF falla no es falta de conexión', () async {
      final client = MockClient((_) async => http.Response('caído', 503));
      final r = await ProductSearchService(client: client).search('arroz');
      expect(r.failed, isTrue);
      expect(r.offline, isFalse);
    });

    test('Mercadona: usa su catálogo sin llamar a OFF', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(jsonEncode(_off([])), 200);
      });
      final r = await ProductSearchService(
        client: client,
        catalog: (q, store, {freshOnly = false}) async => [
          if (store == 'mercadona')
            const SupermarketProduct(
              code: 'mercadona:1',
              name: 'Leche entera Hacendado',
              quantity: '1 l',
              price: 1.15,
            ),
        ],
      ).search('leche', supermarketKey: 'mercadona');
      expect(calls, 0);
      expect(r.filteredByStore, isTrue);
      expect(r.products.single.price, 1.15);
      expect(r.products.single.store, 'mercadona');
    });

    test('súper sin catálogo: busca en los catálogos oficiales, el suyo '
        'primero, sin llamar a OFF', () async {
      var calls = 0;
      final asked = <String>[];
      final r = await ProductSearchService(
        client: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(_off([])), 200);
        }),
        catalog: (q, store, {freshOnly = false}) async {
          asked.add(store);
          return [
            if (store != 'mercadona')
              SupermarketProduct(code: '$store:1', name: 'Queso azul'),
          ];
        },
      ).search('queso azul', supermarketKey: 'dia');
      expect(calls, 0);
      expect(asked.first, 'dia');
      expect(asked, containsAll(['mercadona', 'consum']));
      expect(r.products.map((p) => p.store), ['dia', 'consum', 'bonarea']);
      expect(r.filteredByStore, isTrue);
    });

    test('Open Food Facts va siempre detrás de los catálogos', () async {
      final r = await ProductSearchService(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode(
                _off([
                  {'code': '9', 'product_name': 'Espinacas frescas'},
                ]),
              ),
            ),
            200,
          ),
        ),
        catalog: (q, store, {freshOnly = false}) async => [
          if (store == 'mercadona')
            const SupermarketProduct(
              code: 'mercadona:1',
              name: 'Crema de espinacas',
            ),
        ],
      ).search('espinacas frescas', supermarketKey: 'bonarea');
      expect(r.products.map((p) => p.code), ['mercadona:1', '9']);
      expect(r.filteredByStore, isFalse);
    });

    test('si el catálogo falla o no lo tiene, sigue con OFF', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(
              _off([
                {'code': '9', 'product_name': 'Kéfir'},
              ]),
            ),
          ),
          200,
        );
      });
      final r = await ProductSearchService(
        client: client,
        catalog: (q, store, {freshOnly = false}) async =>
            throw Exception('sin red'),
      ).search('kéfir', supermarketKey: 'mercadona');
      expect(calls, greaterThan(0));
      expect(r.products.single.name, 'Kéfir');
    });

    test('foto de frescos del súper para lo genérico', () async {
      bool? fresh;
      final service = ProductSearchService(
        client: MockClient((_) async => http.Response('', 500)),
        catalog: (q, store, {freshOnly = false}) async {
          fresh = freshOnly;
          return [
            const SupermarketProduct(
              code: 'mercadona:1',
              name: 'Cebolla tierna',
              imageUrl: 'https://prod-mercadona.imgix.net/a.jpg',
            ),
          ];
        },
      );
      expect(
        await service.freshPhoto('cebolla', 'mercadona'),
        'https://prod-mercadona.imgix.net/a.jpg',
      );
      expect(fresh, isTrue);
      expect(await service.freshPhoto('patata', 'mercadona'), isNull);
    });
  });
}
