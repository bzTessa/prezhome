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

  test('las fotos de OFF puestas con la regla antigua no se reutilizan', () {
    const off = 'https://images.openfoodfacts.org/images/products/1/front.jpg';
    expect(isTrustedCachedPhoto(off, DateTime.utc(2026, 10, 1)), isFalse);
    expect(isTrustedCachedPhoto(off, null), isFalse);
    expect(isTrustedCachedPhoto(off, DateTime.utc(2026, 10, 20)), isTrue);
    expect(
      isTrustedCachedPhoto('https://abc.supabase.co/mia.jpg', null),
      isTrue,
    );
    expect(sharedPhotoKey('patata'), 'v2|patata');
  });
}
