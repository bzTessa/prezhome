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

  group('pickImageUrl (cadena de respaldo del alta por nombre)', () {
    test('el catálogo/OFF manda sobre todo', () {
      expect(
        pickImageUrl(
          catalog: 'https://prod-mercadona.imgix.net/leche.jpg',
          fallback: 'https://banco/leche.jpg',
          previous: 'https://previa/leche.jpg',
        ),
        'https://prod-mercadona.imgix.net/leche.jpg',
      );
    });

    test('sin catálogo, gana el banco de fotos (regresión del PR #259)', () {
      // Sin la cadena de respaldo este caso se perdía: se quedaba con la
      // previa (o null) y pintaba la ilustración cozy en vez de la foto.
      expect(
        pickImageUrl(
          catalog: null,
          fallback: 'https://banco/queso-azul.jpg',
          previous: null,
        ),
        'https://banco/queso-azul.jpg',
      );
      // La cadena vacía cuenta como "sin foto" y no gana.
      expect(
        pickImageUrl(catalog: '', fallback: 'https://banco/x.jpg'),
        'https://banco/x.jpg',
      );
    });

    test('sin catálogo ni banco, se conserva la foto previa del item', () {
      expect(
        pickImageUrl(
          catalog: null,
          fallback: null,
          previous: 'https://previa/x.jpg',
        ),
        'https://previa/x.jpg',
      );
      expect(
        pickImageUrl(
          catalog: '',
          fallback: '',
          previous: 'https://previa/x.jpg',
        ),
        'https://previa/x.jpg',
      );
    });

    test('sin ninguna foto, null (ilustración cozy como último recurso)', () {
      expect(pickImageUrl(), isNull);
      expect(pickImageUrl(catalog: '', fallback: '', previous: ''), isNull);
    });
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
