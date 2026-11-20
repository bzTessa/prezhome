import 'package:supabase_flutter/supabase_flutter.dart';

import 'shelf_life.dart';

/// Recuerda las caducidades que el hogar corrige a mano: si la app propuso 5
/// días para la nata y ella puso 4 meses, la próxima nata sale con 4 meses.
/// Se guarda en días de vida por producto y zona (`product_shelf_life`) y
/// [ShelfLife.estimateDays] lo usa antes que sus tablas.
class ShelfLifeMemory {
  ShelfLifeMemory(this._client);

  final SupabaseClient _client;

  static Future<void>? _loading;

  /// Carga lo aprendido del hogar una vez por sesión. No lanza.
  static Future<void> ensureLoaded(SupabaseClient client) =>
      _loading ??= ShelfLifeMemory(client)._load().catchError((_) {
        _loading = null;
      });

  Future<void> _load() async {
    final homeId = await _homeId();
    if (homeId == null) return;
    final rows = await _client
        .from('product_shelf_life')
        .select('name_normalized, zone, days')
        .eq('home_id', homeId);
    ShelfLife.learned = {
      for (final r in rows as List)
        ShelfLife.learnedKey(
          r['name_normalized'] as String,
          r['zone'] as String,
        ): (r['days'] as num)
            .toInt(),
    };
  }

  Future<String?> _homeId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    return profile?['home_id'] as String?;
  }

  /// Guarda que [name] en [zone] dura [days] días. Best-effort: si falla, solo
  /// se recuerda en esta sesión.
  Future<void> remember({
    required String homeId,
    required String name,
    required String zone,
    required int days,
  }) async {
    if (days < 1 || days > 3650) return;
    final key = ShelfLife.normalizedName(name);
    if (key.isEmpty) return;
    ShelfLife.learned = {
      ...ShelfLife.learned,
      ShelfLife.learnedKey(key, zone): days,
    };
    try {
      await _client.from('product_shelf_life').upsert({
        'home_id': homeId,
        'name_normalized': key,
        'zone': zone,
        'days': days,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }
}

/// Lógica PURA: días de vida que la persona quiso decir al corregir la fecha.
/// En un alta, de hoy a [picked]. Al editar, lo que proponía la app más lo
/// que movió la fecha ([previous] → [picked]), porque el producto puede
/// llevar días en casa. Null si no se puede saber.
int? learnedShelfDays({
  required DateTime picked,
  DateTime? previous,
  int? estimatedDays,
  required DateTime today,
}) {
  DateTime d(DateTime x) => DateTime.utc(x.year, x.month, x.day);
  if (previous == null || estimatedDays == null) {
    final days = d(picked).difference(d(today)).inDays;
    return days >= 1 ? days : null;
  }
  final days = estimatedDays + d(picked).difference(d(previous)).inDays;
  return days >= 1 ? days : null;
}
