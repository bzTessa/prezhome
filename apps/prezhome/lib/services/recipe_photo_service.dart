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
  /// la IA (mejora mucho el acierto en los bancos de imágenes). [exclude] son
  /// las fotos ya vistas, para que "Otra foto" traiga una distinta.
  @visibleForTesting
  static Map<String, dynamic> requestBody({
    required String title,
    String? titleEn,
    Iterable<String> exclude = const [],
  }) {
    final en = titleEn?.trim() ?? '';
    final seen = exclude.where((u) => u.trim().isNotEmpty).toSet().toList();
    return {
      'query': title.trim(),
      if (en.isNotEmpty) 'query_en': en,
      if (seen.isNotEmpty) 'exclude': seen,
    };
  }

  /// URL de una foto para [title], o null si no hay ninguna (o falla la red).
  Future<String?> find({
    required String title,
    String? titleEn,
    Iterable<String> exclude = const [],
  }) async {
    if (title.trim().isEmpty) return null;
    try {
      final res = await _client.functions.invoke(
        _function,
        body: requestBody(title: title, titleEn: titleEn, exclude: exclude),
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
}
