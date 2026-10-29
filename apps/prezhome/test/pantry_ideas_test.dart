import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/utils/pantry_ideas.dart';

InventoryItem _item(
  String name, {
  DateTime? expires,
  String type = 'comida',
  double qty = 1,
}) => InventoryItem.fromMap({
  'id': name,
  'home_id': 'h',
  'name': name,
  'category': 'Nevera',
  'item_type': type,
  'quantity': qty,
  'unit': 'ud',
  'expiration_date': expires?.toIso8601String(),
});

void main() {
  group('pantryNamesForIdeas', () {
    test('primero lo que caduca antes y sin fecha al final', () {
      final names = pantryNamesForIdeas([
        _item('Arroz'),
        _item('Pollo', expires: DateTime(2026, 10, 14)),
        _item('Espinacas', expires: DateTime(2026, 10, 13)),
      ]);
      expect(names, ['Espinacas', 'Pollo', 'Arroz']);
    });

    test('descarta hogar, agotados y duplicados', () {
      final names = pantryNamesForIdeas([
        _item('Lejía', type: 'hogar'),
        _item('Huevos', qty: 0),
        _item('Tomates'),
        _item('tomates'),
      ]);
      expect(names, ['Tomates']);
    });

    test('respeta el máximo', () {
      final items = [for (var i = 0; i < 10; i++) _item('Cosa $i')];
      expect(pantryNamesForIdeas(items, max: 3), hasLength(3));
    });
  });

  group('splitByPantry', () {
    test('casa por palabra significativa y plurales', () {
      final r = splitByPantry(
        ['Pechuga de pollo', 'Tomate', 'Nata para cocinar'],
        ['Pollo', 'Tomates'],
      );
      expect(r.have, ['Pechuga de pollo', 'Tomate']);
      expect(r.missing, ['Nata para cocinar']);
    });

    test('lo que falta no casa por una palabra suelta', () {
      final r = splitByPantry(
        [
          'Aceitunas negras',
          'Diente de ajo',
          'Pimienta negra',
          'Sal (al gusto)',
        ],
        ['Aceite de oliva', 'Ajo', 'Pimienta negra molida'],
      );
      expect(r.have, ['Diente de ajo', 'Pimienta negra']);
      expect(r.missing, ['Aceitunas negras']);
    });

    test('los básicos nunca faltan', () {
      final r = splitByPantry(['Sal', 'Aceite de oliva', 'Agua'], []);
      expect(r.have, isEmpty);
      expect(r.missing, isEmpty);
    });
  });

  test('withPrimarySupermarket pone el elegido primero sin duplicar', () {
    expect(withPrimarySupermarket(['lidl', 'mercadona'], 'mercadona'), [
      'mercadona',
      'lidl',
    ]);
    expect(withPrimarySupermarket([], 'dia'), ['dia']);
    expect(withPrimarySupermarket(['lidl'], ' '), ['lidl']);
  });

  test('formatEuros usa coma decimal', () {
    expect(formatEuros(1.8), '1,80\u00A0€');
  });
}
