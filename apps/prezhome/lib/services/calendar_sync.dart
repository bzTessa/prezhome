import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_plan_entry.dart';
import '../models/task.dart';
import 'plan_prefs.dart';
import '../l10n/l10n.dart';

/// Pasa comidas del plan y tareas con hora al calendario del móvil (el de
/// Google si la cuenta está en el móvil) y lee los huecos ocupados.
///
/// Solo toca los eventos que creó PrezHome: los marca en la descripción y,
/// al actualizar, borra los suyos de los próximos días y los vuelve a crear.
class CalendarSync {
  static const _mark = 'Desde PrezHome';
  static const _days = 7;

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
          .eq('is_done', false);
      final tasks = [for (final t in tasksRes as List) HomeTask.fromMap(t)];
      final prefs = PlanPrefs.current.value;

      final events = [
        ...mealEvents(entries, titles, prefs),
        ...taskEvents(tasks.where((t) => t.dueTime != null), today, until),
      ];
      // Las tareas sin hora (mías o de cualquiera) van al primer hueco libre.
      if (prefs.busyAware) {
        final others = busyOf(await _cal.listEvents(today, until));
        events.addAll(
          placeTasks(
            [
              for (final t in tasks)
                if (t.dueTime == null &&
                    (t.assignedTo == null || t.assignedTo == user.id))
                  t,
            ],
            today,
            until,
            [
              ...others,
              for (final e in events)
                (start: e.start, end: e.start.add(e.length)),
            ],
            now,
          ),
        );
      }

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
            '${appL10n.mealType(e.mealType)}: '
            '${titles[e.recipeId] ?? appL10n.recipe}',
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
    Iterable<HomeTask> tasks,
    DateTime from,
    DateTime until,
  ) {
    final out = <CalendarItem>[];
    for (final t in tasks) {
      final parts = t.dueTime?.split(':');
      if (parts == null || parts.length < 2) continue;
      final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      for (final d in dueDays(t, from, until)) {
        out.add((
          title: t.title,
          start: DateTime(d.year, d.month, d.day, 0, minutes),
          length: const Duration(minutes: 30),
        ));
      }
    }
    return out;
  }

  /// Días en que toca [t] entre [from] y [until] (excluido).
  static Iterable<DateTime> dueDays(
    HomeTask t,
    DateTime from,
    DateTime until,
  ) sync* {
    DateTime? d = t.nextDue ?? t.dueDate;
    // Una recurrente atrasada sigue pendiente: se pone hoy.
    if (d != null && d.isBefore(from)) d = from;
    while (d != null && d.isBefore(until)) {
      yield d;
      d = t.computeNextDue(d);
    }
  }

  /// Media hora por cada vez que toca una tarea sin hora, en el primer hueco
  /// que no pisa [busy] ni otra tarea ya puesta. Si el día está lleno, no va.
  static List<CalendarItem> placeTasks(
    List<HomeTask> tasks,
    DateTime from,
    DateTime until,
    List<({DateTime start, DateTime end})> busy,
    DateTime now,
  ) {
    final taken = [...busy];
    final out = <CalendarItem>[];
    for (final t in tasks) {
      for (final d in dueDays(t, from, until)) {
        final m = freeSlot(taken, d, now);
        if (m == null) continue;
        final start = DateTime(d.year, d.month, d.day, 0, m);
        const length = Duration(minutes: 30);
        out.add((title: t.title, start: start, length: length));
        taken.add((start: start, end: start.add(length)));
      }
    }
    return out;
  }

  /// Pide permiso para leer el calendario. false si no lo da.
  static Future<bool> askPermission() async {
    try {
      return await _cal.requestPermissions() ==
          CalendarPermissionStatus.granted;
    } catch (e) {
      debugPrint('CalendarSync.askPermission error: $e');
      return false;
    }
  }

  /// Carga de cada uno de los [days] días desde [from] según los calendarios
  /// del móvil (ver [loadOf]). Vacío sin permiso.
  static Future<Map<String, int>> dayLoads(DateTime from, int days) async {
    try {
      final status = await _cal.hasPermissions();
      if (status != CalendarPermissionStatus.granted) return const {};
      final start = DateTime(from.year, from.month, from.day);
      final end = DateTime(start.year, start.month, start.day + days);
      final busy = busyOf(await _cal.listEvents(start, end));
      return {
        for (var i = 0; i < days; i++)
          dayKey(DateTime(start.year, start.month, start.day + i)): loadOf(
            busy,
            DateTime(start.year, start.month, start.day + i),
          ),
      };
    } catch (e) {
      debugPrint('CalendarSync.dayLoads error: $e');
      return const {};
    }
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Huecos ocupados de [events], sin los de todo el día ni los de PrezHome.
  static List<({DateTime start, DateTime end})> busyOf(List<Event> events) => [
    for (final e in events)
      if (!e.isAllDay && e.description != _mark)
        (start: e.startDate, end: e.endDate),
  ];

  /// 0 libre (una hora o menos ocupada entre las 8:00 y las 22:00), 2 cargado
  /// (dos horas o más ocupadas de 17:00 a 22:00, cuando se cocina, o diez o
  /// más en todo el día) y 1 lo demás: una jornada de trabajo normal es 1.
  static int loadOf(List<({DateTime start, DateTime end})> busy, DateTime day) {
    final base = DateTime(day.year, day.month, day.day);
    var minutes = 0;
    var evening = 0;
    for (var m = 8 * 60; m < 22 * 60; m += 15) {
      final s = base.add(Duration(minutes: m));
      final e = s.add(const Duration(minutes: 15));
      if (busy.any((b) => b.start.isBefore(e) && b.end.isAfter(s))) {
        minutes += 15;
        if (m >= 17 * 60) evening += 15;
      }
    }
    if (evening >= 2 * 60 || minutes >= 10 * 60) return 2;
    return minutes <= 60 ? 0 : 1;
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
