import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/product_photo_resolver.dart';

void main() {
  test('solo se comparten fotos de Open Food Facts', () {
    expect(
      isSharablePhoto(
        'https://images.openfoodfacts.org/images/products/843/front.jpg',
      ),
      isTrue,
    );
    expect(
      isSharablePhoto(
        'https://abc.supabase.co/storage/v1/object/public/fotos/mia.jpg',
      ),
      isFalse,
    );
    expect(isSharablePhoto('https://images.unsplash.com/x.jpg'), isFalse);
  });
}
