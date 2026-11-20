import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/ingredient.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/local_store.dart';
import 'package:prezhome/services/offline_provider.dart';
import 'package:prezhome/services/offline_repository.dart';
import 'package:prezhome/services/pantry_usage.dart';
import 'package:prezhome/utils/offline_actions.dart';
import 'package:prezhome/widgets/freeze_dish_sheet.dart';

class _FakeRemoteSender implements RemoteSender {
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
  Future<List<Map<String, dynamic>>> fetch(String table) async => [
    for (final row in (tables[table]?.values ?? const <Map<String, dynamic>>[]))
      Map<String, dynamic>.from(row),
  ];
}

InventoryItem _item(
  String id,
  String name,
  double qty,
  String unit, {
  bool staple = false,
  String category = 'Nevera',
  DateTime? expires,
}) => InventoryItem(
  id: id,
  homeId: 'h',
  name: name,
  category: category,
  quantity: qty,
  unit: unit,
  isStaple: staple,
  expirationDate: expires,
);

void main() {
  test('resta en la misma medida y convierte kg a g', () {
    final uses = pantryUsesFor(
      [
        Ingredient(name: 'pollo', quantity: 600, unit: 'g'),
        Ingredient(name: 'cebolla', quantity: 2, unit: 'unidades'),
      ],
      [
        _item('1', 'Pechuga de pollo', 1, 'kg'),
        _item('2', 'Cebollas', 3, 'ud'),
      ],
    );
    expect(uses.firstWhere((u) => u.item.id == '1').left, closeTo(0.4, 1e-9));
    expect(uses.firstWhere((u) => u.item.id == '2').left, 1);
  });

  test('aplica las raciones y no baja de cero', () {
    final uses = pantryUsesFor(
      [Ingredient(name: 'leche', quantity: 500, unit: 'ml')],
      [_item('1', 'Leche entera', 1, 'litros')],
      factor: 3,
    );
    expect(uses.single.left, 0);
  });

  test('sin medida convertible gasta un envase', () {
    final uses = pantryUsesFor(
      [Ingredient(name: 'garbanzos cocidos', quantity: 400, unit: 'g')],
      [_item('1', 'Garbanzos', 2, 'botes', category: 'Despensa')],
    );
    expect(uses.single.left, 1);
  });

  test('con el peso del bote resta solo lo usado y pasa a gramos', () {
    final uses = pantryUsesFor(
      [Ingredient(name: 'garbanzos cocidos', quantity: 200, unit: 'g')],
      [_item('1', 'Garbanzos', 1, 'botes', category: 'Despensa')],
      packSizes: {'1': (size: 570, unit: 'g')},
    );
    expect(uses.single.left, closeTo(370, 1e-9));
    expect(uses.single.unitOut, 'g');
    expect(uses.single.used, closeTo(200, 1e-9));
  });

  test('dos recetas del mismo bote restan en proporción', () {
    final uses = pantryUsesFor(
      [
        Ingredient(name: 'garbanzos', quantity: 200, unit: 'g'),
        Ingredient(name: 'garbanzos', quantity: 0.3, unit: 'kg'),
      ],
      [_item('1', 'Garbanzos', 2, 'botes', category: 'Despensa')],
      packSizes: {'1': (size: 570, unit: 'g')},
    );
    expect(uses.single.left, closeTo(640, 1e-9));
  });

  test('suma lo comprado en la medida de la despensa', () {
    expect(mergePantryQuantity(370, 'g', 0.57, 'kg'), (
      quantity: 940.0,
      unit: 'g',
    ));
    expect(mergePantryQuantity(1, 'botes', 570, 'g', packSize: 570), (
      quantity: 2.0,
      unit: 'botes',
    ));
    expect(mergePantryQuantity(1, 'botes', 400, 'g'), (
      quantity: 2.0,
      unit: 'botes',
    ));
    expect(mergePantryQuantity(370, 'g', 1, 'botes'), isNull);
  });

  test('no toca básicos, especias, siempre en casa ni lo que no casa', () {
    final uses = pantryUsesFor(
      [
        Ingredient(name: 'aceite de oliva', quantity: 3, unit: 'cucharadas'),
        Ingredient(name: 'tomillo', quantity: 2, unit: 'cucharaditas'),
        Ingredient(name: 'arroz', quantity: 200, unit: 'g'),
        Ingredient(name: 'aceite de oliva', quantity: 30, unit: 'ml'),
      ],
      [
        _item('1', 'Aceite de oliva', 1, 'litros', category: 'Despensa'),
        _item('2', 'Tomillo', 1, 'ud', category: 'Especias'),
        _item('3', 'Arroz', 1, 'kg', staple: true),
        _item('4', 'Aceitunas de oliva', 2, 'botes'),
      ],
    );
    expect(uses, isEmpty);
  });

  test('gasta primero lo que antes caduca', () {
    final now = DateTime.now();
    final uses = pantryUsesFor(
      [Ingredient(name: 'yogur', quantity: 1, unit: 'ud')],
      [
        _item(
          'late',
          'Yogur',
          4,
          'ud',
          expires: now.add(const Duration(days: 9)),
        ),
        _item(
          'soon',
          'Yogur',
          4,
          'ud',
          expires: now.add(const Duration(days: 1)),
        ),
      ],
    );
    expect(uses.single.item.id, 'soon');
  });

  group('cierre post-cocina (descontar + nevera + congelador + undo)', () {
    test('fridgeDishItem crea táper de nevera a +3 días', () {
      final recipe = Recipe(
        id: 'rec-1',
        homeId: 'h',
        title: 'Lentejas caseras',
        servings: 4,
      );
      final dish = fridgeDishItem(recipe, 2, now: DateTime(2026, 5, 10));
      expect(dish.category, 'Nevera');
      expect(dish.kind, 'dish');
      expect(dish.servings, 2.0);
      expect(dish.expirationDate, DateTime(2026, 5, 13));
      expect(dish.bestBefore, DateTime(2026, 5, 13));
    });

    test(
      'completeCook descuenta, guarda sobras y undoCompleteCook revierte todo',
      () async {
        final store = InMemoryLocalStore();
        final sender = _FakeRemoteSender();
        final repo = OfflineRepository(
          table: kInventoryTable,
          store: store,
          sender: sender,
          homeId: 'h',
          gate: DrainGate(minRetryGapMs: 0, nowMillis: () => 0),
        );

        final chicken = _item('item-chicken', 'Pechuga de pollo', 1, 'kg');
        final rice = _item(
          'item-rice',
          'Arroz',
          200,
          'g',
          category: 'Despensa',
        );
        await repo.applyLocalWrite(
          buildInsertOp(
            table: kInventoryTable,
            id: chicken.id,
            payload: chicken.toCacheMap(),
            nowMillis: 1000,
            seq: 1,
          ),
        );
        await repo.applyLocalWrite(
          buildInsertOp(
            table: kInventoryTable,
            id: rice.id,
            payload: rice.toCacheMap(),
            nowMillis: 1001,
            seq: 2,
          ),
        );

        final recipe = Recipe(
          id: 'rec-pollo',
          homeId: 'h',
          title: 'Pollo con arroz',
          servings: 4,
          freezable: true,
        );
        final ings = [
          Ingredient(name: 'pollo', quantity: 600, unit: 'g'),
          Ingredient(name: 'arroz', quantity: 200, unit: 'g'),
        ];

        final uses = await PantryUsage.previewForRecipe(
          ingredients: ings,
          inventoryRepo: repo,
        );
        expect(uses, hasLength(2));

        final result = await PantryUsage.completeCook(
          recipe: recipe,
          usesToDeduct: uses,
          fridgeServings: 2,
          freezerServings: 1,
          inventoryRepo: repo,
          now: DateTime(2026, 5, 10, 14),
        );
        expect(result.hasAnyChange, isTrue);

        var rows = await repo.readCached();
        expect(rows.where((r) => r['id'] == 'item-rice'), isEmpty);
        final chickenAfter = rows.singleWhere((r) => r['id'] == 'item-chicken');
        expect(
          (chickenAfter['quantity'] as num).toDouble(),
          closeTo(0.4, 1e-9),
        );

        final dishes = rows.where((r) => r['kind'] == 'dish').toList();
        expect(dishes, hasLength(2));
        final fridgeDish = dishes.singleWhere((d) => d['category'] == 'Nevera');
        final freezerDish = dishes.singleWhere(
          (d) => d['category'] == 'Congelador',
        );
        expect((fridgeDish['servings'] as num).toDouble(), 2.0);
        expect((freezerDish['servings'] as num).toDouble(), 1.0);

        await PantryUsage.undoCompleteCook(result, inventoryRepo: repo);

        rows = await repo.readCached();
        expect(rows.where((r) => r['kind'] == 'dish'), isEmpty);
        final chickenRestored = rows.singleWhere(
          (r) => r['id'] == 'item-chicken',
        );
        expect(
          (chickenRestored['quantity'] as num).toDouble(),
          closeTo(1.0, 1e-9),
        );
        final riceRestored = rows.singleWhere((r) => r['name'] == 'Arroz');
        expect(
          (riceRestored['quantity'] as num).toDouble(),
          closeTo(200.0, 1e-9),
        );
      },
    );
  });
}
