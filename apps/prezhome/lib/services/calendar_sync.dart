import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_plan_entry.dart';
import '../models/task.dart';
import 'plan_prefs.dart';

/// Pasa comidas del plan y tareas con hora al calendario del móvil (el de
/// Google si la cuenta está en el móvil) y lee los huecos ocupados.
///
/// Solo toca los eventos que creó PrezHome: los marca en la descripción y,
/// al actualizar, borra los suyos de los próximos días y los vuelve a crear.
class CalendarSync {
  static const _mark = 'Desde PrezHome';
  static const _days = 7;
  static const mealLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Merienda',
    'dessert': 'Postre',
  };

  static DeviceCalendar get _cal => DeviceCalendar.instance;

  /// Pide permiso y devuelve los calendarios donde se puede escribir, el
  /// principal primero. Lista vacía si no hay permiso.
  static Future<List<Calendar>> writableCalendars() async {
    final status = await _cal.requestPermissions();
    if (status != CalendarPermissionStatus.granted) return const [];
    final list = (await _cal.listCalendars()).where((c) => !c.readOnly).toList()
      ..sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    return list;
  }

  static Future<void>? _running;
  static DateTime? _lastRun;

  /// Actualiza el calendario elegido. Si se actualizó hace poco y no es
  /// [force], no hace nada. No lanza.
  static Future<void> sync(SupabaseClient client, {bool force = false}) {
    final calendarId = PlanPrefs.current.value.calendarId;
    if (calendarId == null) return Future.value();
    final last = _lastRun;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 10)) {
      return Future.value();
    }
    return _running ??= _sync(
      client,
      calendarId,
    ).whenComplete(() => _running = null);
  }

  static Future<void> _sync(SupabaseClient client, String calendarId) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    _lastRun = DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final until = today.add(const Duration(days: _days));
    String day(DateTime d) => d.toIso8601String().split('T').first;
    try {
      final profile = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      final planRes = await client
          .from('meal_plan_entries')
          .select()
          .eq('home_id', homeId)
          .gte('plan_date', day(today))
          .lt('plan_date', day(until));
      final entries = [
        for (final m in planRes as List) MealPlanEntry.fromMap(m),
      ].where((e) => !e.skipped && e.recipeId != null).toList();
      final titles = <String, String>{};
      if (entries.isNotEmpty) {
        final recRes = await client
            .from('recipes')
            .select('id, title')
            .inFilter('id', entries.map((e) => e.recipeId!).toSet().toList());
        for (final r in recRes as List) {
          titles[r['id'] as String] = r['title'] as String? ?? '';
        }
      }
      final tasksRes = await client
          .from('tasks')
          .select()
          .eq('home_id', homeId)
          .eq('is_done', false)
          .not('due_time', 'is', null);
      final tasks = [for (final t in tasksRes as List) HomeTask.fromMap(t)];

      final events = [
        ...mealEvents(entries, titles, PlanPrefs.current.value),
        ...taskEvents(tasks, today, until),
      ];

      final old = await _cal.listEvents(
        today,
        until,
        calendarIds: [calendarId],
      );
      for (final e in old) {
        if (e.description == _mark && !e.isRecurring) {
          await _cal.deleteEvent(instanceId: e.instanceId);
        }
      }
      for (final e in events) {
        if (e.start.isBefore(now)) continue;
        await _cal.createEvent(
          calendarId: calendarId,
          title: e.title,
          startDate: e.start,
          endDate: e.start.add(e.length),
          description: _mark,
        );
      }
    } catch (e) {
      debugPrint('CalendarSync error: $e');
    }
  }

  /// Un evento por comida del plan, a su hora, de 45 minutos.
  static List<CalendarItem> mealEvents(
    List<MealPlanEntry> entries,
    Map<String, String> titles,
    PlanPrefs prefs,
  ) => [
    for (final e in entries)
      (
        title:
            '${mealLabels[e.mealType] ?? e.mealType}: '
            '${titles[e.recipeId] ?? 'Receta'}',
        start: DateTime(
          e.date.year,
          e.date.month,
          e.date.day,
          0,
          prefs.minutesOf(e.mealType),
        ),
        length: const Duration(minutes: 45),
      ),
  ];

  /// Un evento por cada vez que toca una tarea con hora entre [from] y
  /// [until] (excluido), de 30 minutos.
  static List<CalendarItem> taskEvents(
    List<HomeTask> tasks,
    DateTime from,
    DateTime until,
  ) {
    final out = <CalendarItem>[];
    for (final t in tasks) {
      final parts = t.dueTime?.split(':');
      if (parts == null || parts.length < 2) continue;
      final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      DateTime? d = t.nextDue ?? t.dueDate;
      // Una recurrente atrasada sigue pendiente: se pone hoy.
      if (d != null && d.isBefore(from)) d = from;
      while (d != null && d.isBefore(until)) {
        out.add((
          title: t.title,
          start: DateTime(d.year, d.month, d.day, 0, minutes),
          length: const Duration(minutes: 30),
        ));
        d = t.computeNextDue(d);
      }
    }
    return out;
  }

  /// Eventos de [day] en todos los calendarios del móvil (vacío sin permiso).
  static Future<List<Event>> busyOn(DateTime day) async {
    try {
      final status = await _cal.hasPermissions();
      if (status != CalendarPermissionStatus.granted) return const [];
      final start = DateTime(day.year, day.month, day.day);
      return await _cal.listEvents(start, start.add(const Duration(days: 1)));
    } catch (e) {
      debugPrint('CalendarSync.busyOn error: $e');
      return const [];
    }
  }

  /// Primera media hora libre de [day] entre las 8:00 y las 22:00 que no
  /// pisa [busy] (ni ya pasó, si es hoy). En minutos desde medianoche.
  static int? freeSlot(
    List<({DateTime start, DateTime end})> busy,
    DateTime day,
    DateTime now, {
    int length = 30,
  }) {
    final base = DateTime(day.year, day.month, day.day);
    for (var m = 8 * 60; m + length <= 22 * 60; m += 30) {
      final s = base.add(Duration(minutes: m));
      final e = s.add(Duration(minutes: length));
      if (s.isBefore(now)) continue;
      if (busy.every((b) => !b.start.isBefore(e) || !b.end.isAfter(s))) {
        return m;
      }
    }
    return null;
  }
}

typedef CalendarItem = ({String title, DateTime start, Duration length});
