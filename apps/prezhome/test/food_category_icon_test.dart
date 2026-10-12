import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/food_category_icon.dart';

void main() {
  group('CategoryIcons.categoryFor', () {
    test('no cae en verdura por la subcadena "col" (chocolate)', () {
      // "chocolate" contiene "col" pero NO debe clasificarse como verdura.
      expect(
        CategoryIcons.categoryFor('chocolate'),
        isNot(FoodCategory.verdura),
      );
    });

    test('"coliflor" sí es verdura (keyword propia)', () {
      expect(CategoryIcons.categoryFor('coliflor'), FoodCategory.verdura);
    });

    test('"col" exacta es verdura', () {
      expect(CategoryIcons.categoryFor('col'), FoodCategory.verdura);
      expect(CategoryIcons.categoryFor('col lombarda'), FoodCategory.verdura);
    });

    test('no cae en verdura por "ajo" dentro de "ajonjoli"', () {
      expect(
        CategoryIcons.categoryFor('ajonjoli'),
        isNot(FoodCategory.verdura),
      );
    });

    test('"ajo" exacto es verdura', () {
      expect(CategoryIcons.categoryFor('ajo'), FoodCategory.verdura);
      expect(CategoryIcons.categoryFor('ajo picado'), FoodCategory.verdura);
    });

    test('"arroz" es panaderia/cereales', () {
      expect(CategoryIcons.categoryFor('arroz'), FoodCategory.panaderia);
      expect(
        CategoryIcons.categoryFor('arroz integral'),
        FoodCategory.panaderia,
      );
    });

    test('un nombre raro cae en "otros" (neutro)', () {
      expect(CategoryIcons.categoryFor('xyzzy'), FoodCategory.otros);
      expect(CategoryIcons.categoryFor('cosa rara 123'), FoodCategory.otros);
    });

    test('el emoji neutro de "otros" es el carrito', () {
      expect(CategoryIcons.emojiFor('xyzzy'), '🛒');
    });

    test('categorias de comida habituales', () {
      expect(CategoryIcons.categoryFor('tomate'), FoodCategory.verdura);
      expect(CategoryIcons.categoryFor('manzanas'), FoodCategory.fruta);
      expect(CategoryIcons.categoryFor('pollo'), FoodCategory.carne);
      expect(CategoryIcons.categoryFor('salmon'), FoodCategory.pescado);
      expect(CategoryIcons.categoryFor('leche'), FoodCategory.lacteos);
      expect(CategoryIcons.categoryFor('pan'), FoodCategory.panaderia);
    });

    test('bebidas gana a lacteos para "leche de avena"', () {
      expect(CategoryIcons.categoryFor('leche de avena'), FoodCategory.bebidas);
      // Pero la leche normal sigue siendo lacteo.
      expect(CategoryIcons.categoryFor('leche'), FoodCategory.lacteos);
    });

    test('item de hogar sin match claro cae en limpieza (no casa vacia)', () {
      // Fallback cozy: para hogar usamos el icono de limpieza, no la casa
      // generica de FoodCategory.hogar.
      expect(
        CategoryIcons.categoryFor('cosa rara', itemType: 'hogar'),
        FoodCategory.limpieza,
      );
      expect(
        CategoryIcons.categoryFor('cosa rara', itemType: 'hogar').icon,
        Icons.cleaning_services,
      );
    });

    test('item de hogar con match de limpieza respeta la categoria', () {
      expect(
        CategoryIcons.categoryFor('detergente', itemType: 'hogar'),
        FoodCategory.limpieza,
      );
    });

    test('productos de limpieza/hogar nuevos se clasifican como limpieza', () {
      // Casos del feedback real de la usuaria: "Bastoncillos" ya no debe caer
      // en la casa generica.
      expect(CategoryIcons.categoryFor('Bastoncillos'), FoodCategory.limpieza);
      expect(
        CategoryIcons.categoryFor('bastoncillos', itemType: 'hogar'),
        FoodCategory.limpieza,
      );
      expect(CategoryIcons.categoryFor('algodon'), FoodCategory.limpieza);
      expect(
        CategoryIcons.categoryFor('papel de cocina'),
        FoodCategory.limpieza,
      );
      expect(
        CategoryIcons.categoryFor('rollo de cocina'),
        FoodCategory.limpieza,
      );
    });

    test('un producto de limpieza NO muestra el icono de casa generica', () {
      expect(CategoryIcons.iconFor('Bastoncillos'), isNot(Icons.home));
      expect(CategoryIcons.iconFor('Bastoncillos'), Icons.cleaning_services);
    });

    test('normalize ignora acentos y mayusculas', () {
      expect(CategoryIcons.normalize('Plátano'), 'platano');
      expect(CategoryIcons.normalize('  JAMÓN '), 'jamon');
    });

    test('match es robusto con acentos en el nombre', () {
      expect(CategoryIcons.categoryFor('Plátano'), FoodCategory.fruta);
      expect(CategoryIcons.categoryFor('Jamón serrano'), FoodCategory.carne);
    });
  });
}
