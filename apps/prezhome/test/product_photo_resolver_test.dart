import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/food_photo_service.dart';
import 'package:prezhome/services/product_photo_resolver.dart';
import 'package:prezhome/services/product_search_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Banco de fotos recipe-photo falso: devuelve [_url] y anota si lo llamaron,
/// sin tocar Supabase ni la red.
class _FakePhotos extends FoodPhotoService {
  _FakePhotos(this._url) : super(SupabaseClient('http://x', 'k'));

  final String? _url;
  int calls = 0;

  @override
  Future<String?> resolvePhotoUrl({
    required String homeId,
    required String name,
    String mode = 'ingredient',
  }) async {
    calls++;
    return _url;
  }
}

/// Resolver con la vía de catálogo/OFF simulada ([_catalogUrl] + [_price]),
/// para ejercer el CABLEADO real de resolveAddByNamePhoto (respaldo al banco y
/// pickImageUrl) sin montar Supabase ni red.
class _FakeResolver extends ProductPhotoResolver {
  _FakeResolver({
    required String? catalogUrl,
    required double? price,
    required FoodPhotoService photos,
  }) : _catalogUrl = catalogUrl,
       _price = price,
       super(SupabaseClient('http://x', 'k'), photos: photos);

  final String? _catalogUrl;
  final double? _price;

  @override
  Future<({String? url, double? price})> resolveWithPrice({
    required String homeId,
    required String name,
    String? supermarketKey,
  }) async => (url: _catalogUrl, price: _price);
}

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

  group('resolveAddByNamePhoto (cableado del alta por nombre)', () {
    test(
      'con foto de catálogo gana el catálogo y NO se llama al banco',
      () async {
        final photos = _FakePhotos('https://banco/queso-azul.jpg');
        final resolver = _FakeResolver(
          catalogUrl: 'https://prod-bonarea/queso-azul.jpg',
          price: 3.45,
          photos: photos,
        );
        final out = await resolver.resolveAddByNamePhoto(
          homeId: 'h1',
          name: 'Queso azul',
          previous: 'https://previa/x.jpg',
        );
        expect(out.imageUrl, 'https://prod-bonarea/queso-azul.jpg');
        expect(out.price, 3.45);
        // El catálogo trajo foto: el banco no se llega a consultar.
        expect(photos.calls, 0);
      },
    );

    test(
      'sin foto de catálogo, gana el banco (regresión del PR #259)',
      () async {
        // Este es el bug real: "Queso azul" sin foto de catálogo debía caer al
        // banco recipe-photo, no quedarse con la ilustración cozy. Si alguien
        // quitara el respaldo o el pickImageUrl del cableado, este test falla.
        final photos = _FakePhotos('https://banco/queso-azul.jpg');
        final resolver = _FakeResolver(
          catalogUrl: null,
          price: null,
          photos: photos,
        );
        final out = await resolver.resolveAddByNamePhoto(
          homeId: 'h1',
          name: 'Queso azul',
          previous: null,
        );
        expect(out.imageUrl, 'https://banco/queso-azul.jpg');
        // Sin catálogo sí se consulta el banco (una sola vez).
        expect(photos.calls, 1);
      },
    );

    test(
      'sin catálogo ni banco, se conserva la foto previa del item',
      () async {
        final photos = _FakePhotos(null);
        final resolver = _FakeResolver(
          catalogUrl: null,
          price: null,
          photos: photos,
        );
        final out = await resolver.resolveAddByNamePhoto(
          homeId: 'h1',
          name: 'Queso azul',
          previous: 'https://previa/queso.jpg',
        );
        expect(out.imageUrl, 'https://previa/queso.jpg');
        expect(photos.calls, 1);
      },
    );
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
