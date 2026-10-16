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
    expect(ProductIcons.iconNameFor('Salmón'), 'fish');
    // Palabras cortas no casan por prefijo: salmón no es sal, panceta no es pan.
    expect(ProductIcons.iconNameFor('Panceta'), 'bacon');
    expect(ProductIcons.iconNameFor('Quinoa'), isNull);
    // Sin el dibujo de Tessa en assets, no hay icono propio.
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

  test('los iconos propios apuntados existen', () {
    final src = File('lib/widgets/product_icons.dart').readAsStringSync();
    final own = RegExp(r'_own = \{([^}]*)\}').firstMatch(src)![1]!;
    for (final m in RegExp(r"'([a-z_]+)'").allMatches(own)) {
      expect(
        File('assets/icons/products/${m[1]}.png').existsSync(),
        isTrue,
        reason: m[1],
      );
    }
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
