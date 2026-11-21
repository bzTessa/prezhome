import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un apunte de la bandeja: algo escrito rápido desde el "+" que todavía no
/// se ha convertido en compra, tarea ni aviso.
class InboxNote {
  const InboxNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.remindAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime? remindAt;

  factory InboxNote.fromMap(Map<String, dynamic> m) => InboxNote(
    id: m['id'] as String,
    text: (m['text'] ?? '').toString(),
    createdAt:
        DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now(),
    remindAt: DateTime.tryParse(m['remind_at']?.toString() ?? '')?.toLocal(),
  );
}

/// Bandeja de apuntes (tabla `inbox_notes`, privada de cada persona).
class Inbox {
  Inbox(this._client);

  final SupabaseClient _client;

  /// Cuántos apuntes quedan por ordenar. Lo escuchan Hoy y el "+".
  static final count = ValueNotifier<int>(0);

  Future<List<InboxNote>> list() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await _client
        .from('inbox_notes')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    final notes = [
      for (final r in rows as List)
        InboxNote.fromMap(Map<String, dynamic>.from(r)),
    ];
    count.value = notes.length;
    return notes;
  }

  /// Recuenta sin lanzar (para Hoy).
  Future<void> refreshCount() async {
    try {
      await list();
    } catch (e) {
      debugPrint('Inbox.refreshCount error: $e');
    }
  }

  Future<void> add(String homeId, String text) async {
    await _client.from('inbox_notes').insert({
      'home_id': homeId,
      'text': text.trim(),
    });
    count.value = count.value + 1;
  }

  Future<void> remove(String id) async {
    await _client.from('inbox_notes').delete().eq('id', id);
    if (count.value > 0) count.value = count.value - 1;
  }

  /// Pone (o quita, con null) el aviso del apunte.
  Future<void> setRemind(String id, DateTime? at) => _client
      .from('inbox_notes')
      .update({'remind_at': at?.toUtc().toIso8601String()})
      .eq('id', id);

  /// Vuelve a poner un apunte borrado (Deshacer).
  Future<void> restore(String homeId, InboxNote n) async {
    await _client.from('inbox_notes').insert({
      'id': n.id,
      'home_id': homeId,
      'text': n.text,
      'remind_at': n.remindAt?.toUtc().toIso8601String(),
      'created_at': n.createdAt.toUtc().toIso8601String(),
    });
    count.value = count.value + 1;
  }
}
