import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/shopping_list_item.dart';
import 'package:prezhome/services/local_store.dart';
import 'package:prezhome/services/offline_provider.dart';
import 'package:prezhome/services/offline_repository.dart';
import 'package:prezhome/services/shopping_checkout.dart';
import 'package:prezhome/utils/offline_actions.dart';

class _FakeSender implements RemoteSender {
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};

  @override
  Future<void> sendInsert(String table, Map<String, dynamic> payload) async {
    final id = payload['id'] as String;
    tables.putIfAbsent(table, () => {})[id] = Map<String, dynamic>.from(
      payload,
    );
  }

  @override
  Future<void> sendUpdate(
    String table,
    Map<String, dynamic> payload,
    String id,
  ) async {
    final row = tables[table]?[id];
    if (row != null) row.addAll(payload);
  }

  @override
  Future<void> sendDelete(String table, String id) async {
    tables[table]?.remove(id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table) async {
    return [
      for (final row
          in (tables[table]?.values ?? const <Map<String, dynamic>>[]))
        Map<String, dynamic>.from(row),
    ];
  }
}

void main() {
  test('isShoppingTask reconoce la tarea de hacer la compra', () {
    expect(isShoppingTask('Hacer la compra'), isTrue);
    expect(isShoppingTask('Compra semanal'), isTrue);
    expect(isShoppingTask('Ir de compras'), isTrue);
    expect(isShoppingTask('Comprobar la caldera'), isFalse);
    expect(isShoppingTask('Fregar los platos'), isFalse);
  });

  group('Carrito, En casa y reconciliación de ticket', () {
    late InMemoryLocalStore store;
    late _FakeSender sender;
    late OfflineRepository shoppingRepo;
    late OfflineRepository inventoryRepo;
    late RecentCheckoutStore recentStore;
    late ShoppingCheckout checkout;

    setUp(() {
      store = InMemoryLocalStore();
      sender = _FakeSender();
      shoppingRepo = OfflineRepository(
        table: kShoppingTable,
        store: store,
        sender: sender,
        homeId: 'h',
        gate: DrainGate(minRetryGapMs: 0, nowMillis: () => 0),
      );
      inventoryRepo = OfflineRepository(
        table: kInventoryTable,
        store: store,
        sender: sender,
        homeId: 'h',
        gate: DrainGate(minRetryGapMs: 0, nowMillis: () => 0),
      );
      recentStore = RecentCheckoutStore(store: store);
      checkout = ShoppingCheckout(
        shopping: shoppingRepo,
        inventory: inventoryRepo,
        recentCheckouts: recentStore,
      );
    });

    Future<void> seedShopping(ShoppingListItem item, {int seq = 0}) async {
      await shoppingRepo.applyLocalWrite(
        buildInsertOp(
          table: kShoppingTable,
          id: item.id!,
          payload: item.toCacheMap(),
          nowMillis: 1000 + seq,
          seq: seq,
        ),
      );
    }

    test(
      'setInCart solo marca checked en el carrito sin tocar En casa',
      () async {
        final item = ShoppingListItem(
          id: 'shop-1',
          homeId: 'h',
          name: 'Garbanzos',
          quantity: 200,
          unit: 'g',
          packSize: 570,
        );
        await seedShopping(item);

        await checkout.setInCart(item, true);

        final shoppingRows = await shoppingRepo.readCached();
        final inventoryRows = await inventoryRepo.readCached();
        expect(shoppingRows, hasLength(1));
        expect(shoppingRows.single['checked'], isTrue);
        expect(inventoryRows, isEmpty);
        expect(await recentStore.load(), isEmpty);
      },
    );

    test(
      'checkoutToPantry guarda envase entero en gramos y registra el checkout',
      () async {
        final garbanzos = ShoppingListItem(
          id: 'shop-1',
          homeId: 'h',
          name: 'Garbanzos',
          quantity: 200,
          unit: 'g',
          packSize: 570,
          checked: true,
        );

        final saved = await checkout.checkoutToPantry([garbanzos], homeId: 'h');

        expect(saved, 1);
        final inventoryRows = await inventoryRepo.readCached();
        expect(inventoryRows, hasLength(1));
        expect(inventoryRows.single['name'], 'Garbanzos');
        expect((inventoryRows.single['quantity'] as num).toDouble(), 570.0);
        expect(inventoryRows.single['unit'], 'g');

        final recent = await recentStore.load();
        expect(recent, hasLength(1));
        expect(recent.single.names, ['Garbanzos']);
      },
    );

    test(
      'clearCoveredByTicket borra pendientes y en carrito cubiertos sin tocar otros',
      () async {
        await seedShopping(
          ShoppingListItem(
            id: 's1',
            homeId: 'h',
            name: 'Garbanzos',
            checked: false,
          ),
          seq: 1,
        );
        await seedShopping(
          ShoppingListItem(
            id: 's2',
            homeId: 'h',
            name: 'Leche entera',
            checked: true,
          ),
          seq: 2,
        );
        await seedShopping(
          ShoppingListItem(
            id: 's3',
            homeId: 'h',
            name: 'Detergente',
            checked: false,
          ),
          seq: 3,
        );

        final cleared = await checkout.clearCoveredByTicket(const [
          'Garbanzos cocidos',
          'Leche entera',
        ]);

        expect(cleared, 2);
        final remaining = await shoppingRepo.readCached();
        expect(remaining.map((r) => r['name']).toList(), ['Detergente']);
      },
    );

    test(
      'clearCoveredByTicket no borra productos más específicos ni de otra lista',
      () async {
        await seedShopping(
          ShoppingListItem(id: 'a1', homeId: 'h', name: 'Leche', listId: 'l1'),
          seq: 1,
        );
        await seedShopping(
          ShoppingListItem(
            id: 'a2',
            homeId: 'h',
            name: 'Chocolate con leche',
            listId: 'l1',
          ),
          seq: 2,
        );
        await seedShopping(
          ShoppingListItem(
            id: 'a3',
            homeId: 'h',
            name: 'Salsa de tomate',
            listId: 'l1',
          ),
          seq: 3,
        );
        await seedShopping(
          ShoppingListItem(
            id: 'a4',
            homeId: 'h',
            name: 'Tomates',
            listId: 'l1',
          ),
          seq: 4,
        );
        await seedShopping(
          ShoppingListItem(id: 'b1', homeId: 'h', name: 'Leche', listId: 'l2'),
          seq: 5,
        );

        final cleared = await checkout.clearCoveredByTicket(const [
          'Leche',
          'Tomate',
        ], listId: 'l1');

        expect(cleared, 2);
        final remaining = await shoppingRepo.readCached();
        expect(remaining.map((r) => r['id']).toList(), ['a2', 'a3', 'b1']);
      },
    );

    test(
      'undoCheckout revierte tanto altas nuevas como sumas en En casa y limpia el histórico',
      () async {
        await checkout.checkoutToPantry([
          ShoppingListItem(
            id: 'init',
            homeId: 'h',
            name: 'Garbanzos',
            quantity: 570,
            unit: 'g',
            packSize: 570,
          ),
        ], homeId: 'h');

        final receipt = await checkout.checkoutToPantryWithReceipt([
          ShoppingListItem(
            id: 'g2',
            homeId: 'h',
            name: 'Garbanzos',
            quantity: 570,
            unit: 'g',
            packSize: 570,
          ),
          ShoppingListItem(
            id: 'm1',
            homeId: 'h',
            name: 'Macarrones',
            quantity: 500,
            unit: 'g',
            packSize: 500,
          ),
        ], homeId: 'h');

        expect(receipt.count, 2);
        var inv = await inventoryRepo.readCached();
        expect(inv, hasLength(2));
        expect(
          (inv.firstWhere((r) => r['name'] == 'Garbanzos')['quantity'] as num)
              .toDouble(),
          1140.0,
        );
        expect(await recentStore.load(), hasLength(2));

        await checkout.undoCheckout(receipt);

        inv = await inventoryRepo.readCached();
        expect(inv, hasLength(1));
        expect(inv.single['name'], 'Garbanzos');
        expect((inv.single['quantity'] as num).toDouble(), 570.0);
        expect(await recentStore.load(), hasLength(1));
      },
    );
  });
}
