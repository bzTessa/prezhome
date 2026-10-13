import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/product_icons.dart';

void main() {
  test('cada producto lleva su propio icono', () {
    expect(ProductIcons.assetFor('Cebolla'), 'assets/icons/products/onion.png');
    expect(
      ProductIcons.assetFor('patatas'),
      'assets/icons/products/potato.png',
    );
    expect(
      ProductIcons.assetFor('Pechugas de pollo'),
      endsWith('poultry_leg.png'),
    );
    expect(
      ProductIcons.assetFor('Zumo de naranja'),
      endsWith('beverage_box.png'),
    );
    expect(
      ProductIcons.assetFor('Pasta de dientes'),
      endsWith('toothbrush.png'),
    );
    expect(ProductIcons.assetFor('nueces'), endsWith('peanuts.png'));
    expect(ProductIcons.assetFor('Salmón'), endsWith('fish.png'));
    // Palabras cortas no casan por prefijo: salmón no es sal, panceta no es pan.
    expect(ProductIcons.assetFor('Panceta'), endsWith('bacon.png'));
    expect(ProductIcons.assetFor('Quinoa'), isNull);
  });

  test('genérico solo si no hay marca ni nada más', () {
    expect(ProductIcons.isGeneric('cebolla'), isTrue);
    expect(ProductIcons.isGeneric('2 cebollas moradas'), isTrue);
    expect(ProductIcons.isGeneric('Leche entera'), isTrue);
    expect(ProductIcons.isGeneric('Tomate pera'), isTrue);
    expect(ProductIcons.isGeneric('Cebolla Hacendado'), isFalse);
    expect(ProductIcons.isGeneric('Leche Pascual semidesnatada'), isFalse);
    expect(ProductIcons.isGeneric('Quinoa'), isFalse);
  });

  test('todos los iconos existen', () {
    final src = File('lib/widgets/product_icons.dart').readAsStringSync();
    final names = RegExp(r"': '([a-z_]+)',").allMatches(src).map((m) => m[1]);
    expect(names, isNotEmpty);
    for (final n in names) {
      expect(
        File('assets/icons/products/$n.png').existsSync(),
        isTrue,
        reason: n,
      );
    }
  });
}
