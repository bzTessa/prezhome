import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/food_photo_service.dart';
import 'package:prezhome/theme/app_theme.dart';
import 'package:prezhome/widgets/food_category_icon.dart';

void main() {
  group('CategoryIcons estilo cozy (icono + colores) por categoría', () {
    test('iconFor devuelve el icono de la categoría inferida', () {
      // Verdura
      expect(CategoryIcons.iconFor('tomate'), FoodCategory.verdura.icon);
      // Carne
      expect(CategoryIcons.iconFor('pollo'), FoodCategory.carne.icon);
      // Pescado
      expect(CategoryIcons.iconFor('salmon'), FoodCategory.pescado.icon);
      // Fruta
      expect(CategoryIcons.iconFor('manzana'), FoodCategory.fruta.icon);
      // Lácteos
      expect(CategoryIcons.iconFor('leche'), FoodCategory.lacteos.icon);
      // Panadería/Cereales
      expect(CategoryIcons.iconFor('arroz'), FoodCategory.panaderia.icon);
    });

    test('nombre raro cae en el icono neutro de "otros"', () {
      expect(CategoryIcons.iconFor('xyzzy'), FoodCategory.otros.icon);
      expect(CategoryIcons.iconFor('xyzzy'), Icons.shopping_cart);
    });

    test('item de hogar sin match claro usa el icono de limpieza', () {
      // Decisión UX: para productos de hogar el fallback usa el icono de
      // limpieza (escoba/esponja) en vez de la casa vacía, que la usuaria
      // percibía como genérica (p. ej. "Bastoncillos").
      expect(
        CategoryIcons.iconFor('cosa rara', itemType: 'hogar'),
        FoodCategory.limpieza.icon,
      );
      expect(
        CategoryIcons.iconFor('cosa rara', itemType: 'hogar'),
        Icons.cleaning_services,
      );
    });

    test('backgroundColorFor/foregroundColorFor coherentes por categoría', () {
      // Verdura -> salvia.
      expect(CategoryIcons.backgroundColorFor('tomate'), AppColors.sageBg);
      expect(CategoryIcons.foregroundColorFor('tomate'), AppColors.sage);
      // Carne -> terracota.
      expect(CategoryIcons.backgroundColorFor('pollo'), AppColors.terracottaBg);
      expect(CategoryIcons.foregroundColorFor('pollo'), AppColors.terracotta);
      // Fruta -> melocotón.
      expect(CategoryIcons.backgroundColorFor('manzana'), AppColors.peachBg);
      expect(CategoryIcons.foregroundColorFor('manzana'), AppColors.peach);
    });

    test(
      'un nombre raro usa un par de colores neutro cozy (no transparente)',
      () {
        final bg = CategoryIcons.backgroundColorFor('xyzzy');
        final fg = CategoryIcons.foregroundColorFor('xyzzy');
        expect(bg, AppColors.cream);
        expect(fg, AppColors.woodDark);
        // Nunca transparente: siempre hay ilustración, nunca hueco vacío.
        expect(bg.a, greaterThan(0));
        expect(fg.a, greaterThan(0));
      },
    );

    test('styleFor agrupa icono + fondo + color coherentes', () {
      final style = CategoryIcons.styleFor('pollo');
      expect(style.icon, FoodCategory.carne.icon);
      expect(style.background, AppColors.terracottaBg);
      expect(style.foreground, AppColors.terracotta);
    });
  });

  group('No regresión: la API de emoji existente se conserva', () {
    test('cada categoría mantiene su emoji original', () {
      expect(FoodCategory.verdura.emoji, '🥦');
      expect(FoodCategory.fruta.emoji, '🍎');
      expect(FoodCategory.carne.emoji, '🥩');
      expect(FoodCategory.pescado.emoji, '🐟');
      expect(FoodCategory.lacteos.emoji, '🧀');
      expect(FoodCategory.bebidas.emoji, '🥤');
      expect(FoodCategory.panaderia.emoji, '🥖');
      expect(FoodCategory.limpieza.emoji, '🧽');
      expect(FoodCategory.hogar.emoji, '🏠');
      expect(FoodCategory.otros.emoji, '🛒');
    });

    test('emojiFor sigue funcionando igual que antes', () {
      expect(CategoryIcons.emojiFor('tomate'), '🥦');
      expect(CategoryIcons.emojiFor('pollo'), '🥩');
      expect(CategoryIcons.emojiFor('xyzzy'), '🛒');
    });
  });

  group('FoodPhotoService.cacheKey (clave de caché por hogar)', () {
    test('coincide exactamente con CategoryIcons.normalize', () {
      for (final name in ['Plátano', '  JAMÓN ', 'Leche de Avena', 'Tomate']) {
        expect(FoodPhotoService.cacheKey(name), CategoryIcons.normalize(name));
      }
    });

    test('agrupa variantes con acentos/mayúsculas en la misma clave', () {
      expect(FoodPhotoService.cacheKey('Plátano'), 'platano');
      expect(FoodPhotoService.cacheKey('platano'), 'platano');
      expect(
        FoodPhotoService.cacheKey('Plátano'),
        FoodPhotoService.cacheKey('platano'),
      );
    });

    test('recorta espacios y pasa a minúsculas', () {
      expect(FoodPhotoService.cacheKey('  Jamón '), 'jamon');
    });
  });
}
