import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/utils/kitchen_zones.dart';
import 'package:prezhome/widgets/kitchen/kitchen_zones_grid.dart';

InventoryItem _item(
  String name,
  String category, {
  String type = 'comida',
  int? expiresInDays,
}) {
  final now = DateTime.now();
  return InventoryItem.fromMap({
    'id': name,
    'home_id': 'h',
    'name': name,
    'category': category,
    'item_type': type,
    'quantity': 1,
    'unit': 'ud',
    'expiration_date': expiresInDays == null
        ? null
        : DateTime(
            now.year,
            now.month,
            now.day + expiresInDays,
          ).toIso8601String(),
  });
}

void main() {
  _dupes();
  final items = [
    _item('Leche', 'Nevera', expiresInDays: 1),
    _item('Yogur', 'Nevera', expiresInDays: -2),
    _item('Guisantes', 'Congelador'),
    _item('Arroz', 'Despensa'),
    _item('Pimentón', 'Especias', expiresInDays: -10),
    _item('Lejía', 'Despensa', type: 'hogar'),
    _item('Champú', 'Hogar', type: 'hogar'),
    // Guardado como comida por error: va igual con lo de casa.
    _item('Guantes', 'Limpieza'),
  ];

  test('cada producto cae en una sola zona', () {
    for (final i in items) {
      final zones = KitchenZone.values.where((z) => z.matches(i));
      expect(zones, hasLength(1), reason: i.name);
    }
  });

  test('resumen por zona con caducidades (sin especias ni hogar)', () {
    final byZone = {for (final s in summarizeZones(items)) s.zone: s};
    expect(byZone[KitchenZone.nevera]!.count, 2);
    expect(byZone[KitchenZone.nevera]!.soon, 1);
    expect(byZone[KitchenZone.nevera]!.expired, 1);
    expect(byZone[KitchenZone.especias]!.expired, 0);
    expect(byZone[KitchenZone.limpieza]!.count, 2);
    expect(byZone[KitchenZone.hogar]!.count, 1);
    expect(byZone[KitchenZone.despensa]!.count, 1);
    expect(byZone[KitchenZone.bebidas]!.count, 0);
  });

  testWidgets('la cuadrícula filtra al tocar y oculta zonas vacías', (
    tester,
  ) async {
    KitchenZone? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: KitchenZonesGrid(
              zones: summarizeZones(items),
              selected: null,
              onSelect: (z) => picked = z,
            ),
          ),
        ),
      ),
    );
    expect(find.text('8 productos'), findsOneWidget);
    expect(find.text('Bebidas'), findsNothing);
    // La zona y la tarjeta "Revisar" (lo urgente de todas).
    expect(find.text('1 caducado'), findsNWidgets(2));

    await tester.tap(find.text('Congelador'));
    expect(picked, KitchenZone.congelador);
    expect(tester.takeException(), isNull);
  });
}

void _dupes() {
  test(
    'une los productos repetidos sumando y con la caducidad más próxima',
    () {
      final now = DateTime.now();
      InventoryItem jamon(String id, double q, int days) =>
          InventoryItem.fromMap({
            'id': id,
            'home_id': 'h',
            'name': id == 'a' ? 'Jamón serrano' : 'jamon serrano',
            'category': 'Nevera',
            'item_type': 'comida',
            'quantity': q,
            'unit': 'g',
            'kind': 'ingredient',
            'expiration_date': now.add(Duration(days: days)).toIso8601String(),
          });
      final merges = findPantryDuplicates([
        jamon('a', 100, 5),
        jamon('b', 145, 2),
        _item('Leche', 'Nevera'),
      ]);
      expect(merges, hasLength(1));
      expect(merges.single.keep.id, 'a');
      expect(merges.single.quantity, 245);
      expect(merges.single.removeIds, ['b']);
      expect(
        merges.single.expirationDate!.day,
        now.add(const Duration(days: 2)).day,
      );
    },
  );
}
