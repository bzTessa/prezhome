import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/food_category_icon.dart';

/// Cómo cuenta el hogar un producto en la compra.
enum CountMode { pack, piece, weight }

/// Peso o volumen de un envase: 570 g, 1000 ml.
typedef PackMeasure = ({double size, String unit});

/// Lo que cada hogar eligió en una fila ("Contar en…"), por nombre
/// normalizado. La app lo respeta desde entonces.
class CountPrefs {
  CountPrefs(this._client);

  final SupabaseClient _client;

  static String key(String name) => CategoryIcons.normalize(name.trim());

  /// Lo que trae cada envase según el hogar ("Garbanzos: 570 g"), por nombre
  /// normalizado. Se rellena con [load] y manda sobre el catálogo del súper.
  static Map<String, PackMeasure> customPacks = const {};

  /// Envase propio de [name], o null.
  static PackMeasure? customPackOf(String name) => customPacks[key(name)];

  Future<Map<String, CountMode>> load(String homeId) async {
    try {
      final rows = await _client
          .from('product_count_prefs')
          .select('name_normalized, mode, pack_size, pack_unit')
          .eq('home_id', homeId);
      final packs = <String, PackMeasure>{};
      final modes = <String, CountMode>{};
      for (final r in rows as List) {
        final k = r['name_normalized'] as String;
        modes[k] = CountMode.values.byName(r['mode'] as String);
        final size = (r['pack_size'] as num?)?.toDouble();
        final unit = r['pack_unit'] as String?;
        if (size != null && size > 0 && unit != null) {
          packs[k] = (size: size, unit: unit);
        }
      }
      customPacks = packs;
      return modes;
    } catch (_) {
      // Sin preferencias se usa la regla automática.
      return const {};
    }
  }

  /// Guarda lo que trae cada envase de [name] y lo cuenta en envases desde
  /// ahora.
  Future<void> savePack(String homeId, String name, PackMeasure pack) async {
    await _client.from('product_count_prefs').upsert({
      'home_id': homeId,
      'name_normalized': key(name),
      'mode': CountMode.pack.name,
      'pack_size': pack.size,
      'pack_unit': pack.unit,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    customPacks = {...customPacks, key(name): pack};
  }

  Future<void> save(String homeId, String name, CountMode mode) =>
      _client.from('product_count_prefs').upsert({
        'home_id': homeId,
        'name_normalized': key(name),
        'mode': mode.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
}
