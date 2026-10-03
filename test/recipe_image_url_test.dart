import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';

void main() {
  // Base del bucket público recipe-images (ver Recipe._supabaseUrl).
  const bucketBase =
      'https://ubrihtnnkbwcbchvvlno.supabase.co/storage/v1/object/public/recipe-images';
  const pexelsUrl = 'https://images.pexels.com/photos/1234/comida.jpg';

  // Campos mínimos obligatorios para construir un mapa válido para fromMap.
  Map<String, dynamic> baseMap({Object? imagePath, Object? imageUrl}) {
    return {
      'id': 'rec-1',
      'home_id': 'home-1',
      'title': 'Lentejas',
      'servings': 2,
      'image_path': imagePath,
      'image_url': imageUrl,
    };
  }

  group('Recipe.fromMap -> imageUrl (foto automática)', () {
    test('solo image_path -> URL pública del bucket (foto manual)', () {
      final recipe = Recipe.fromMap(baseMap(imagePath: 'home-1/foto.jpg'));

      expect(recipe.imagePath, 'home-1/foto.jpg');
      expect(recipe.externalImageUrl, isNull);
      expect(recipe.imageUrl, '$bucketBase/home-1/foto.jpg');
    });

    test('solo image_url externa -> esa URL externa tal cual', () {
      final recipe = Recipe.fromMap(baseMap(imageUrl: pexelsUrl));

      expect(recipe.imagePath, isNull);
      expect(recipe.externalImageUrl, pexelsUrl);
      expect(recipe.imageUrl, pexelsUrl);
    });

    test(
      'ambos presentes -> prioriza la derivada de image_path (foto manual gana)',
      () {
        final recipe = Recipe.fromMap(
          baseMap(imagePath: 'home-1/manual.png', imageUrl: pexelsUrl),
        );

        // La foto manual (image_path) tiene prioridad sobre la de Pexels.
        expect(recipe.imageUrl, '$bucketBase/home-1/manual.png');
        // Pero conserva ambos valores crudos.
        expect(recipe.externalImageUrl, pexelsUrl);
        expect(recipe.imagePath, 'home-1/manual.png');
      },
    );

    test('sin ninguna de las dos -> imageUrl es null', () {
      final recipe = Recipe.fromMap(baseMap());

      expect(recipe.imagePath, isNull);
      expect(recipe.externalImageUrl, isNull);
      expect(recipe.imageUrl, isNull);
    });

    test('cadenas vacías ("") se tratan como ausentes -> imageUrl es null', () {
      final recipe = Recipe.fromMap(baseMap(imagePath: '', imageUrl: ''));

      expect(recipe.imagePath, isNull);
      expect(recipe.externalImageUrl, isNull);
      expect(recipe.imageUrl, isNull);
    });

    test(
      'image_path vacío pero image_url externa presente -> cae a la externa',
      () {
        final recipe = Recipe.fromMap(
          baseMap(imagePath: '', imageUrl: pexelsUrl),
        );

        expect(recipe.imagePath, isNull);
        expect(recipe.externalImageUrl, pexelsUrl);
        expect(recipe.imageUrl, pexelsUrl);
      },
    );

    test('tolera nulls explícitos en image_path/image_url', () {
      final recipe = Recipe.fromMap({
        'id': 'rec-1',
        'home_id': 'home-1',
        'title': 'Lentejas',
        'servings': 2,
        'image_path': null,
        'image_url': null,
      });

      expect(recipe.imageUrl, isNull);
    });
  });

  group('Recipe.toMap -> image_url', () {
    test('con URL externa real: toMap emite image_url con esa URL', () {
      final recipe = Recipe(
        id: 'rec-1',
        homeId: 'home-1',
        title: 'Lentejas',
        servings: 2,
        externalImageUrl: pexelsUrl,
      );

      final map = recipe.toMap();
      expect(map.containsKey('image_url'), isTrue);
      expect(map['image_url'], pexelsUrl);
    });

    test(
      'sin URL externa: image_url se emite como null (no la derivada del bucket)',
      () {
        final recipe = Recipe(
          id: 'rec-1',
          homeId: 'home-1',
          title: 'Lentejas',
          servings: 2,
          imagePath: 'home-1/foto.jpg',
        );

        final map = recipe.toMap();
        // El getter imageUrl sí resuelve la foto manual...
        expect(recipe.imageUrl, '$bucketBase/home-1/foto.jpg');
        // ...pero toMap NO escribe la URL derivada del bucket en image_url.
        expect(map['image_url'], isNull);
      },
    );

    test('externalImageUrl vacío ("") se persiste como null', () {
      final recipe = Recipe(
        id: 'rec-1',
        homeId: 'home-1',
        title: 'Lentejas',
        servings: 2,
        externalImageUrl: '',
      );

      final map = recipe.toMap();
      expect(map['image_url'], isNull);
    });

    test('round-trip de URL externa: toMap -> fromMap conserva imageUrl', () {
      final original = Recipe(
        id: 'rec-1',
        homeId: 'home-1',
        title: 'Lentejas',
        servings: 2,
        externalImageUrl: pexelsUrl,
      );

      final roundTrip = Recipe.fromMap({'id': 'rec-1', ...original.toMap()});

      expect(roundTrip.externalImageUrl, pexelsUrl);
      expect(roundTrip.imageUrl, pexelsUrl);
    });
  });
}
