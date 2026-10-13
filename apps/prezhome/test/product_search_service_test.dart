import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prezhome/services/product_search_service.dart';

Map<String, dynamic> _off(List<Map<String, dynamic>> products) => {
  'count': products.length,
  'products': products,
};

void main() {
  setUp(ProductSearchService.resetForTest);

  group('buildProductSearchUri', () {
    test('filtra por España y, si se pide, por tienda', () {
      final uri = buildProductSearchUri('leche', storeTag: 'mercadona');
      expect(uri.host, 'es.openfoodfacts.org');
      expect(uri.queryParameters['search_terms'], 'leche');
      expect(uri.queryParameters['tag_0'], 'spain');
      expect(uri.queryParameters['tagtype_1'], 'stores');
      expect(uri.queryParameters['tag_1'], 'mercadona');
      expect(uri.queryParameters['json'], '1');
    });

    test('sin tienda no añade el segundo filtro', () {
      final uri = buildProductSearchUri('leche');
      expect(uri.queryParameters.containsKey('tag_1'), isFalse);
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
        final store = req.url.queryParameters['tag_1'];
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(
              _off(
                store == null
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

    test('un error de red no lanza', () async {
      final client = MockClient((_) async => throw Exception('sin red'));
      final r = await ProductSearchService(client: client).search('arroz');
      expect(r.failed, isTrue);
      expect(r.products, isEmpty);
    });
  });
}
