import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/utils/food_restrictions.dart';

Recipe _r(String title, List<String> ingredients) => Recipe(
  id: title,
  homeId: 'h',
  title: title,
  servings: 2,
  ingredientNames: ingredients,
);

void main() {
  group('FoodRestrictions.fromRows', () {
    test('junta las alergias de todos y "sin gluten" cuenta como alergia', () {
      final r = FoodRestrictions.fromRows([
        {
          'diet': 'omnivora',
          'allergies': ['Frutos secos'],
          'disliked': [],
        },
        {
          'diet': 'sin_gluten',
          'allergies': [],
          'disliked': ['Cebolla'],
        },
      ]);
      expect(r.allergies, {'frutos secos', 'gluten'});
      expect(r.disliked, {'cebolla'});
      expect(r.diet, isNull);
    });

    test('la dieta es la menos estricta de quien la ha dicho', () {
      expect(
        FoodRestrictions.fromRows([
          {'diet': 'vegana'},
          {'diet': 'vegetariana'},
          {'diet': null},
        ]).diet,
        'vegetariana',
      );
      expect(
        FoodRestrictions.fromRows([
          {'diet': 'vegetariana'},
          {'diet': 'omnivora'},
        ]).diet,
        isNull,
      );
    });
  });

  group('blockerIn', () {
    const gluten = FoodRestrictions(allergies: {'gluten'});
    const lactosa = FoodRestrictions(allergies: {'lactosa'});

    test('encuentra el alérgeno en el título o los ingredientes', () {
      expect(gluten.blockerIn(['Macarrones con tomate']), 'gluten');
      expect(gluten.blockerIn(['Ensalada', 'pan rallado']), 'gluten');
      expect(gluten.blockerIn(['Lentejas', 'zanahoria', 'pimentón']), isNull);
    });

    test('no confunde palabras parecidas ni versiones sin el alérgeno', () {
      expect(gluten.blockerIn(['Panceta a la plancha']), isNull);
      expect(gluten.blockerIn(['Tortitas de arroz', 'harina de maíz']), isNull);
      expect(gluten.blockerIn(['Pasta sin gluten']), isNull);
      expect(lactosa.blockerIn(['Curry', 'leche de coco']), isNull);
      expect(lactosa.blockerIn(['Leche sin lactosa']), isNull);
      expect(lactosa.blockerIn(['Arroz con leche']), 'lactosa');
      expect(lactosa.blockerIn(['Quesos variados']), 'lactosa');
    });

    test('las dietas quitan lo que no encaja', () {
      const veg = FoodRestrictions(diet: 'vegetariana');
      const vegan = FoodRestrictions(diet: 'vegana');
      const pesc = FoodRestrictions(diet: 'pescetariana');
      expect(veg.blockerIn(['Lentejas con chorizo']), 'vegetariana');
      expect(veg.blockerIn(['Merluza en salsa']), 'vegetariana');
      expect(veg.blockerIn(['Tortilla de patatas', 'huevo']), isNull);
      expect(vegan.blockerIn(['Tortilla de patatas', 'huevos']), 'vegana');
      expect(vegan.blockerIn(['Garbanzos con espinacas']), isNull);
      expect(pesc.blockerIn(['Lomo de salmón al horno']), isNull);
      expect(pesc.blockerIn(['Lomo de cerdo']), 'pescetariana');
      expect(veg.blockerIn(['Hamburguesa vegetal']), isNull);
    });

    test('una alergia escrita a mano se busca tal cual', () {
      const kiwi = FoodRestrictions(allergies: {'kiwi'});
      expect(kiwi.blockerIn(['Macedonia', 'kiwis']), 'kiwi');
      expect(kiwi.blockerIn(['Macedonia', 'fresas']), isNull);
    });
  });

  group('safeRecipes', () {
    final recipes = [
      _r('Macarrones', ['macarrones', 'tomate']),
      _r('Lentejas', ['lentejas', 'cebolla']),
      _r('Pisto', ['calabacín', 'pimiento']),
      _r('Arroz', ['arroz', 'cebolla']),
    ];

    test('nunca deja una receta con alérgeno', () {
      final out = const FoodRestrictions(
        allergies: {'gluten'},
      ).safeRecipes(recipes);
      expect(out.map((r) => r.title), ['Lentejas', 'Pisto', 'Arroz']);
    });

    test('lo que no gusta solo se quita si quedan bastantes recetas', () {
      const r = FoodRestrictions(disliked: {'cebolla'});
      expect(r.safeRecipes(recipes, minLiked: 2).map((r) => r.title), [
        'Macarrones',
        'Pisto',
      ]);
      expect(r.safeRecipes(recipes, minLiked: 3).length, 4);
    });

    test('sin restricciones devuelve todo', () {
      expect(FoodRestrictions.empty.safeRecipes(recipes), recipes);
    });
  });
}
