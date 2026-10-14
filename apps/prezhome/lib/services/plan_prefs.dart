import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'file_local_store.dart';

/// Cómo quiere ver cada persona su plan: comidas ocultas (p. ej. desayuno y
/// merienda).
///
/// shortcut: se guarda en el dispositivo, no en el perfil; si hace falta que
/// viaje entre móviles, pasarlo a profiles.
class PlanPrefs {
  const PlanPrefs({this.hidden = const {}});

  final Set<String> hidden;

  static final current = ValueNotifier<PlanPrefs>(const PlanPrefs());
  static final _store = FileLocalStore(folderName: 'settings');
  static const _key = 'plan_prefs';

  /// Comidas que el plan genera solo: sin las ocultas.
  List<String> planned(List<String> meals) => [
    for (final m in meals)
      if (!hidden.contains(m)) m,
  ];

  static Future<void> load() async {
    try {
      final raw = await _store.read(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      current.value = PlanPrefs(
        hidden: {...(m['hidden'] as List? ?? const []).cast<String>()},
      );
    } catch (_) {}
  }

  static Future<void> save(PlanPrefs p) async {
    current.value = p;
    try {
      await _store.write(_key, jsonEncode({'hidden': p.hidden.toList()}));
    } catch (_) {}
  }
}
