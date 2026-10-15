import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/shelf_life.dart';

void main() {
  test('Zona de la despensa al comprar', () {
    String zone(String name, {String? aisle, String type = 'comida'}) =>
        ShelfLife.pantryZoneFor(name: name, itemType: type, category: aisle);
    expect(zone('Helado'), 'Congelador');
    expect(zone('Helado de proteínas', aisle: 'Lácteos'), 'Congelador');
    expect(zone('Bolsas de basura extra'), 'Limpieza');
    expect(zone('Gel de baño coco'), 'Hogar');
    expect(zone('Ensaladilla rusa'), 'Nevera');
    expect(zone('Cosa', aisle: 'Platos preparados'), 'Nevera');
    expect(zone('Cosa', type: 'hogar'), 'Limpieza');
    expect(zone('Arroz'), 'Despensa');
  });
}
