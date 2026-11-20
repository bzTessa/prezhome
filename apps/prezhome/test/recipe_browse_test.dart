import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/utils/recipe_browse.dart';

Recipe _r(
  String title, {
  List<String> types = const [],
  List<String> ingredients = const [],
  int? minutes,
  int? kcal,
  bool fav = false,
  bool freezes = false,
}) => Recipe(
  id: title,
  homeId: 'h',
  title: title,
  servings: 2,
  mealTypes: types,
  ingredientNames: ingredients,
  prepTimeMinutes: minutes,
  calories: kcal,
  isFavorite: fav,
  freezable: freezes,
);

final _all = [
  _r(
    'Bowl de pollo salteado',
    types: ['lunch'],
    ingredients: ['Arroz'],
    minutes: 25,
    kcal: 480,
  ),
  _r(
    'Salmón al horno',
    types: ['dinner'],
    ingredients: ['Patata'],
    minutes: 40,
    kcal: 550,
  ),
  _r('Arroz con leche', types: ['dessert'], minutes: 15, kcal: 300, fav: true),
  _r('Café doble', types: ['breakfast', 'drink'], minutes: 5),
];

List<String> _titles(List<Recipe> rs) => rs.map((r) => r.title).toList();

void main() {
  test('busca sin acentos, por varias palabras y por ingrediente', () {
    expect(_titles(browseRecipes(_all, query: 'salmon')), ['Salmón al horno']);
    expect(_titles(browseRecipes(_all, query: 'pollo arroz')), [
      'Bowl de pollo salteado',
    ]);
    // El nombre que coincide va antes que la que solo lleva el ingrediente.
    expect(_titles(browseRecipes(_all, query: 'ARROZ')), [
      'Arroz con leche',
      'Bowl de pollo salteado',
    ]);
  });

  test('categorías: tipo, rápidas, ligeras y favoritas', () {
    expect(_titles(browseRecipes(_all, category: 'quick')), [
      'Arroz con leche',
      'Café doble',
    ]);
    expect(_titles(browseRecipes(_all, category: 'light')), [
      'Arroz con leche',
    ]);
    expect(_titles(browseRecipes(_all, category: 'drink')), ['Café doble']);
    expect(recipeCategoryCounts(_all), {
      'favorites': 1,
      'quick': 2,
      'light': 1,
      'breakfast': 1,
      'lunch': 1,
      'dinner': 1,
      'dessert': 1,
      'drink': 1,
    });
  });

  test('orden: A-Z, más rápidas y menos calorías (sin dato al final)', () {
    expect(
      _titles(browseRecipes(_all, sort: RecipeSort.az)).first,
      'Arroz con leche',
    );
    expect(_titles(browseRecipes(_all, sort: RecipeSort.fastest)), [
      'Café doble',
      'Arroz con leche',
      'Bowl de pollo salteado',
      'Salmón al horno',
    ]);
    expect(
      _titles(browseRecipes(_all, sort: RecipeSort.lightest)).last,
      'Café doble',
    );
  });

  test('fromMap lee los ingredientes anidados', () {
    final r = Recipe.fromMap({
      'id': '1',
      'home_id': 'h',
      'title': 'X',
      'recipe_ingredients': [
        {'name': 'Huevo'},
        {'name': null},
      ],
    });
    expect(r.ingredientNames, ['Huevo']);
  });

  group('filtros combinables y con lo que tengo', () {
    final comboPool = [
      _r(
        'Crema de calabacín',
        types: ['dinner'],
        ingredients: ['Calabacín', 'Patata'],
        minutes: 20,
        fav: true,
        freezes: true,
      ),
      _r(
        'Tostada con aguacate',
        types: ['breakfast'],
        ingredients: ['Pan', 'Aguacate'],
        minutes: 5,
        fav: true,
      ),
      _r(
        'Merluza al vapor',
        types: ['dinner'],
        ingredients: ['Merluza', 'Limón'],
        minutes: 15,
      ),
      _r(
        'Lentejas estofadas',
        types: ['lunch'],
        ingredients: ['Lentejas', 'Zanahoria'],
        minutes: 45,
        freezes: true,
      ),
    ];

    test('combina momento + favoritas sin mezclar otros tipos', () {
      expect(
        _titles(
          browseRecipes(comboPool, categories: const {'dinner', 'favorites'}),
        ),
        ['Crema de calabacín'],
      );
    });

    test('usa OR entre tipos de plato', () {
      expect(
        _titles(
          browseRecipes(comboPool, categories: const {'lunch', 'dinner'}),
        ),
        ['Crema de calabacín', 'Merluza al vapor', 'Lentejas estofadas'],
      );
    });

    test('usa AND entre atributos (rápidas + congelables)', () {
      expect(
        _titles(
          browseRecipes(comboPool, categories: const {'quick', 'freezer'}),
        ),
        ['Crema de calabacín'],
      );
    });

    test('combina onlyReady con despensa y tipo de plato', () {
      const pantry = ['Calabacín', 'Patata', 'Pan', 'Aguacate'];
      expect(
        _titles(
          browseRecipes(
            comboPool,
            categories: const {'dinner'},
            onlyReady: true,
            pantry: pantry,
          ),
        ),
        ['Crema de calabacín'],
      );
    });
  });
}
