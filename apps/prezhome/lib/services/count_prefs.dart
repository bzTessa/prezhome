import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/food_category_icon.dart';

/// Cómo cuenta el hogar un producto en la compra.
enum CountMode { pack, piece, weight }

/// Lo que cada hogar eligió en una fila ("Contar en…"), por nombre
/// normalizado. La app lo respeta desde entonces.
class CountPrefs {
  CountPrefs(this._client);

  final SupabaseClient _client;

  static String key(String name) => CategoryIcons.normalize(name.trim());

  Future<Map<String, CountMode>> load(String homeId) async {
    try {
      final rows = await _client
          .from('product_count_prefs')
          .select('name_normalized, mode')
          .eq('home_id', homeId);
      return {
        for (final r in rows as List)
          r['name_normalized'] as String: CountMode.values.byName(
            r['mode'] as String,
          ),
      };
    } catch (_) {
      // Sin preferencias se usa la regla automática.
      return const {};
    }
  }

  Future<void> save(String homeId, String name, CountMode mode) =>
      _client.from('product_count_prefs').upsert({
        'home_id': homeId,
        'name_normalized': key(name),
        'mode': mode.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
}
