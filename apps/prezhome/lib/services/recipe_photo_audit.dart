import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'file_local_store.dart';
import 'recipe_photo_service.dart';

/// Revisa las fotos automáticas que ya tienen las recetas del hogar.
///
/// Antes de que la IA mirase las fotos se guardaron algunas equivocadas (un
/// hipopótamo para "Cheesecake Happy Hippo", una ensalada para un plato de
/// pollo con arroz). En segundo plano, unas pocas recetas cada vez, pregunta
/// si la foto es del plato; si no lo es, busca otra (ya revisada) o la quita
/// para que se vea el dibujo. Solo toca fotos de bancos (Unsplash/Pexels): las
/// subidas a mano o las de la receta importada no se tocan.
///
/// Cada foto revisada se recuerda en el dispositivo para no volver a mirarla.
class RecipePhotoAudit {
  static final _store = FileLocalStore(folderName: 'settings');
  static Future<int>? _running;

  /// Recetas que mira como mucho por vez (cada una es una consulta a la IA).
  static const int perRun = 10;

  /// Revisa las pendientes. Devuelve cuántas fotos cambió. No lanza.
  static Future<int> run(SupabaseClient client) =>
      _running ??= _run(client).whenComplete(() => _running = null);

  /// ¿Es una foto automática de un banco de imágenes?
  @visibleForTesting
  static bool isStockPhoto(String? url) {
    final host = Uri.tryParse(url ?? '')?.host ?? '';
    return host == 'images.unsplash.com' || host == 'images.pexels.com';
  }

  static Future<int> _run(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final key = 'recipe_photo_checked_v1:${user.id}';
    try {
      final me = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = me?['home_id'] as String?;
      if (homeId == null) return 0;

      final checked = <String>{
        ...((jsonDecode(await _store.read(key) ?? '[]') as List).map(
          (e) => e.toString(),
        )),
      };
      final rows = await client
          .from('recipes')
          .select(
            'id, title, description, image_url, image_path, '
            'recipe_ingredients(name)',
          )
          .eq('home_id', homeId)
          .not('image_url', 'is', null)
          .order('created_at', ascending: false);

      final pending = [
        for (final r in rows as List)
          if ((r['image_path'] ?? '').toString().isEmpty &&
              isStockPhoto(r['image_url']?.toString()) &&
              !checked.contains('${r['id']}|${r['image_url']}'))
            r,
      ].take(perRun);

      final photos = RecipePhotoService(client);
      var changed = 0;
      for (final r in pending) {
        final url = r['image_url'].toString();
        final title = (r['title'] ?? '').toString();
        final description = r['description']?.toString();
        final ingredients = [
          for (final i in (r['recipe_ingredients'] as List? ?? const []))
            (i['name'] ?? '').toString(),
        ];
        final ok = await photos.verify(
          url: url,
          title: title,
          description: description,
          ingredients: ingredients,
        );
        // Sin respuesta (sin red, sin IA): se reintenta otro día.
        if (ok == null) continue;
        checked.add('${r['id']}|$url');
        if (!ok) {
          final better = await photos.find(
            title: title,
            description: description,
            ingredients: ingredients,
            exclude: [url],
          );
          await client
              .from('recipes')
              .update({'image_url': better})
              .eq('id', r['id']);
          // La nueva ya la ha revisado la IA al buscarla.
          if (better != null) checked.add('${r['id']}|$better');
          changed++;
        }
        await _store.write(key, jsonEncode(checked.toList()));
      }
      return changed;
    } catch (e) {
      debugPrint('RecipePhotoAudit error: $e');
      return 0;
    }
  }
}
