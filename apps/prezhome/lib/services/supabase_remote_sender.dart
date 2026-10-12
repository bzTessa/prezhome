/// Implementación FINA de [RemoteSender] respaldada por Supabase.
///
/// Es la ÚNICA pieza de la capa offline-first que importa `supabase_flutter`:
/// toda la lógica (caché, cola, merge, drenado, aislamiento por hogar) vive en
/// `OfflineRepository` y en el núcleo puro. Aquí solo traducimos las
/// operaciones de sincronización a llamadas `insert`/`update`/`delete`/`select`
/// filtradas por el hogar actual.
///
/// El `home_id` se resuelve con el patrón de las pantallas: `currentUser` +
/// `profiles.home_id`. Al ser una capa de red, cualquier fallo (sin cobertura,
/// error del servidor) se propaga como excepción para que `OfflineRepository`
/// lo interprete como "offline" y detenga el drenado sin perder operaciones.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_repository.dart';

/// [RemoteSender] que habla con Supabase, aislando home_id por perfil.
class SupabaseRemoteSender implements RemoteSender {
  final SupabaseClient _client;

  SupabaseRemoteSender({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Resuelve el home_id del usuario autenticado leyendo su perfil, igual que
  /// hacen las pantallas de compra/despensa.
  Future<String> _homeId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No hay usuario autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .single();
    final homeId = profile['home_id'] as String?;
    if (homeId == null) throw 'El usuario no esta asignado a ningun hogar.';
    return homeId;
  }

  /// Garantiza que el payload lleve el `home_id` del hogar actual (la RLS lo
  /// exige y las filas cacheadas pueden no traerlo si vienen de un insert
  /// optimista mínimo).
  Future<Map<String, dynamic>> _withHomeId(Map<String, dynamic> payload) async {
    if (payload['home_id'] != null) return payload;
    final homeId = await _homeId();
    return {...payload, 'home_id': homeId};
  }

  @override
  Future<void> sendInsert(String table, Map<String, dynamic> payload) async {
    final body = await _withHomeId(payload);
    // Quitamos campos que pone la base de datos para no chocar con defaults.
    final insertable = Map<String, dynamic>.from(body)
      ..remove('id')
      ..remove('created_at');
    await _client.from(table).insert(insertable);
  }

  @override
  Future<void> sendUpdate(
    String table,
    Map<String, dynamic> payload,
    String id,
  ) async {
    final body = Map<String, dynamic>.from(payload)
      ..remove('id')
      ..remove('created_at');
    await _client.from(table).update(body).eq('id', id);
  }

  @override
  Future<void> sendDelete(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table) async {
    final homeId = await _homeId();
    final rows = await _client.from(table).select().eq('home_id', homeId);
    return (rows as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }
}
