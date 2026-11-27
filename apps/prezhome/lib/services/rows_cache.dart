import 'dart:convert';

import 'file_local_store.dart';

/// Última copia buena de una consulta, guardada en el móvil, para enseñar
/// algo aunque no haya conexión (recetas, tareas, plan y el buscador).
class RowsCache {
  RowsCache._();

  static final _store = FileLocalStore(folderName: 'rows_cache');

  static Future<List<Map<String, dynamic>>?> read(String key) async {
    try {
      final raw = await _store.read(key);
      if (raw == null) return null;
      return [
        for (final r in jsonDecode(raw) as List)
          Map<String, dynamic>.from(r as Map),
      ];
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, List<dynamic> rows) async {
    try {
      await _store.write(key, jsonEncode(rows));
    } catch (_) {
      // Sin disco no hay copia; la app sigue igual que antes.
    }
  }

  /// Pide al servidor y guarda la copia. Si falla y hay copia, devuelve la
  /// copia; si no hay copia, deja pasar el error.
  static Future<List<Map<String, dynamic>>> fetch(
    String key,
    Future<List<dynamic>> Function() remote,
  ) async {
    try {
      final rows = [
        for (final r in await remote()) Map<String, dynamic>.from(r as Map),
      ];
      await write(key, rows);
      return rows;
    } catch (_) {
      final cached = await read(key);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Igual que [fetch] para una sola fila (o ninguna).
  static Future<Map<String, dynamic>?> fetchOne(
    String key,
    Future<Map<String, dynamic>?> Function() remote,
  ) async {
    final rows = await fetch(key, () async {
      final r = await remote();
      return r == null ? const [] : [r];
    });
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> clear() async {
    try {
      await _store.clearAll();
    } catch (_) {}
  }
}
