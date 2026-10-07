import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/shopping_categories.dart';

void main() {
  group('categorías por defecto', () {
    test('no hay nombres duplicados', () {
      final names = defaultCategoryNames();
      final unique = names.toSet();
      expect(unique.length, names.length);
    });

    test('"Sin categorizar" existe y va la última', () {
      final names = defaultCategoryNames();
      expect(names.contains(kUncategorizedName), isTrue);
      expect(names.last, kUncategorizedName);
    });

    test('incluye las secciones de súper en español esperadas', () {
      final names = defaultCategoryNames();
      expect(names, contains('Frutas y Verduras'));
      expect(names, contains('Carnes y Pescados'));
      expect(names, contains('Lácteos'));
      expect(names, contains('Panadería'));
      expect(names, contains('Congelados'));
      expect(names, contains('Conservas'));
      expect(names, contains('Pastas y Cereales'));
      expect(names, contains('Bebidas'));
      expect(names, contains('Limpieza y Hogar'));
      expect(names, contains('Condimentos'));
    });
  });

  group('defaultCategoryFor', () {
    test('fruta/verdura', () {
      expect(defaultCategoryFor('Manzanas'), 'Frutas y Verduras');
      expect(defaultCategoryFor('Tomate'), 'Frutas y Verduras');
    });

    test('carnes y pescados', () {
      expect(defaultCategoryFor('Pechuga de pollo'), 'Carnes y Pescados');
      expect(defaultCategoryFor('Salmón'), 'Carnes y Pescados');
    });

    test('condimentos (sal, pimienta, aceite)', () {
      expect(defaultCategoryFor('Sal'), 'Condimentos');
      expect(defaultCategoryFor('Pimienta negra'), 'Condimentos');
      expect(defaultCategoryFor('Aceite de oliva virgen extra'), 'Condimentos');
    });

    test('"sal" (<=3 letras) no arrastra a "salmón"', () {
      // salmón debe caer en Carnes y Pescados, no en Condimentos por "sal".
      expect(defaultCategoryFor('Salmón'), 'Carnes y Pescados');
    });

    test('sin match claro -> Sin categorizar', () {
      expect(defaultCategoryFor('Chuchería rara xyz'), kUncategorizedName);
      expect(defaultCategoryFor(''), kUncategorizedName);
    });

    test('normalización estable: acentos y mayúsculas no cambian el resultado', () {
      expect(defaultCategoryFor('plátano'), defaultCategoryFor('PLATANO'));
      expect(defaultCategoryFor('Café'), defaultCategoryFor('cafe'));
    });
  });

  group('normalizeCategoryText', () {
    test('quita acentos y pasa a minúsculas', () {
      expect(normalizeCategoryText('Plátano'), 'platano');
      expect(normalizeCategoryText('ESPÁRRAGOS'), 'esparragos');
    });
  });
}
