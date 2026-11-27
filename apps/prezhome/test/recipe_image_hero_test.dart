import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/widgets/recipe_image.dart';

Recipe _recipeWithPhoto() => Recipe(
  id: 'rec-hero-1',
  homeId: 'home-1',
  title: 'Café doble con leche',
  servings: 1,
  mealTypes: ['breakfast'],
  externalImageUrl: 'https://images.pexels.com/photos/1234/cafe.jpg',
);

void main() {
  testWidgets(
    'RecipeImage miniatura usa gaplessPlayback y cacheWidth constante al cambiar ancho',
    (tester) async {
      final recipe = _recipeWithPhoto();
      final widths = <int?>[];

      Future<void> pumpAt(double w) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: w,
                  height: 72,
                  child: RecipeImage(
                    recipe: recipe,
                    width: 72,
                    height: 72,
                    radius: 14,
                  ),
                ),
              ),
            ),
          ),
        );
        final img = tester.widget<Image>(find.byType(Image));
        expect(img.gaplessPlayback, isTrue);
        final provider = img.image;
        expect(provider, isA<ResizeImage>());
        widths.add((provider as ResizeImage).width);
      }

      // Simula varios fotogramas con anchos distintos (como en un vuelo Hero).
      await pumpAt(72);
      await pumpAt(140);
      await pumpAt(260);
      await pumpAt(360);

      expect(widths, everyElement(RecipeImage.thumbCacheWidth));
    },
  );

  testWidgets(
    'RecipeImage detalle usa fullCacheWidth y mantiene thumbCacheWidth como placeholder',
    (tester) async {
      final recipe = _recipeWithPhoto();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeImage(
              recipe: recipe,
              height: 360,
              radius: 0,
              placeholderCacheWidth: RecipeImage.thumbCacheWidth,
            ),
          ),
        ),
      );

      final imgs = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(imgs.length, greaterThanOrEqualTo(1));
      final primary = imgs.first;
      expect(primary.gaplessPlayback, isTrue);
      expect((primary.image as ResizeImage).width, RecipeImage.fullCacheWidth);

      // El placeholder inmediato usa la miniatura ya cacheada.
      expect(
        imgs.any(
          (i) =>
              i.gaplessPlayback &&
              i.image is ResizeImage &&
              (i.image as ResizeImage).width == RecipeImage.thumbCacheWidth,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'RecipeImage con cacheWidth explícito (cuadrícula 2 col) usa gridCacheWidth constante',
    (tester) async {
      final recipe = _recipeWithPhoto();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 160,
              child: RecipeImage(
                recipe: recipe,
                height: double.infinity,
                radius: 0,
                cacheWidth: RecipeImage.gridCacheWidth,
              ),
            ),
          ),
        ),
      );

      final img = tester.widget<Image>(find.byType(Image));
      expect(img.gaplessPlayback, isTrue);
      expect((img.image as ResizeImage).width, RecipeImage.gridCacheWidth);
    },
  );
}
