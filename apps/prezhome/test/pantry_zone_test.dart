import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/services/shelf_life.dart';

void main() {
  group('pantryZoneFor', () {
    test('respeta una zona válida', () {
      expect(
        ShelfLife.pantryZoneFor(name: 'Leche', category: 'Nevera'),
        'Nevera',
      );
    });

    test('traduce los pasillos de la compra a zonas', () {
      expect(
        ShelfLife.pantryZoneFor(
          name: 'Tomillo',
          category: 'Especias y condimentos',
        ),
        'Especias',
      );
      expect(
        ShelfLife.pantryZoneFor(name: 'Vino blanco', category: 'Bebidas'),
        'Bebidas',
      );
      expect(
        ShelfLife.pantryZoneFor(name: 'Guisantes', category: 'Congelados'),
        'Congelador',
      );
    });

    test('un pasillo sin zona se deduce por el alimento', () {
      final zone = ShelfLife.pantryZoneFor(
        name: 'Espinacas frescas',
        category: 'Verduras',
      );
      expect(ShelfLife.pantryZones, contains(zone));
      expect(zone, isNot('Verduras'));
    });

    test('lo de casa va a Limpieza u Hogar', () {
      expect(
        ShelfLife.pantryZoneFor(
          name: 'Detergente',
          itemType: 'hogar',
          category: 'Limpieza y hogar',
        ),
        'Limpieza',
      );
    });
  });

  test('InventoryItem.fromMap tolera filas incompletas', () {
    final item = InventoryItem.fromMap({'id': '1', 'name': 'Arroz'});
    expect(item.category, 'Despensa');
    expect(item.quantity, 0);
    expect(item.unit, 'unidades');
  });
}
