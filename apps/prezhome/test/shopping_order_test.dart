import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/shopping_list_item.dart';

void main() {
  test('mismo created_at: el orden no depende del orden de llegada', () {
    final t = DateTime(2026, 11, 9);
    ShoppingListItem item(String id, {bool checked = false}) =>
        ShoppingListItem(
          id: id,
          homeId: 'h',
          name: id,
          createdAt: t,
          checked: checked,
        );
    final a = [item('b'), item('a'), item('c', checked: true)];
    // Tras un UPDATE el servidor devuelve la fila tocada al final.
    final b = [item('c', checked: true), item('a'), item('b')];
    a.sort(compareShoppingItems);
    b.sort(compareShoppingItems);
    expect(a.map((i) => i.id), ['a', 'b', 'c']);
    expect(b.map((i) => i.id), ['a', 'b', 'c']);
  });
}
