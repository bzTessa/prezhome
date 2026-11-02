import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/shopping_categories.dart';

typedef _Item = ({String name, String? catId, String? cat});

void main() {
  test('agrupa en el orden de las categorías del hogar', () {
    final cats = [
      (id: 'c1', name: 'Limpieza y Hogar'),
      (id: 'c2', name: 'Frutas y Verduras'),
      (id: 'c3', name: kUncategorizedName),
    ];
    final List<_Item> items = [
      (name: 'Tomates', catId: null, cat: null),
      (name: 'Lejía', catId: 'c1', cat: null),
      (name: 'Cosa rara', catId: null, cat: null),
      (name: 'Peras', catId: null, cat: 'frutas y verduras'),
    ];
    final groups = groupByHomeCategories<_Item>(
      items,
      cats,
      categoryIdOf: (i) => i.catId,
      categoryNameOf: (i) => i.cat,
      nameOf: (i) => i.name,
    );
    expect(groups.map((g) => g.$1), [
      'Limpieza y Hogar',
      'Frutas y Verduras',
      kUncategorizedName,
    ]);
    expect(groups[1].$2.map((i) => i.name), ['Tomates', 'Peras']);
    expect(groups[2].$2.map((i) => i.name), ['Cosa rara']);
  });

  test('lo habitual: lo más comprado que no está ya en la lista', () {
    final usual = usualProducts(
      [
        (name: 'Leche', times: 9),
        (name: 'Pan', times: 5),
        (name: 'Atún', times: 1),
        (name: null, times: 7),
        (name: 'Huevos', times: 6),
      ],
      ['leche'],
    );
    expect(usual, ['Huevos', 'Pan']);
  });

  test('te toca: lo que se compra con ritmo y ya hay que reponer', () {
    final now = DateTime(2026, 11, 2);
    DateTime ago(int d) => now.subtract(Duration(days: d));
    final due = dueProducts(
      [
        // Cada 5 días, última hace 6: toca.
        (name: 'Leche', date: ago(16)),
        (name: 'leche', date: ago(11)),
        (name: 'Leche', date: ago(6)),
        // Cada 2 días, última hace 4: muy atrasado, va primero.
        (name: 'Pan', date: ago(8)),
        (name: 'Pan', date: ago(6)),
        (name: 'Pan', date: ago(4)),
        // Cada 10 días, última ayer: aún no.
        (name: 'Arroz', date: ago(11)),
        (name: 'Arroz', date: ago(1)),
        // Una sola compra: sin ritmo.
        (name: 'Atún', date: ago(30)),
        // Ya en la lista.
        (name: 'Huevos', date: ago(20)),
        (name: 'Huevos', date: ago(10)),
        // Cada 2 días pero hace 40: abandonado.
        (name: 'Kéfir', date: ago(42)),
        (name: 'Kéfir', date: ago(40)),
      ],
      ['huevos'],
      now: now,
    );
    expect(due, [(name: 'Pan', everyDays: 2), (name: 'Leche', everyDays: 5)]);
  });
}
