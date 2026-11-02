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

void main() {
  test('cada receta sale una vez, en su sección y en orden', () {
    final groups = groupRecipesBySection([
      _r('Café', ['breakfast', 'drink'], fav: true),
      _r('Lentejas', ['lunch', 'dinner']),
      _r('Tortilla', ['dinner', 'breakfast']),
      _r('Cheesecake', ['snack', 'dessert']),
      _r('Sin tipo', []),
      _r('Pollo', ['lunch']),
    ]);
    expect(
      {for (final g in groups) g.key: g.value.map((r) => r.title).toList()},
      {
        'favorites': ['Café'],
        'breakfast': ['Tortilla'],
        'lunch': ['Lentejas', 'Pollo'],
        'dessert': ['Cheesecake'],
        'other': ['Sin tipo'],
      },
    );
    expect(groups.map((g) => g.key).toList(), [
      'favorites',
      'breakfast',
      'lunch',
      'dessert',
      'other',
    ]);
  });
}
