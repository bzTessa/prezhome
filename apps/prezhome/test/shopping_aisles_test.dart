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
}
