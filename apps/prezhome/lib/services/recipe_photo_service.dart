import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Busca la foto automática de una receta con la edge function `recipe-photo`.
///
/// Centraliza la llamada que antes estaba repetida en el alta de recetas, en
/// "Descubrir" y en el detalle. Degrada siempre con elegancia: ante cualquier
/// fallo devuelve null y la app pinta la ilustración del plato.
class RecipePhotoService {
  RecipePhotoService(this._client);

  final SupabaseClient _client;

  static const String _function = 'recipe-photo';

  /// Cuerpo de la petición. [titleEn] es el nombre del plato en inglés que da
  /// la IA (mejora mucho el acierto en los bancos de imágenes). [description]
  /// e [ingredients] ayudan a la IA del servidor a saber qué plato es (y a no
  /// buscar marcas como "Happy Hippo" tal cual). [exclude] son las fotos ya
  /// vistas, para que "Otra foto" traiga una distinta. [verifyUrl] no busca:
  /// pregunta si esa foto es del plato.
  @visibleForTesting
  static Map<String, dynamic> requestBody({
    required String title,
    String? titleEn,
    String? description,
    Iterable<String> ingredients = const [],
    Iterable<String> exclude = const [],
    String? verifyUrl,
  }) {
    final en = titleEn?.trim() ?? '';
    final desc = description?.trim() ?? '';
    final ings = ingredients
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty)
        .toSet()
        .take(15)
        .toList();
    final seen = exclude.where((u) => u.trim().isNotEmpty).toSet().toList();
    final verify = verifyUrl?.trim() ?? '';
    return {
      'query': title.trim(),
      if (en.isNotEmpty) 'query_en': en,
      if (desc.isNotEmpty) 'description': desc,
      if (ings.isNotEmpty) 'ingredients': ings,
      if (seen.isNotEmpty) 'exclude': seen,
      if (verify.isNotEmpty) 'verify_url': verify,
    };
  }

  /// URL de una foto para [title], o null si no hay ninguna (o falla la red).
  Future<String?> find({
    required String title,
    String? titleEn,
    String? description,
    Iterable<String> ingredients = const [],
    Iterable<String> exclude = const [],
  }) async {
    if (title.trim().isEmpty) return null;
    try {
      final res = await _client.functions.invoke(
        _function,
        body: requestBody(
          title: title,
          titleEn: titleEn,
          description: description,
          ingredients: ingredients,
          exclude: exclude,
        ),
      );
      final data = res.data;
      if (data is Map) {
        final url = data['url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (e) {
      debugPrint('RecipePhotoService error: $e');
    }
    return null;
  }

  /// ¿La foto [url] es de verdad este plato? true / false, o null si no se ha
  /// podido saber (sin red, sin IA en el servidor, foto de otro sitio).
  Future<bool?> verify({
    required String url,
    required String title,
    String? description,
    Iterable<String> ingredients = const [],
  }) async {
    if (title.trim().isEmpty || url.trim().isEmpty) return null;
    try {
      final res = await _client.functions.invoke(
        _function,
        body: requestBody(
          title: title,
          description: description,
          ingredients: ingredients,
          verifyUrl: url,
        ),
      );
      final data = res.data;
      if (data is Map && data['ok'] is bool) return data['ok'] as bool;
    } catch (e) {
      debugPrint('RecipePhotoService verify error: $e');
    }
    return null;
  }
}
