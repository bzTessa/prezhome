import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/product_icons.dart';

void main() {
  test('cada producto lleva su propio icono', () {
    expect(ProductIcons.iconNameFor('Cebolla'), 'onion');
    expect(ProductIcons.iconNameFor('patatas'), 'potato');
    expect(ProductIcons.iconNameFor('Pechugas de pollo'), 'poultry_leg');
    expect(ProductIcons.iconNameFor('Zumo de naranja'), 'beverage_box');
    expect(ProductIcons.iconNameFor('Pasta de dientes'), 'toothbrush');
    expect(ProductIcons.iconNameFor('nueces'), 'peanuts');
    expect(ProductIcons.iconNameFor('Salmón'), 'salmon_fillet');
    // Palabras cortas no casan por prefijo: salmón no es sal, panceta no es pan.
    expect(ProductIcons.iconNameFor('Panceta'), 'bacon');
    expect(ProductIcons.iconNameFor('Quinoa'), isNull);
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

  test('cada icono del mapa tiene su dibujo', () {
    final src = File('lib/widgets/product_icons.dart').readAsStringSync();
    final icons = RegExp(
      r"^\s+'[a-z ]+': '([a-z_]+)',",
      multiLine: true,
    ).allMatches(src).map((m) => m[1]!).toSet();
    for (final icon in icons) {
      expect(
        File('assets/icons/products/$icon.png').existsSync(),
        isTrue,
        reason: icon,
      );
    }
  });

  test('los dibujos nuevos casan con su producto', () {
    expect(ProductIcons.assetFor('Cebolla'), 'assets/icons/products/onion.png');
    expect(ProductIcons.iconNameFor('Tortilla de patata'), 'tortilla_patata');
    expect(ProductIcons.iconNameFor('Queso rallado'), 'grated_cheese');
    expect(ProductIcons.iconNameFor('Yogur de avena'), 'yogurt_cup');
    expect(ProductIcons.iconNameFor('Pastilla de caldo'), 'stock_cube');
    expect(ProductIcons.iconNameFor('Salsa de soja'), 'soy_sauce');
    expect(ProductIcons.iconNameFor('Pañales'), 'diapers');
    expect(ProductIcons.iconNameFor('Coca-Cola'), 'soda_can');
  });

  test('clave de la foto genérica', () {
    expect(ProductIcons.keyFor('2 Cebollas moradas'), 'cebolla');
    expect(ProductIcons.keyFor('Judías verdes'), 'judia verde');
    expect(ProductIcons.photoKeyFor('Patatas'), 'patata');
    expect(ProductIcons.photoKeyFor('Quinoa'), 'quinoa');
    expect(ProductIcons.photoKeyFor('500 g'), isNull);
  });

  test('la función product-image conoce todas las palabras clave', () {
    final src = File('lib/widgets/product_icons.dart').readAsStringSync();
    final keys = RegExp(
      r"^\s+'([a-z ]+)': '[a-z_]+',",
      multiLine: true,
    ).allMatches(src).map((m) => m[1]).toList();
    final json = File(
      '../../supabase/functions/product-image/keywords.json',
    ).readAsStringSync();
    expect((jsonDecode(json) as List).cast<String>(), keys);
  });
}
