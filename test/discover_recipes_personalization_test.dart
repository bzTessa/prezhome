import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/discover_recipes_screen.dart';
import 'package:prezhome/models/nutrition_profile.dart';

void main() {
  group('DiscoverRecipesScreen.resolveDiet', () {
    test('usa la etiqueta del perfil cuando la dieta es mapeable', () {
      // 'vegana' existe en dietLabels -> gana sobre el dropdown local.
      expect(
        DiscoverRecipesScreen.resolveDiet('vegana', 'sin restricción'),
        NutritionProfile.dietLabels['vegana'],
      );
    });

    test('cae al dropdown local cuando el perfil no tiene dieta', () {
      expect(
        DiscoverRecipesScreen.resolveDiet(null, 'vegetariana'),
        'vegetariana',
      );
    });

    test('cae al dropdown local cuando el código de perfil no mapea', () {
      // Clave desconocida -> no hay etiqueta -> se usa la local (sin regresión).
      expect(
        DiscoverRecipesScreen.resolveDiet('desconocida', 'rápida'),
        'rápida',
      );
    });

    test('mapea baja_carbo y sin_gluten como etiquetas de restricción', () {
      expect(
        DiscoverRecipesScreen.resolveDiet('baja_carbo', 'sin restricción'),
        'Baja en carbohidratos',
      );
      expect(
        DiscoverRecipesScreen.resolveDiet('sin_gluten', 'sin restricción'),
        'Sin gluten',
      );
    });

    test('omnivora no es override: manda la dieta local del dropdown', () {
      // "De todo" no restringe nada, así que el dropdown local tiene efecto.
      expect(
        DiscoverRecipesScreen.resolveDiet('omnivora', 'vegetariana'),
        'vegetariana',
      );
    });
  });

  group('DiscoverRecipesScreen.profileDietOverrides', () {
    test('true cuando hay dieta de perfil mapeable', () {
      expect(DiscoverRecipesScreen.profileDietOverrides('vegetariana'), isTrue);
    });

    test('false cuando no hay dieta de perfil', () {
      expect(DiscoverRecipesScreen.profileDietOverrides(null), isFalse);
    });

    test('false cuando el código de perfil no mapea', () {
      expect(DiscoverRecipesScreen.profileDietOverrides('inventada'), isFalse);
    });

    test('false para omnivora ("De todo" no es restricción real)', () {
      expect(DiscoverRecipesScreen.profileDietOverrides('omnivora'), isFalse);
    });

    test('true para el resto de dietas mapeables', () {
      expect(DiscoverRecipesScreen.profileDietOverrides('vegana'), isTrue);
      expect(
        DiscoverRecipesScreen.profileDietOverrides('pescetariana'),
        isTrue,
      );
      expect(DiscoverRecipesScreen.profileDietOverrides('baja_carbo'), isTrue);
      expect(DiscoverRecipesScreen.profileDietOverrides('sin_gluten'), isTrue);
    });
  });

  group('DiscoverRecipesScreen.cookTimeLabel', () {
    test('mapea las claves de tiempo de cocina a etiqueta legible', () {
      expect(
        DiscoverRecipesScreen.cookTimeLabel('rapido'),
        NutritionProfile.cookTimeLabels['rapido'],
      );
      expect(
        DiscoverRecipesScreen.cookTimeLabel('normal'),
        NutritionProfile.cookTimeLabels['normal'],
      );
      expect(
        DiscoverRecipesScreen.cookTimeLabel('elaborado'),
        NutritionProfile.cookTimeLabels['elaborado'],
      );
    });

    test('null cuando no hay preferencia o no mapea', () {
      expect(DiscoverRecipesScreen.cookTimeLabel(null), isNull);
      expect(DiscoverRecipesScreen.cookTimeLabel('otra'), isNull);
    });
  });
}
