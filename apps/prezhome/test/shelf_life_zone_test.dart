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
    expect(zone('Cosa', type: 'hogar'), 'Hogar'); // Varios recoge lo demás
    expect(zone('Arroz'), 'Despensa');
  });

  test(
    'envasados de larga vida: cerrados en la despensa, abiertos en nevera',
    () {
      int? days(String n, String z) => ShelfLife.estimateDays(n, z);
      String loc(String n) => ShelfLife.suggestLocation(n);
      // Tomate frito no es tomate fresco.
      expect(loc('Tomate frito'), 'Despensa');
      expect(days('Tomate frito Hacendado', 'Despensa'), 365);
      expect(days('Tomate frito', 'Nevera'), 5);
      expect(days('Tomates', 'Nevera'), 7);
      // Nata y leche de brik (UHT).
      expect(loc('Nata para cocinar'), 'Despensa');
      expect(days('Nata para cocinar', 'Despensa'), 150);
      expect(days('Leche entera', 'Despensa'), 150);
      expect(loc('Leche fresca'), 'Nevera');
      expect(days('Leche fresca', 'Nevera'), 7);
      // Yogur con leche sigue siendo yogur.
      expect(loc('Yogur de leche de cabra'), 'Nevera');
      expect(days('Yogur de leche de cabra', 'Nevera'), 20);
      // Atún en lata no es atún fresco; jamón cocido sigue en la nevera.
      expect(days('Atún claro en aceite', 'Despensa'), 1095);
      expect(days('Atún', 'Nevera'), 2);
      expect(loc('Garbanzos cocidos'), 'Despensa');
      expect(days('Jamón cocido', 'Nevera'), 10);
    },
  );
}
