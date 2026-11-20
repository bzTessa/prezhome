import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/utils/kitchen_zones.dart';
import 'package:prezhome/widgets/kitchen/kitchen_zones_grid.dart';

InventoryItem _item(
  String name,
  String category, {
  String type = 'comida',
  int? expiresInDays,
  double quantity = 1,
  String unit = 'ud',
  String kind = 'ingredient',
}) {
  final now = DateTime.now();
  return InventoryItem.fromMap({
    'id': name,
    'home_id': 'h',
    'name': name,
    'category': category,
    'item_type': type,
    'quantity': quantity,
    'unit': unit,
    'kind': kind,
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
    _item('Jabón de manos', 'Despensa', type: 'hogar'),
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
    expect(byZone[KitchenZone.hogar]!.count, 2);
    expect(byZone[KitchenZone.despensa]!.count, 1);
  });

  test('las bebidas van a la despensa y cada cosa a su estante', () {
    final cola = _item('Coca-Cola', 'Bebidas');
    expect(KitchenZone.despensa.matches(cola), isTrue);
    expect(shelfOf(cola), PantryShelf.bebidas);
    expect(
      shelfOf(_item('Pechuga de pollo', 'Nevera')),
      PantryShelf.carnePescado,
    );
    expect(shelfOf(_item('Lechuga', 'Nevera')), PantryShelf.verduraFruta);
    expect(shelfOf(_item('Yogur natural', 'Nevera')), PantryShelf.lacteos);
  });

  testWidgets(
    'la cuadrícula filtra al tocar y enseña también las zonas vacías',
    (tester) async {
      KitchenZone? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
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
      expect(find.text('9 productos'), findsOneWidget);
      // Las zonas vacías también se ven, para poder añadir en ellas.
      expect(find.text('Bebidas'), findsNothing);
      expect(find.text('Revisar'), findsNothing);

      await tester.tap(find.text('Congelador'));
      expect(picked, KitchenZone.congelador);
      expect(tester.takeException(), isNull);
    },
  );

  test('cada zona expone su ilustración zona_*.png', () {
    for (final z in KitchenZone.values) {
      expect(z.assetPath, startsWith('assets/images/zona_'));
      expect(z.assetPath, endsWith('.png'));
    }
  });

  test(
    'isLevelTracked aplica solo a especias, condimentos y hogar en unidades',
    () {
      expect(isLevelTracked(_item('Orégano', 'Especias', unit: 'ud')), isTrue);
      expect(
        isLevelTracked(_item('Lejía', 'Limpieza', type: 'hogar', unit: 'ud')),
        isTrue,
      );
      expect(
        isLevelTracked(_item('Estropajos', 'Hogar', type: 'hogar', unit: 'ud')),
        isTrue,
      );
      expect(
        isLevelTracked(_item('Aceite de oliva', 'Despensa', unit: 'ud')),
        isTrue,
      );

      expect(
        isLevelTracked(
          _item('Garbanzos', 'Despensa', quantity: 570, unit: 'g'),
        ),
        isFalse,
      );
      expect(
        isLevelTracked(_item('Tomates', 'Nevera', quantity: 500, unit: 'g')),
        isFalse,
      );
      expect(
        isLevelTracked(_item('Leche', 'Nevera', quantity: 1000, unit: 'ml')),
        isFalse,
      );
      expect(
        isLevelTracked(_item('Manzanas', 'Nevera', quantity: 4, unit: 'ud')),
        isFalse,
      );
      expect(
        isLevelTracked(_item('Lentejas guisadas', 'Nevera', kind: 'dish')),
        isFalse,
      );
    },
  );

  test('isPantryItemOpened detecta envases empezados en gramos o ml', () {
    expect(
      isPantryItemOpened(
        _item('Garbanzos', 'Despensa', quantity: 370, unit: 'g'),
        570,
      ),
      isTrue,
    );
    expect(
      isPantryItemOpened(
        _item('Garbanzos', 'Despensa', quantity: 570, unit: 'g'),
        570,
      ),
      isFalse,
    );
    expect(
      isPantryItemOpened(
        _item('Garbanzos', 'Despensa', quantity: 1140, unit: 'g'),
        570,
      ),
      isFalse,
    );
  });

  test(
    'urgentPantryItems ordena caducados -> pronto -> tápers nevera -> abiertos',
    () {
      final opened = _item('Garbanzos', 'Despensa', quantity: 370, unit: 'g');
      final sealed = _item('Lentejas', 'Despensa', quantity: 500, unit: 'g');
      final dish = _item('Pollo asado', 'Nevera', kind: 'dish');
      final soon = _item('Leche', 'Nevera', expiresInDays: 2);
      final expired = _item('Yogur', 'Nevera', expiresInDays: -1);
      final spice = _item('Comino', 'Especias', expiresInDays: -30);

      final ordered = urgentPantryItems([
        opened,
        sealed,
        dish,
        soon,
        expired,
        spice,
      ], packSizeOf: (i) => i.name == 'Garbanzos' ? 570 : null);

      expect(ordered.map((e) => e.id).toList(), [
        'Yogur',
        'Leche',
        'Pollo asado',
        'Garbanzos',
      ]);
    },
  );

  testWidgets('KitchenZonesGrid cabe en 320 px con onAdd sin desbordar', (
    tester,
  ) async {
    KitchenZone? picked;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: KitchenZonesGrid(
                zones: summarizeZones(items),
                selected: null,
                onAdd: () {},
                onSelect: (z) => picked = z,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('9 productos'), findsOneWidget);
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
