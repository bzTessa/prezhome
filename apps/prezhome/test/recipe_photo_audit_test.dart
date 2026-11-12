import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/recipe_photo_audit.dart';

void main() {
  test('solo revisa fotos de los bancos de imágenes', () {
    expect(
      RecipePhotoAudit.isStockPhoto(
        'https://images.unsplash.com/photo-1?w=1080',
      ),
      isTrue,
    );
    expect(
      RecipePhotoAudit.isStockPhoto(
        'https://images.pexels.com/photos/1/a.jpeg',
      ),
      isTrue,
    );
    expect(
      RecipePhotoAudit.isStockPhoto('https://i.ytimg.com/vi/x/hq.jpg'),
      isFalse,
    );
    expect(RecipePhotoAudit.isStockPhoto(null), isFalse);
  });
}
