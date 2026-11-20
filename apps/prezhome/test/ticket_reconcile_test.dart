import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/shopping_list_item.dart';
import 'package:prezhome/utils/ticket_reconcile.dart';

void main() {
  final now = DateTime(2026, 11, 20, 18, 0);

  test('pruneRecentCheckouts conserva los recientes y descarta antiguos', () {
    final recent = RecentCheckoutRecord(
      at: now.subtract(const Duration(hours: 6)),
      names: const ['Garbanzos', 'Leche entera'],
    );
    final expired = RecentCheckoutRecord(
      at: now.subtract(const Duration(hours: 25)),
      names: const ['Pan'],
    );

    final kept = pruneRecentCheckouts([expired, recent], now);
    expect(kept, [recent]);
  });

  group('reconcileTicket', () {
    test('detecta compra ya guardada en casa dentro de la ventana de 12 h', () {
      final checkouts = [
        RecentCheckoutRecord(
          at: now.subtract(const Duration(hours: 2)),
          names: const ['Garbanzos', 'Leche entera'],
        ),
      ];

      final res = reconcileTicket(
        ticketNames: const [
          'Garbanzos cocidos',
          'Leche entera',
          'Pan de molde',
        ],
        listItems: const [],
        recentCheckouts: checkouts,
        now: now,
      );

      expect(res.alreadyInPantryIndices, {0, 1});
      expect(res.likelyAlreadySavedToPantry, isTrue);
    });

    test('no marca como duplicado un checkout hecho hace más de 12 h', () {
      final checkouts = [
        RecentCheckoutRecord(
          at: now.subtract(const Duration(hours: 20)),
          names: const ['Garbanzos', 'Leche entera'],
        ),
      ];

      final res = reconcileTicket(
        ticketNames: const [
          'Garbanzos cocidos',
          'Leche entera',
          'Pan de molde',
        ],
        listItems: const [],
        recentCheckouts: checkouts,
        now: now,
      );

      expect(res.alreadyInPantryIndices, isEmpty);
      expect(res.likelyAlreadySavedToPantry, isFalse);
    });

    test(
      'hereda el envase del producto y prioriza los marcados en el carrito',
      () {
        final unchecked = ShoppingListItem(
          id: '1',
          homeId: 'h',
          name: 'Garbanzos',
          quantity: 400,
          unit: 'g',
          packSize: 400,
          checked: false,
        );
        final inCart = ShoppingListItem(
          id: '2',
          homeId: 'h',
          name: 'Garbanzos',
          quantity: 570,
          unit: 'g',
          packSize: 570,
          checked: true,
        );

        final res = reconcileTicket(
          ticketNames: const ['Garbanzos cocidos'],
          listItems: [unchecked, inCart],
          recentCheckouts: const [],
          now: now,
        );

        expect(res.matchedListItems[0]?.packSize, 570);
        expect(res.matchedListItems[0]?.unit, 'g');
      },
    );
  });
}
