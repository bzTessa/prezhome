import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/supermarket.dart';
import 'package:prezhome/widgets/supermarket_badge.dart';

void main() {
  test('iniciales de la insignia del súper', () {
    expect(SupermarketBadge.initials('Mercadona'), 'M');
    expect(SupermarketBadge.initials('El Corte Inglés / Hipercor'), 'EC');
    expect(SupermarketBadge.initials('Dia'), 'D');
  });

  test('buscador de súper: etiqueta, clave sin tildes y Bonarea', () {
    Supermarket find(String k) => Supermarket.all.firstWhere((s) => s.key == k);
    expect(find('bonarea').matches('bonarea'), isTrue);
    expect(find('bonarea').matches('BonÀrea'), isTrue);
    expect(find('ahorramas').matches('ahorramas'), isTrue);
    expect(find('elcorteingles').matches('corte ingles'), isTrue);
    expect(find('elcorteingles').matches('hipercor'), isTrue);
    expect(find('lidl').matches('merca'), isFalse);
    expect(
      Supermarket.all.map((s) => s.key).toSet().length,
      Supermarket.all.length,
    );
  });

  test('cada logo de súper existe en assets', () {
    for (final s in Supermarket.all) {
      expect(File(s.logo!).existsSync(), isTrue, reason: s.key);
    }
  });
}
