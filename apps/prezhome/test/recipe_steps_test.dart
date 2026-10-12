import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/recipe_steps.dart';

void main() {
  group('splitRecipeSteps', () {
    test('separa por líneas y quita la numeración', () {
      expect(splitRecipeSteps('1. Corta la cebolla.\n2) Sofríe 5 minutos.'), [
        'Corta la cebolla.',
        'Sofríe 5 minutos.',
      ]);
    });

    test('separa la numeración cuando viene todo junto', () {
      expect(splitRecipeSteps('1. Lava el arroz. 2. Hiérvelo. 3. Escurre.'), [
        'Lava el arroz.',
        'Hiérvelo.',
        'Escurre.',
      ]);
    });

    test('como último recurso separa por frases', () {
      expect(splitRecipeSteps('Mezcla todo. Hornea a 180 grados.'), [
        'Mezcla todo.',
        'Hornea a 180 grados.',
      ]);
    });

    test('texto vacío no da pasos', () {
      expect(splitRecipeSteps('  \n '), isEmpty);
    });
  });

  group('stepTimerMinutes', () {
    test('detecta minutos', () {
      expect(stepTimerMinutes('Hornea 25 minutos a 180 grados'), 25);
      expect(stepTimerMinutes('Cuece 8 min'), 8);
    });

    test('con un rango toma el mayor', () {
      expect(stepTimerMinutes('Cocina de 10 a 12 minutos'), 12);
      expect(stepTimerMinutes('Cocina 10-12 min'), 12);
    });

    test('detecta horas y horas con minutos', () {
      expect(stepTimerMinutes('Deja reposar 1 hora'), 60);
      expect(stepTimerMinutes('Guisa 1,5 horas'), 90);
      expect(stepTimerMinutes('Hornea 1 hora y 15 minutos'), 75);
    });

    test('sin tiempo devuelve null', () {
      expect(stepTimerMinutes('Añade 2 hojas de laurel'), isNull);
      expect(stepTimerMinutes('Sirve caliente'), isNull);
    });
  });
}
