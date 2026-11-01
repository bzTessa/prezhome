import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/product_photo_resolver.dart';
import 'package:prezhome/services/product_search_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  test('saca el código de barras de una foto de OFF', () {
    expect(
      offBarcodeFromUrl(
        'https://images.openfoodfacts.org/images/products/843/000/000/1234/front_es.3.200.jpg',
      ),
      '8430000001234',
    );
    expect(
      offBarcodeFromUrl(
        'https://images.openfoodfacts.net/images/products/12345678/front.jpg',
      ),
      '12345678',
    );
    expect(offBarcodeFromUrl('https://abc.supabase.co/mia.jpg'), isNull);
    expect(sharedPhotoKey('patata'), 'v2|patata');
  });

  test('un dibujo guardado nunca vale: se busca la foto del súper', () async {
    final resolver = ProductPhotoResolver(SupabaseClient('http://x', 'k'));
    expect(
      await resolver.photoMatches(
        'Pimentón',
        'https://x.supabase.co/storage/v1/object/public/recipe-images/icons/pimenton.png',
      ),
      isFalse,
    );
  });
}
