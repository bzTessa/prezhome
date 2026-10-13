import 'package:supabase_flutter/supabase_flutter.dart';

/// Código de invitación activo de un hogar.
class HomeInvite {
  const HomeInvite({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// Lo escrito por la persona → código canónico (8 caracteres, mayúsculas, sin
/// guiones ni espacios). Admite "abcd-efgh" o "ABCD EFGH".
String normalizeInviteCode(String raw) =>
    raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// "ABCDEFGH" → "ABCD-EFGH", más fácil de leer y dictar.
String formatInviteCode(String code) {
  final c = normalizeInviteCode(code);
  if (c.length != 8) return c;
  return '${c.substring(0, 4)}-${c.substring(4)}';
}

/// ¿Parece un código de invitación válido? (8 caracteres de su alfabeto).
bool looksLikeInviteCode(String raw) =>
    RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(normalizeInviteCode(raw));

/// Invitaciones y miembros del hogar. Todo pasa por funciones del servidor
/// que comprueban permisos (el código caduca a los 7 días y admite 10 usos).
class HomeInvites {
  HomeInvites(this._client);

  final SupabaseClient _client;

  /// Código activo del hogar, o null si no hay ninguno vigente.
  Future<HomeInvite?> current(String homeId) async {
    final rows = await _client
        .from('home_invites')
        .select('code, expires_at, uses, max_uses')
        .eq('home_id', homeId)
        .filter('revoked_at', 'is', null)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);
    for (final r in rows as List) {
      if ((r['uses'] as int) >= (r['max_uses'] as int)) return null;
      return HomeInvite(
        code: r['code'] as String,
        expiresAt: DateTime.parse(r['expires_at'] as String).toLocal(),
      );
    }
    return null;
  }

  /// Crea un código nuevo; el anterior deja de valer.
  Future<HomeInvite> create() async {
    final res = await _client.rpc('create_home_invite');
    final row = (res as List).first as Map;
    return HomeInvite(
      code: row['invite_code'] as String,
      expiresAt: DateTime.parse(row['invite_expires_at'] as String).toLocal(),
    );
  }

  /// Te une al hogar del código (y te saca del anterior).
  Future<void> join(String code) =>
      _client.rpc('join_home_with_code', params: {'p_code': code});

  /// El administrador quita a un miembro.
  Future<void> removeMember(String userId) =>
      _client.rpc('remove_home_member', params: {'p_user_id': userId});

  /// Salir del hogar.
  Future<void> leave() => _client.rpc('leave_home');
}
