import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'file_local_store.dart';

/// Cómo quiere ver cada persona su plan: comidas ocultas (p. ej. desayuno y
/// merienda), a qué hora come, ayuno y calendario.
///
/// shortcut: se guarda en el dispositivo, no en el perfil; si hace falta que
/// viaje entre móviles, pasarlo a profiles.
class PlanPrefs {
  const PlanPrefs({
    this.hidden = const {},
    this.times = const {},
    this.fastHours,
    this.calendarId,
    this.energy = 1,
  });

  final Set<String> hidden;

  /// Hora de cada comida en minutos desde medianoche; lo que falte usa
  /// [defaultTimes].
  final Map<String, int> times;

  /// Horas de ayuno (12, 14, 16) o null si no ayuna.
  final int? fastHours;

  /// Calendario del móvil al que se pasan comidas y tareas, o null.
  final String? calendarId;

  /// Cuánto cocinar (0 poco, 1 normal, 2 mucho): cuántos días de tanda hay.
  final int energy;

  static const defaultTimes = {
    'breakfast': 8 * 60 + 30,
    'lunch': 14 * 60,
    'dessert': 14 * 60,
    'snack': 17 * 60 + 30,
    'dinner': 21 * 60,
  };

  static final current = ValueNotifier<PlanPrefs>(const PlanPrefs());
  static final _store = FileLocalStore(folderName: 'settings');
  static const _key = 'plan_prefs';

  /// Comidas que el plan genera solo: sin las ocultas.
  List<String> planned(List<String> meals) => [
    for (final m in meals)
      if (!hidden.contains(m)) m,
  ];

  int minutesOf(String meal) => times[meal] ?? defaultTimes[meal] ?? 21 * 60;

  String timeOf(String meal) => formatMinutes(minutesOf(meal));

  static String formatMinutes(int m) =>
      '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';

  /// Ventana para comer con ayuno, en minutos: acaba una hora después de la
  /// cena (lo que se tarda en cenar) y dura 24 − [fastHours].
  ({int start, int end})? get eatingWindow {
    final f = fastHours;
    if (f == null) return null;
    final end = minutesOf('dinner') + 60;
    return (start: end - (24 - f) * 60, end: end);
  }

  /// Si [meal] cae fuera de la ventana para comer.
  bool inFast(String meal) {
    final w = eatingWindow;
    if (w == null) return false;
    final m = minutesOf(meal);
    return m < w.start || m >= w.end;
  }

  /// Si a las [now] toca ayunar y cuándo cambia (empieza a comer o a
  /// ayunar). Null sin ayuno.
  ({bool fasting, DateTime until})? fastAt(DateTime now) {
    final w = eatingWindow;
    if (w == null) return null;
    final m = now.hour * 60 + now.minute;
    final eating = (m - w.start) % 1440 < w.end - w.start;
    final next = (eating ? w.end : w.start) % 1440;
    final wait = (next - m) % 1440;
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    return (
      fasting: !eating,
      until: base.add(Duration(minutes: wait == 0 ? 1440 : wait)),
    );
  }

  PlanPrefs copyWith({
    Set<String>? hidden,
    Map<String, int>? times,
    int? Function()? fastHours,
    String? Function()? calendarId,
    int? energy,
  }) => PlanPrefs(
    hidden: hidden ?? this.hidden,
    times: times ?? this.times,
    fastHours: fastHours == null ? this.fastHours : fastHours(),
    calendarId: calendarId == null ? this.calendarId : calendarId(),
    energy: energy ?? this.energy,
  );

  static Future<void> load() async {
    try {
      final raw = await _store.read(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      current.value = PlanPrefs(
        hidden: {...(m['hidden'] as List? ?? const []).cast<String>()},
        times: {
          ...(m['times'] as Map? ?? const {}).map(
            (k, v) => MapEntry(k as String, v as int),
          ),
        },
        fastHours: m['fast_hours'] as int?,
        calendarId: m['calendar_id'] as String?,
        energy: m['energy'] as int? ?? 1,
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
          'times': p.times,
          'fast_hours': p.fastHours,
          'calendar_id': p.calendarId,
          'energy': p.energy,
        }),
      );
    } catch (_) {}
  }
}
