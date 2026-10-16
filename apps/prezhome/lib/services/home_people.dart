import 'package:supabase_flutter/supabase_flutter.dart';

/// Personas de casa sin cuenta (tabla home_people): se pueden asignar a
/// tareas, marcar como quien la hizo y sumar puntos, como un miembro más.
class HomePeople {
  HomePeople(this._client);

  final SupabaseClient _client;

  /// id -> nombre. Vacío si falla, para que Tareas y Hogar funcionen igual.
  Future<Map<String, String>> load(String homeId) async {
    try {
      final rows = await _client
          .from('home_people')
          .select('id, name')
          .eq('home_id', homeId)
          .order('created_at');
      return {
        for (final r in rows as List) r['id'] as String: r['name'] as String,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> add(String homeId, String name) => _client
      .from('home_people')
      .insert({'home_id': homeId, 'name': name.trim()});

  /// Al borrarla, la base de datos le quita sus tareas y sus puntos.
  Future<void> remove(String id) =>
      _client.from('home_people').delete().eq('id', id);
}
