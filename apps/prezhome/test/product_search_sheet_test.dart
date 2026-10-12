import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prezhome/services/product_search_service.dart';
import 'package:prezhome/widgets/product_search_sheet.dart';

void main() {
  setUp(ProductSearchService.resetForTest);

  testWidgets('busca al abrir y devuelve el producto elegido', (tester) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'products': [
            {
              'code': '1',
              'product_name_es': 'Yogur griego natural',
              'brands': 'Hacendado',
              'quantity': '6 x 125 g',
            },
          ],
        }),
        200,
      ),
    );
    SupermarketProduct? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showProductSearchSheet(
                  context,
                  initialQuery: 'yogur griego',
                  supermarketKey: 'mercadona',
                  service: ProductSearchService(client: client),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Productos de Mercadona'), findsOneWidget);
    expect(find.text('Yogur griego natural'), findsOneWidget);
    expect(find.text('Hacendado · 6 x 125 g'), findsOneWidget);

    await tester.tap(find.text('Yogur griego natural'));
    await tester.pumpAndSettle();
    expect(picked?.displayName, 'Yogur griego natural · Hacendado');
  });
}
