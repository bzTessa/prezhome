import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/product_icons.dart';
import 'food_photo_service.dart';
import 'home_country.dart';
import 'product_search_service.dart';

/// Foto de banco de imágenes (Unsplash, Pexels): en la compra salen
/// demasiado al azar, así que no se usan para productos.
bool isStockPhoto(String? url) {
  if (url == null || url.isEmpty) return false;
  final host = Uri.tryParse(url)?.host ?? '';
  return host.contains('unsplash.com') || host.contains('pexels.com');
}

/// Solo las fotos de Open Food Facts se comparten entre hogares (misma regla
/// que el check de `product_photo_shared`); nunca una foto de la persona.
bool isSharablePhoto(String url) =>
    RegExp(r'^https://images\.openfoodfacts\.(org|net)/').hasMatch(url);

/// Clave en `product_photo_shared` de las fotos elegidas con la regla nueva;
/// las filas antiguas (sin prefijo) se ignoran.
String sharedPhotoKey(String key) => 'v2|$key';

/// Foto de producto para la compra: la del envase en Open Food Facts (del
/// súper principal si lo hay), solo si el producto es claramente lo buscado.
/// Las fotos ya guardadas se comprueban antes de reutilizarlas. Lo encontrado se guarda por hogar y se
/// reutiliza. Si no hay producto, null: se ve la ilustración del alimento.
class ProductPhotoResolver {
  ProductPhotoResolver(
    this._client, {
    ProductSearchService? search,
    Duration throttleWait = const Duration(seconds: 8),
  }) : _search = search ?? ProductSearchService(),
       _throttleWait = throttleWait;

  final SupabaseClient _client;
  final ProductSearchService _search;
  final Duration _throttleWait;

  static final Map<String, bool> _checked = {};

  /// Si la foto guardada [url] es de verdad de [name]: las de la galería
  /// siempre; las de OFF se comprueban leyendo el producto por su código de
  /// barras (no gasta búsquedas). Null si no se pudo comprobar (sin red).
  Future<bool?> photoMatches(String name, String url) async {
    // Lo genérico lleva su foto genérica: una de OFF guardada sobra.
    if (ProductIcons.isGeneric(name) && isSharablePhoto(url)) return false;
    final code = offBarcodeFromUrl(url);
    if (code == null) return !isSharablePhoto(url) && !isStockPhoto(url);
    final memo = '$name|$code';
    final known = _checked[memo];
    if (known != null) return known;
    final product = await _search.productByCode(code);
    if (product == null) return null;
    return _checked[memo] = isProductFor(name, product);
  }

  /// Busca la foto de [name]. Si Open Food Facts pide esperar, espera y
  /// reintenta (pensado para ir en segundo plano). Nunca lanza.
  Future<String?> photoFor({
    required String homeId,
    required String name,
    String? supermarketKey,
  }) async {
    final key = FoodPhotoService.cacheKey(name);
    if (key.isEmpty) return null;
    try {
      final cached = await _client
          .from('food_photo_cache')
          .select('url')
          .eq('home_id', homeId)
          .eq('name_normalized', key)
          .maybeSingle();
      final url = cached?['url']?.toString() ?? '';
      if (url.isNotEmpty &&
          !isStockPhoto(url) &&
          await photoMatches(name, url) != false) {
        return url;
      }
    } catch (_) {}
    // Lo genérico (cebolla, leche...) lleva la foto de la sección de frescos
    // del súper o, si no hay, su foto genérica compartida; nunca un envase.
    if (ProductIcons.isGeneric(name)) {
      final store = catalogStores.contains(supermarketKey)
          ? supermarketKey!
          : catalogForCountry[HomeCountry.current.value.code];
      final url =
          (store == null ? null : await _search.freshPhoto(name, store)) ??
          await genericPhoto(name);
      if (url != null) {
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: url);
      }
      return url;
    }

    // Otro hogar ya encontró este producto: se reutiliza sin buscar.
    try {
      final shared = await _client
          .from('product_photo_shared')
          .select('url')
          .eq('name_normalized', sharedPhotoKey(key))
          .maybeSingle();
      final url = shared?['url']?.toString();
      if (url != null &&
          url.isNotEmpty &&
          await photoMatches(name, url) == true) {
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: url);
        return url;
      }
    } catch (_) {}

    Future<ProductSearchResult> searchIn(String? store) async {
      ProductSearchResult result;
      var tries = 0;
      do {
        result = await _search.search(
          name,
          supermarketKey: store,
          background: true,
        );
        if (!result.throttled) break;
        await Future<void>.delayed(_throttleWait);
      } while (++tries < 10);
      return result;
    }

    final result = await searchIn(supermarketKey);
    final found = confidentProductPhoto(name, result.products);
    if (found != null) {
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: name, url: found);
      if (isSharablePhoto(found)) {
        try {
          await _client.from('product_photo_shared').upsert({
            'name_normalized': sharedPhotoKey(key),
            'url': found,
          }, ignoreDuplicates: true);
        } catch (_) {}
      }
    }
    return found;
  }

  /// Foto genérica realista de [name] (función `product-image`, Nano
  /// Banana), compartida por todos los hogares. Con [again] crea otra
  /// versión, gasta una foto del cupo y lanza si falla (para avisar).
  Future<String?> genericPhoto(String name, {bool again = false}) async {
    final key = ProductIcons.photoKeyFor(name);
    if (key == null) return null;
    try {
      final res = await _client.functions.invoke(
        'product-image',
        body: {'key': key, 'again': again},
      );
      final url = (res.data is Map ? res.data['url'] : null)?.toString();
      return url == null || url.isEmpty ? null : url;
    } catch (_) {
      if (again) rethrow;
      return null;
    }
  }
}
