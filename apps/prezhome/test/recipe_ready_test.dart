import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/utils/recipe_browse.dart';

Recipe _r(String title, List<String> ings) => Recipe.fromMap({
  'id': title,
  'home_id': 'h',
  'title': title,
  'recipe_ingredients': [
    for (final i in ings) {'name': i},
  ],
});

void main() {
  final pantry = ['Huevos', 'Patatas', 'Cebolla', 'Arroz'];

  test('sin despensa o sin ingredientes no se sabe', () {
    expect(missingAtHome(_r('a', ['Huevos']), const []), isNull);
    expect(missingAtHome(_r('a', const []), pantry), isNull);
  });

  test('cuenta lo que falta y da por supuestos los básicos', () {
    final tortilla = _r('Tortilla', ['Huevos', 'Patatas', 'Sal', 'Aceite']);
    final pollo = _r('Pollo al limón', ['Pollo', 'Limón', 'Arroz']);
    expect(missingAtHome(tortilla, pantry), 0);
    expect(missingAtHome(pollo, pantry), 2);
  });

  test('lista para cocinar: no falta nada y hay al menos dos cosas', () {
    final tortilla = _r('Tortilla', ['Huevos', 'Patatas', 'Sal']);
    final arroz = _r('Arroz blanco', ['Arroz', 'Sal']);
    final pollo = _r('Pollo', ['Pollo', 'Arroz']);
    expect(readyToCook([tortilla, arroz, pollo], pantry), [tortilla]);
  });
}
