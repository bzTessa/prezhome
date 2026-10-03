import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/nutrition_profile.dart';

void main() {
  group('NutritionProfile preferencias alimentarias', () {
    test('fromMap parsea diet, allergies, disliked y cook_time_pref', () {
      // allergies/disliked llegan de Supabase (text[]) como List.
      final p = NutritionProfile.fromMap({
        'id': 'user-1',
        'diet': 'vegetariana',
        'allergies': ['frutos secos', 'lactosa'],
        'disliked': ['cebolla'],
        'cook_time_pref': 'rapido',
      });

      expect(p.diet, 'vegetariana');
      expect(p.allergies, ['frutos secos', 'lactosa']);
      expect(p.disliked, ['cebolla']);
      expect(p.cookTimePref, 'rapido');
    });

    test('fromMap con campos ausentes da defaults neutros', () {
      final p = NutritionProfile.fromMap({'id': 'user-2'});

      expect(p.diet, isNull);
      expect(p.allergies, isEmpty);
      expect(p.disliked, isEmpty);
      expect(p.cookTimePref, isNull);
    });

    test('fromMap convierte elementos no string a string en las listas', () {
      final p = NutritionProfile.fromMap({
        'id': 'user-3',
        'allergies': ['gluten', 42],
      });

      expect(p.allergies, ['gluten', '42']);
    });

    test('toUpdateMap incluye las 4 claves con los valores correctos', () {
      final p = NutritionProfile(
        id: 'user-4',
        diet: 'vegana',
        allergies: const ['soja'],
        disliked: const ['pimiento', 'brócoli'],
        cookTimePref: 'elaborado',
      );

      final map = p.toUpdateMap();
      expect(map.containsKey('diet'), isTrue);
      expect(map.containsKey('allergies'), isTrue);
      expect(map.containsKey('disliked'), isTrue);
      expect(map.containsKey('cook_time_pref'), isTrue);

      expect(map['diet'], 'vegana');
      expect(map['allergies'], ['soja']);
      expect(map['disliked'], ['pimiento', 'brócoli']);
      expect(map['cook_time_pref'], 'elaborado');
    });

    test('toUpdateMap con defaults serializa listas vacías y nulls', () {
      final p = NutritionProfile(id: 'user-5');
      final map = p.toUpdateMap();

      expect(map['diet'], isNull);
      expect(map['allergies'], isEmpty);
      expect(map['disliked'], isEmpty);
      expect(map['cook_time_pref'], isNull);
    });

    test('las etiquetas en español cubren los códigos esperados', () {
      expect(
        NutritionProfile.dietLabels.keys,
        containsAll(<String>[
          'omnivora',
          'vegetariana',
          'vegana',
          'pescetariana',
          'baja_carbo',
          'sin_gluten',
        ]),
      );
      expect(
        NutritionProfile.cookTimeLabels.keys,
        containsAll(<String>['rapido', 'normal', 'elaborado']),
      );
    });
  });
}
