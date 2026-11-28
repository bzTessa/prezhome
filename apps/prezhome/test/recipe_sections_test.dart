import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/recipes_screen.dart';

Recipe _r(String title, List<String> types, {bool fav = false}) => Recipe(
  id: title,
  homeId: 'h',
  title: title,
  servings: 2,
  mealTypes: types,
  isFavorite: fav,
);

Map<String, List<String>> _titles(List<MapEntry<String, List<Recipe>>> g) => {
  for (final e in g) e.key: e.value.map((r) => r.title).toList(),
};

void main() {
  test('cada receta va en una sección de comida, por momento del día', () {
    final groups = groupRecipesBySection([
      _r('Café', ['breakfast', 'drink'], fav: true),
      _r('Lentejas', ['lunch', 'dinner']),
      _r('Tortilla', ['dinner', 'breakfast']),
      _r('Cheesecake', ['snack', 'dessert']),
      _r('Sin tipo', []),
      _r('Pollo', ['lunch']),
    ]);
    expect(_titles(groups), {
      'breakfast': ['Café', 'Tortilla'],
      'lunch': ['Lentejas', 'Pollo'],
      'dessert': ['Cheesecake'],
      'other': ['Sin tipo'],
    });
  });

  test('favoritas primero, luego lo que más se come, luego lo nuevo', () {
    final groups = groupRecipesBySection(
      [
        _r('Nueva', ['lunch']),
        _r('Pollo', ['lunch']),
        _r('Lentejas', ['lunch']),
        _r('Paella', ['lunch'], fav: true),
      ],
      eaten: {'Lentejas': 5, 'Pollo': 2},
    );
    expect(_titles(groups), {
      'usual': ['Lentejas', 'Pollo'],
      'lunch': ['Paella', 'Lentejas', 'Pollo', 'Nueva'],
    });
    expect(groups.first.key, 'usual');
  });
}
