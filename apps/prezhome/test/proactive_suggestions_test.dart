import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/proactive_suggestions_service.dart';

void main() {
  group('buildExpiringSuggestions', () {
    test('incluye solo comida que caduca hoy/mañana/pasado (0,1,2)', () {
      final r = buildExpiringSuggestions(const [
        ProactiveStockItem(name: 'Yogur', daysUntilExpiry: 0),
        ProactiveStockItem(name: 'Pollo', daysUntilExpiry: 1),
        ProactiveStockItem(name: 'Espinacas', daysUntilExpiry: 2),
      ]);
      expect(r.map((s) => s.name), ['Yogur', 'Pollo', 'Espinacas']);
    });

    test('excluye frescos (3 y 5 días)', () {
      final r = buildExpiringSuggestions(const [
        ProactiveStockItem(name: 'Arroz', daysUntilExpiry: 3),
        ProactiveStockItem(name: 'Pasta', daysUntilExpiry: 5),
      ]);
      expect(r, isEmpty);
    });

    test('excluye caducados (-1) y sin fecha (null)', () {
      final r = buildExpiringSuggestions(const [
        ProactiveStockItem(name: 'Leche', daysUntilExpiry: -1),
        ProactiveStockItem(name: 'Sal', daysUntilExpiry: null),
      ]);
      expect(r, isEmpty);
    });

    test('excluye lo que no es comida aunque caduque pronto', () {
      final r = buildExpiringSuggestions(const [
        ProactiveStockItem(name: 'Lejía', daysUntilExpiry: 1, isFood: false),
      ]);
      expect(r, isEmpty);
    });

    test('ordena por días ascendente (lo más urgente primero)', () {
      final r = buildExpiringSuggestions(const [
        ProactiveStockItem(name: 'Pasado', daysUntilExpiry: 2),
        ProactiveStockItem(name: 'Hoy', daysUntilExpiry: 0),
        ProactiveStockItem(name: 'Mañana', daysUntilExpiry: 1),
      ]);
      expect(r.map((s) => s.name), ['Hoy', 'Mañana', 'Pasado']);
      expect(r.map((s) => s.daysUntilExpiry), [0, 1, 2]);
    });

    test('respeta un umbral personalizado', () {
      final r = buildExpiringSuggestions(const [
        ProactiveStockItem(name: 'A', daysUntilExpiry: 3),
        ProactiveStockItem(name: 'B', daysUntilExpiry: 4),
      ], thresholdDays: 3);
      expect(r.map((s) => s.name), ['A']);
    });

    test('message usa español cercano sin la palabra IA', () {
      final hoy = const ExpiringSuggestion(name: 'Yogur', daysUntilExpiry: 0);
      final manana = const ExpiringSuggestion(
        name: 'Pollo',
        daysUntilExpiry: 1,
      );
      final pasado = const ExpiringSuggestion(name: 'Pan', daysUntilExpiry: 2);
      expect(hoy.message.contains('caduca hoy'), isTrue);
      expect(manana.message.contains('caduca mañana'), isTrue);
      expect(pasado.message.contains('2 días'), isTrue);
      for (final m in [hoy.message, manana.message, pasado.message]) {
        expect(m.toLowerCase().contains('ia '), isFalse);
      }
    });
  });

  group('isDepletedStaple', () {
    test('true solo si es básico y la cantidad es <= 0', () {
      expect(isDepletedStaple(true, 0), isTrue);
      expect(isDepletedStaple(true, -1), isTrue);
      expect(isDepletedStaple(true, 1), isFalse);
      expect(isDepletedStaple(false, 0), isFalse);
      expect(isDepletedStaple(false, 5), isFalse);
    });
  });

  group('buildRestockItem', () {
    test('crea un ShoppingListItem con source auto y campos correctos', () {
      final item = buildRestockItem(
        homeId: 'home-1',
        name: 'Leche',
        itemType: 'comida',
        category: 'Nevera',
        unit: 'l',
        imageUrl: 'https://example.com/leche.jpg',
        existingShoppingNames: const [],
      );
      expect(item, isNotNull);
      expect(item!.source, 'auto');
      expect(item.homeId, 'home-1');
      expect(item.name, 'Leche');
      expect(item.quantity, 1);
      expect(item.unit, 'l');
      expect(item.category, 'Nevera');
      expect(item.itemType, 'comida');
      expect(item.imageUrl, 'https://example.com/leche.jpg');
      expect(item.id, isNull);
    });

    test('respeta una cantidad explícita', () {
      final item = buildRestockItem(
        homeId: 'home-1',
        name: 'Huevos',
        itemType: 'comida',
        quantity: 12,
        existingShoppingNames: const [],
      );
      expect(item!.quantity, 12);
    });

    test(
      'dedup: devuelve null si el nombre ya está (comparando normalizado)',
      () {
        final item = buildRestockItem(
          homeId: 'home-1',
          name: 'Leche',
          itemType: 'comida',
          existingShoppingNames: const ['leche'],
        );
        expect(item, isNull);
      },
    );

    test('dedup ignora espacios y mayúsculas', () {
      final item = buildRestockItem(
        homeId: 'home-1',
        name: '  Pan  ',
        itemType: 'comida',
        existingShoppingNames: const ['PAN'],
      );
      expect(item, isNull);
    });

    test('no deduplica nombres distintos', () {
      final item = buildRestockItem(
        homeId: 'home-1',
        name: 'Mantequilla',
        itemType: 'comida',
        existingShoppingNames: const ['Leche', 'Pan'],
      );
      expect(item, isNotNull);
      expect(item!.name, 'Mantequilla');
    });
  });

  group('normalizeName', () {
    test('baja a minúsculas y recorta espacios', () {
      expect(normalizeName('  Leche '), 'leche');
      expect(normalizeName('PAN'), 'pan');
    });
  });
}
