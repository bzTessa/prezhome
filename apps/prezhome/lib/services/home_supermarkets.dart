import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/pantry_ideas.dart';

/// Supermercados del hogar (`homes.supermarkets`). El PRIMERO de la lista es
/// el súper principal: el que usan la IA al generar recetas, "Descubrir" y
/// la lista de la compra.
class HomeSupermarkets {
  HomeSupermarkets(this._client);

  final SupabaseClient _client;

  /// Claves de los súper del hogar del usuario actual (vacío si no hay o si
  /// falla). La primera es la principal.
  Future<({String? homeId, List<String> keys})> load() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return (homeId: null, keys: const <String>[]);
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return (homeId: null, keys: const <String>[]);
      final home = await _client
          .from('homes')
          .select('supermarkets')
          .eq('id', homeId)
          .maybeSingle();
      final raw = home?['supermarkets'];
      final keys = raw is List
          ? raw.map((e) => e.toString()).where((k) => k.isNotEmpty).toList()
          : <String>[];
      return (homeId: homeId, keys: keys);
    } catch (_) {
      return (homeId: null, keys: const <String>[]);
    }
  }

  /// Marca [key] como súper principal (lo pone el primero). Devuelve la lista
  /// resultante.
  Future<List<String>> setPrimary(
    String homeId,
    List<String> current,
    String key,
  ) async {
    final next = withPrimarySupermarket(current, key);
    await _client.from('homes').update({'supermarkets': next}).eq('id', homeId);
    return next;
  }
}
