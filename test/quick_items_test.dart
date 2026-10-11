import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/quick_items.dart';

void main() {
  group('normalizeQuickName', () {
    test('minúsculas y recorte', () {
      expect(normalizeQuickName('  Sal  '), 'sal');
    });
    test('quita acentos', () {
      expect(normalizeQuickName('Azúcar'), 'azucar');
      expect(normalizeQuickName('Pimentón'), 'pimenton');
      expect(normalizeQuickName('Cúrcuma'), 'curcuma');
    });
    test('es estable (idempotente)', () {
      final once = normalizeQuickName('Papel higiénico');
      expect(normalizeQuickName(once), once);
    });
  });

  group('kQuickCondiments', () {
    test('no está vacío', () {
      expect(kQuickCondiments, isNotEmpty);
    });
    test('sin duplicados (por nombre normalizado)', () {
      final seen = <String>{};
      for (final item in kQuickCondiments) {
        final key = normalizeQuickName(item.name);
        expect(seen.add(key), isTrue, reason: 'Duplicado: ${item.name}');
      }
    });
    test('todos tienen nombre y unidad no vacíos', () {
      for (final item in kQuickCondiments) {
        expect(item.name.trim(), isNotEmpty);
        expect(item.unit.trim(), isNotEmpty);
      }
    });
    test('ningún condimento usa cucharadas/cucharaditas', () {
      for (final item in kQuickCondiments) {
        final unit = normalizeQuickName(item.unit);
        expect(unit.contains('cucharad'), isFalse, reason: item.name);
      }
    });
    test('incluye los básicos de siempre', () {
      final names = kQuickCondiments.map((e) => normalizeQuickName(e.name));
      for (final expected in ['sal', 'azucar', 'pimienta negra', 'comino']) {
        expect(names, contains(expected));
      }
    });
  });

  group('kQuickBasics', () {
    test('no está vacío', () {
      expect(kQuickBasics, isNotEmpty);
    });
    test('sin duplicados (por nombre normalizado)', () {
      final seen = <String>{};
      for (final item in kQuickBasics) {
        final key = normalizeQuickName(item.name);
        expect(seen.add(key), isTrue, reason: 'Duplicado: ${item.name}');
      }
    });
    test('todos tienen nombre y unidad no vacíos', () {
      for (final item in kQuickBasics) {
        expect(item.name.trim(), isNotEmpty);
        expect(item.unit.trim(), isNotEmpty);
      }
    });
  });

  test('sin solapamiento entre condimentos y básicos', () {
    final condiments = kQuickCondiments
        .map((e) => normalizeQuickName(e.name))
        .toSet();
    final basics = kQuickBasics.map((e) => normalizeQuickName(e.name)).toSet();
    expect(condiments.intersection(basics), isEmpty);
  });
}
