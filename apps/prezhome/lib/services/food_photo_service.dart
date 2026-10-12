import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/food_category_icon.dart';
import 'food_facts_service.dart';

/// Resuelve y cachea la FOTO REAL de un alimento a partir de su nombre.
///
/// El combo visual de la despensa y la lista de la compra es: foto real cuando
/// hay buen match, e ilustración cozy de categoría como respaldo. Este servicio
/// cubre la mitad de "foto real":
///
///   1. Normaliza el nombre con [CategoryIcons.normalize] (minúsculas, sin
///      acentos) para usarlo como clave de caché por hogar. Así "Plátano" y
///      "platano" comparten la misma foto.
///   2. Consulta la caché compartida por hogar `public.food_photo_cache` por
///      (home_id, name_normalized):
///        - Si hay fila con url -> la devuelve ( no vuelve a buscar).
///        - Si hay fila con url NULL -> devuelve null y NO re-busca. Esto
///          respeta la cuota de la cuenta demo de Unsplash (~50 búsquedas/hora):
///          una vez que sabemos que no hay foto (o no hay clave), no insistimos.
///        - Si no hay fila -> llama a la edge function `recipe-photo`
///          REUTILIZADA (query = nombre del alimento), lee `data['url']`
///          (puede ser null), hace UPSERT en la caché y devuelve la url (o null).
///   3. Degrada con elegancia: CUALQUIER excepción (sin clave de Unsplash, red,
///      RLS, respuesta inesperada) se traga y devuelve null. NUNCA lanza hacia
///      la UI, de modo que el guardado o el pintado nunca se rompen.
///
/// Nota sobre la clave de Unsplash: SIN el secreto `UNSPLASH_ACCESS_KEY` la
/// edge function devuelve `{ url: null }`, así que este servicio devuelve null
/// y la UI muestra la ilustración cozy. En cuanto la clave esté configurada,
/// las NUEVAS búsquedas devolverán foto y se cachearán; las filas con url NULL
/// ya cacheadas se pueden refrescar borrándolas (no es objetivo de esta capa).
class FoodPhotoService {
  FoodPhotoService(this._client);

  final SupabaseClient _client;

  static const String _cacheTable = 'food_photo_cache';
  static const String _photoFunction = 'recipe-photo';

  /// Normaliza el nombre a la clave de caché por hogar. Reutiliza EXACTAMENTE
  /// [CategoryIcons.normalize] para que la agrupación coincida con la
  /// categorización visual.
  static String cacheKey(String name) => CategoryIcons.normalize(name);

  /// Memoriza una foto (p. ej. elegida por el usuario de su galería) para
  /// [name] en el hogar [homeId], de modo que se reutilice en futuras
  /// búsquedas (lista de la compra y despensa). Best-effort: nunca lanza.
  Future<void> rememberPhoto({
    required String homeId,
    required String name,
    required String url,
  }) async {
    final key = cacheKey(name);
    if (key.isEmpty || homeId.isEmpty || url.isEmpty) return;
    try {
      await _client.from(_cacheTable).upsert({
        'home_id': homeId,
        'name_normalized': key,
        'url': url,
        'fetched_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'home_id,name_normalized');
    } catch (_) {
      // Si falla el cacheo, no pasa nada: la foto ya está en el item.
    }
  }

  /// Resuelve la URL de foto para [name] en el hogar [homeId]. Devuelve la URL
  /// si hay foto, o null si no la hay (o no se pudo resolver). Nunca lanza.
  Future<String?> resolvePhotoUrl({
    required String homeId,
    required String name,
    String mode = 'ingredient',
  }) async {
    final key = cacheKey(name);
    if (key.isEmpty || homeId.isEmpty) return null;

    try {
      // 1. Mirar la caché por hogar.
      final cached = await _client
          .from(_cacheTable)
          .select('url')
          .eq('home_id', homeId)
          .eq('name_normalized', key)
          .maybeSingle();

      if (cached != null) {
        // Hay fila: respetamos el resultado previo (incluida url NULL) para no
        // re-buscar y gastar cuota de Unsplash.
        final url = cached['url']?.toString();
        return (url != null && url.isNotEmpty) ? url : null;
      }

      // 2. No hay fila: buscar foto reutilizando la edge function recipe-photo.
      String? resolved;
      try {
        final res = await _client.functions.invoke(
          _photoFunction,
          body: {'query': name, 'mode': mode},
        );
        final data = res.data;
        if (data is Map) {
          final url = data['url']?.toString();
          if (url != null && url.isNotEmpty) resolved = url;
        }
      } catch (_) {
        // Fallo de la función (sin clave, red...): tratamos como "sin foto".
        resolved = null;
      }

      // 3. Guardar el resultado en la caché (url o null) para no repetir la
      //    búsqueda. El UPSERT respeta la PK (home_id, name_normalized).
      try {
        await _client.from(_cacheTable).upsert({
          'home_id': homeId,
          'name_normalized': key,
          'url': resolved,
          'fetched_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'home_id,name_normalized');
      } catch (_) {
        // Si el guardado de caché falla (RLS, red), seguimos: devolvemos la
        // foto resuelta igualmente; solo perdemos el cacheo.
      }

      return resolved;
    } catch (_) {
      // Cualquier otra excepción (red, RLS en la lectura): sin foto.
      return null;
    }
  }

  /// Resuelve la FOTO REAL DE PRODUCTO para [name] priorizando Open Food Facts
  /// (foto del producto empaquetado, p. ej. el bote de garbanzos tal cual se
  /// vende) antes que el banco de imágenes genérico. Flujo:
  ///   1. Caché por hogar (igual que [resolvePhotoUrl]): si hay fila, se
  ///      respeta (incluida url NULL) para no re-buscar.
  ///   2. Si no hay fila: consulta food-facts (OFF) por nombre y usa su
  ///      `imageUrl` si lo trae.
  ///   3. Si OFF no da foto: cae a la edge function recipe-photo (banco de
  ///      imágenes), igual que [resolvePhotoUrl].
  ///   4. Cachea el resultado (url o null) para no repetir la búsqueda.
  /// Nunca lanza; ante cualquier fallo devuelve null y la UI muestra la
  /// ilustración cozy. Pensado para la lista de la compra y la despensa.
  Future<String?> resolveProductPhotoUrl({
    required String homeId,
    required String name,
    String mode = 'ingredient',
  }) async {
    final key = cacheKey(name);
    if (key.isEmpty || homeId.isEmpty) return null;

    try {
      // 1. Caché por hogar.
      final cached = await _client
          .from(_cacheTable)
          .select('url')
          .eq('home_id', homeId)
          .eq('name_normalized', key)
          .maybeSingle();
      if (cached != null) {
        final url = cached['url']?.toString();
        return (url != null && url.isNotEmpty) ? url : null;
      }

      String? resolved;

      // 2. Foto real de producto vía Open Food Facts (food-facts).
      try {
        final facts = await FoodFactsService(_client).lookup(name);
        final offUrl = facts.imageUrl;
        if (offUrl != null && offUrl.isNotEmpty) resolved = offUrl;
      } catch (_) {
        // OFF caído o sin foto: seguimos al banco de imágenes.
      }

      // 3. Respaldo al banco de imágenes (recipe-photo) si OFF no dio foto.
      if (resolved == null) {
        try {
          final res = await _client.functions.invoke(
            _photoFunction,
            body: {'query': name, 'mode': mode},
          );
          final data = res.data;
          if (data is Map) {
            final url = data['url']?.toString();
            if (url != null && url.isNotEmpty) resolved = url;
          }
        } catch (_) {
          resolved = null;
        }
      }

      // 4. Cachear el resultado (url o null) para no repetir la búsqueda.
      try {
        await _client.from(_cacheTable).upsert({
          'home_id': homeId,
          'name_normalized': key,
          'url': resolved,
          'fetched_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'home_id,name_normalized');
      } catch (_) {
        // Si el guardado de caché falla, devolvemos la foto igualmente.
      }

      return resolved;
    } catch (_) {
      return null;
    }
  }
}
