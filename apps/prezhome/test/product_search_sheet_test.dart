import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
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

  testWidgets('en pickPhotoMode filtra sin foto o urls rotas y ofrece Cerrar', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'products': [
            {'code': '1', 'product_name_es': 'Zanahoria sin foto'},
            {
              'code': '2',
              'product_name_es': 'Zanahoria Consum rota',
              'image_front_small_url':
                  'https://cdn-consum.example.com/zanahoria.jpg',
            },
            {
              'code': '3',
              'product_name_es': 'Zanahoria fresca buena',
              'image_front_small_url':
                  'https://images.openfoodfacts.org/images/products/123/front.jpg',
            },
          ],
        }),
        200,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: ProductSearchSheet(
            initialQuery: 'zanahoria',
            service: ProductSearchService(client: client),
            pickPhotoMode: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zanahoria sin foto'), findsNothing);
    expect(find.text('Zanahoria Consum rota'), findsNothing);
    expect(find.text('Zanahoria fresca buena'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Añadir "zanahoria" sin elegir producto'), findsNothing);
  });
}
