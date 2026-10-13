import 'package:supabase_flutter/supabase_flutter.dart';

import 'food_photo_service.dart';
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

/// Foto de producto para la compra: la del envase en Open Food Facts (del
/// súper principal si lo hay). Lo encontrado se guarda por hogar y se
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
      final url = cached?['url']?.toString();
      if (url != null && url.isNotEmpty && !isStockPhoto(url)) return url;
    } catch (_) {}

    // Otro hogar ya encontró este producto: se reutiliza sin buscar.
    try {
      final shared = await _client
          .from('product_photo_shared')
          .select('url')
          .eq('name_normalized', key)
          .maybeSingle();
      final url = shared?['url']?.toString();
      if (url != null && url.isNotEmpty) {
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: url);
        return url;
      }
    } catch (_) {}

    ProductSearchResult result;
    var tries = 0;
    do {
      result = await _search.search(
        name,
        supermarketKey: supermarketKey,
        background: true,
      );
      if (!result.throttled) break;
      await Future<void>.delayed(_throttleWait);
    } while (++tries < 10);

    String? found;
    for (final p in result.products) {
      if ((p.imageUrl ?? '').isNotEmpty) {
        found = p.imageUrl;
        break;
      }
    }
    if (found != null) {
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: name, url: found);
      if (isSharablePhoto(found)) {
        try {
          await _client.from('product_photo_shared').upsert({
            'name_normalized': key,
            'url': found,
          }, ignoreDuplicates: true);
        } catch (_) {}
      }
    }
    return found;
  }
}
