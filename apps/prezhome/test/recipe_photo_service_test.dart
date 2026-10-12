import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/recipe_photo_service.dart';

void main() {
  group('RecipePhotoService.requestBody', () {
    test('solo el título cuando no hay más datos', () {
      expect(RecipePhotoService.requestBody(title: '  Lentejas  '), {
        'query': 'Lentejas',
      });
    });

    test('incluye el nombre en inglés si la IA lo dio', () {
      final body = RecipePhotoService.requestBody(
        title: 'Lentejas estofadas con chorizo',
        titleEn: ' spanish lentil stew ',
      );
      expect(body['query_en'], 'spanish lentil stew');
    });

    test('omite el inglés vacío', () {
      final body = RecipePhotoService.requestBody(
        title: 'Tortilla',
        titleEn: '  ',
      );
      expect(body.containsKey('query_en'), isFalse);
    });

    test('manda las fotos ya vistas sin repetir ni vacías', () {
      final body = RecipePhotoService.requestBody(
        title: 'Tortilla',
        exclude: ['https://a', '', 'https://a', 'https://b'],
      );
      expect(body['exclude'], ['https://a', 'https://b']);
    });
  });
}
