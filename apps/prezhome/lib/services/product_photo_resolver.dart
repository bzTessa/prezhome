import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/drawn_icons.dart';
import '../widgets/product_icons.dart';
import 'food_photo_service.dart';
import 'home_country.dart';
import 'product_search_service.dart';

/// Elige la URL de foto a usar en el alta por nombre, respetando la prioridad:
/// catálogo/OFF ([catalog]) manda, luego el banco de fotos recipe-photo
/// ([fallback]) y, en último término, la foto previa del item ([previous]).
/// Las cadenas vacías se tratan como null para no pintar un hueco. Devuelve
/// null solo si no hay ninguna foto por ninguna vía. Función PURA, sin efectos.
String? pickImageUrl({String? catalog, String? fallback, String? previous}) {
  String? clean(String? url) => (url == null || url.isEmpty) ? null : url;
  return clean(catalog) ?? clean(fallback) ?? clean(previous);
}

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

/// Decide qué foto guardar al revisar una ya puesta: [current] es la actual y
/// [resolved] la que acaba de devolver la búsqueda. Devuelve la URL a escribir
/// o null si NO hay que tocar nada. Lógica PURA.
///
/// Regla clave (bug de la foto que desaparece): NUNCA se borra una foto buena
/// escribiendo null. Si la búsqueda no encuentra nada ([resolved] == null) se
/// deja la que había, aunque se sospeche que no es exactamente ese producto:
/// una foto real aunque sea aproximada es mejor que un hueco en blanco, y la
/// persona siempre puede cambiarla a mano. Solo se actualiza cuando hay una
/// foto nueva distinta de la actual.
String? photoUpdateOrNull(String? current, String? resolved) {
  if (resolved == null || resolved.isEmpty) return null;
  if (resolved == (current ?? '')) return null;
  return resolved;
}

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
    // Los dibujos ya no se usan: se cambian por la foto del súper.
    if (DrawnIcons.isDrawn(url)) return false;
    // Lo genérico lleva la foto de frescos del súper: una de OFF sobra.
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
  }) async => (await resolveWithPrice(
    homeId: homeId,
    name: name,
    supermarketKey: supermarketKey,
  )).url;

  /// Igual que [photoFor] pero devuelve también el precio real del catálogo
  /// del producto más probable (el mismo que enseña el buscador manual como
  /// "… € aprox."). El precio solo sale de un producto de catálogo
  /// (store != null); para lo genérico y para Open Food Facts es null. Así el
  /// alta por nombre puede poner la foto oficial Y recordar el precio real.
  Future<({String? url, double? price})> resolveWithPrice({
    required String homeId,
    required String name,
    String? supermarketKey,
  }) async {
    final key = FoodPhotoService.cacheKey(name);
    if (key.isEmpty) return (url: null, price: null);
    try {
      final cached = await _client
          .from('food_photo_cache')
          .select('url,manual')
          .eq('home_id', homeId)
          .eq('name_normalized', key)
          .maybeSingle();
      final url = cached?['url']?.toString() ?? '';
      // La elegida a mano manda siempre, hasta que la persona la cambie.
      if (cached?['manual'] == true &&
          url.isNotEmpty &&
          !DrawnIcons.isDrawn(url)) {
        return (url: url, price: null);
      }
      if (url.isNotEmpty &&
          !isStockPhoto(url) &&
          await photoMatches(name, url) != false) {
        return (url: url, price: null);
      }
    } catch (_) {}
    // Lo genérico (cebolla, leche...) lleva la foto de la sección de frescos
    // del súper; si no la hay, se busca en el catálogo como lo demás.
    final generic = ProductIcons.isGeneric(name);
    if (generic) {
      final store = catalogStores.contains(supermarketKey)
          ? supermarketKey!
          : catalogForCountry[HomeCountry.current.value.code];
      final url = store == null ? null : await _search.freshPhoto(name, store);
      if (url != null) {
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: url);
        // Lo genérico no lleva precio de producto concreto.
        return (url: url, price: null);
      }
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
        // Foto compartida de OFF: sin precio de catálogo.
        return (url: url, price: null);
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
    var found = confidentProductPhoto(name, result.products);
    // Un envase de OFF no sirve para lo genérico.
    if (generic && found != null && isSharablePhoto(found)) found = null;
    // Precio real: solo del producto de catálogo más probable (store != null),
    // el mismo que enseña el buscador manual. OFF no trae precio.
    double? price;
    if (!generic) {
      final best = bestCatalogMatch(name, result.products);
      if (best != null && best.store != null) price = best.price;
    }
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
    return (url: found, price: price);
  }
}
