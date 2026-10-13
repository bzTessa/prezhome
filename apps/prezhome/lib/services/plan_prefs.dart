import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'file_local_store.dart';

/// Cómo quiere ver cada persona su plan: comidas ocultas (p. ej. desayuno y
/// merienda) y un desayuno fijo de cada día ("Café con leche").
///
/// shortcut: se guarda en el dispositivo, no en el perfil; si hace falta que
/// viaje entre móviles, pasarlo a profiles.
class PlanPrefs {
  const PlanPrefs({this.hidden = const {}, this.fixedBreakfast});

  final Set<String> hidden;
  final String? fixedBreakfast;

  static final current = ValueNotifier<PlanPrefs>(const PlanPrefs());
  static final _store = FileLocalStore(folderName: 'settings');
  static const _key = 'plan_prefs';

  /// Comidas que el plan genera solo: sin las ocultas ni el desayuno fijo.
  List<String> planned(List<String> meals) => [
    for (final m in meals)
      if (!hidden.contains(m) && !(m == 'breakfast' && fixedBreakfast != null))
        m,
  ];

  static Future<void> load() async {
    try {
      final raw = await _store.read(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      current.value = PlanPrefs(
        hidden: {...(m['hidden'] as List? ?? const []).cast<String>()},
        fixedBreakfast: m['fixed_breakfast'] as String?,
      );
    } catch (_) {}
  }

  static Future<void> save(PlanPrefs p) async {
    current.value = p;
    try {
      await _store.write(
        _key,
        jsonEncode({
          'hidden': p.hidden.toList(),
          'fixed_breakfast': p.fixedBreakfast,
        }),
      );
    } catch (_) {}
  }
}
