import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/inventory_item.dart';
import '../models/task.dart';
import 'calendar_sync.dart';
import 'file_local_store.dart';
import 'streak.dart';

typedef Reminder = ({DateTime at, String title, String body});

/// Avisos del móvil programados en el propio dispositivo, sin servidor:
/// tareas con hora, productos que caducan y la racha. Cada vez que la app
/// pasa a segundo plano se borran y se vuelven a programar los de los
/// próximos días con lo último que hay en la base de datos.
///
/// shortcut: si la persona no abre la app en una semana se queda sin avisos
/// (y no se entera de lo que añada otra persona del hogar hasta abrirla); si
/// hace falta, pasar a push remoto (FCM/APNs) desde Supabase.
class Reminders {
  static const kinds = {
    'tasks': 'Tareas con hora',
    'expiry': 'Productos que caducan',
    'streak': 'Racha de casa al día',
  };

  /// Tipos de aviso que la persona apagó (por defecto, todos encendidos).
  static final off = ValueNotifier<Set<String>>({});
  static final _store = FileLocalStore(folderName: 'settings');
  static const _key = 'reminders_off';
  static const _days = 7;
  // iOS no guarda más de 64 avisos pendientes por app.
  static const _max = 60;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<bool?>? _ready;

  static Future<void> load() async {
    try {
      final raw = await _store.read(_key);
      if (raw != null) off.value = {...(jsonDecode(raw) as List).cast()};
    } catch (_) {}
  }

  static Future<void> setOn(String kind, bool on) async {
    off.value = on ? ({...off.value}..remove(kind)) : {...off.value, kind};
    try {
      await _store.write(_key, jsonEncode(off.value.toList()));
    } catch (_) {}
  }

  static Future<bool?> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // El permiso se pide en [sync], no al arrancar.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  static Future<void>? _running;

  /// Vuelve a programar los avisos. No lanza.
  static Future<void> sync(SupabaseClient client) {
    if (kIsWeb) return Future.value();
    return _running ??= _sync(client).whenComplete(() => _running = null);
  }

  /// Quita todos los avisos (al cerrar sesión).
  static Future<void> clear() async {
    if (kIsWeb) return;
    try {
      await _init();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Reminders.clear error: $e');
    }
  }

  static Future<void> _sync(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      await _init();
      final list = off.value.length == kinds.length
          ? const <Reminder>[]
          : await _load(client, user.id);
      if (list.isNotEmpty && !await _allowed()) return;
      await _plugin.cancelAll();
      for (final (i, r) in list.indexed) {
        await _plugin.zonedSchedule(
          id: i,
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          title: r.title,
          body: r.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'recordatorios',
              'Recordatorios',
              channelDescription: 'Tareas, caducidades y racha',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          // Sin hora exacta: no hace falta el permiso de alarmas de Android.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Reminders error: $e');
    }
  }

  static Future<bool> _allowed() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  static Future<List<Reminder>> _load(SupabaseClient client, String uid) async {
    final skip = off.value;
    final profile = await client
        .from('profiles')
        .select('home_id')
        .eq('id', uid)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String day(DateTime d) => d.toIso8601String().split('T').first;

    var tasks = <HomeTask>[];
    if (!skip.contains('tasks')) {
      final res = await client
          .from('tasks')
          .select()
          .eq('home_id', homeId)
          .eq('is_done', false)
          .not('due_time', 'is', null);
      tasks = [
        for (final t in res as List)
          if (t['assigned_to'] == null || t['assigned_to'] == uid)
            HomeTask.fromMap(t),
      ];
    }
    var items = <InventoryItem>[];
    if (!skip.contains('expiry')) {
      final res = await client
          .from('inventory_items')
          .select()
          .eq('home_id', homeId)
          .gt('quantity', 0)
          .gte('expiration_date', day(today))
          .lte('expiration_date', day(today.add(const Duration(days: _days))));
      items = [for (final r in res as List) InventoryItem.fromMap(r)];
    }
    final streak = skip.contains('streak') ? null : await Streak.load(client);
    return plan(tasks: tasks, items: items, streak: streak, now: now);
  }

  /// Los avisos de los próximos días, del más cercano al más lejano.
  static List<Reminder> plan({
    required List<HomeTask> tasks,
    required List<InventoryItem> items,
    required Streak? streak,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final until = today.add(const Duration(days: _days));
    final out = <Reminder>[
      for (final e in CalendarSync.taskEvents(tasks, today, until))
        (at: e.start, title: 'Toca: ${e.title}', body: 'Tarea de hoy'),
    ];

    // Un aviso por día, a las 10:00 del día anterior a caducar.
    final byDay = <DateTime, List<String>>{};
    for (final i in items) {
      final d = i.expirationDate;
      if (d == null) continue;
      (byDay[DateTime(d.year, d.month, d.day)] ??= []).add(i.name);
    }
    byDay.forEach((d, names) {
      out.add((
        at: DateTime(d.year, d.month, d.day - 1, 10),
        title: names.length == 1
            ? 'Mañana caduca ${names.first}'
            : 'Mañana caducan ${names.length} productos',
        body: names.join(', '),
      ));
    });

    // A las 20:00 de hoy (si aún no cuenta) y de los dos días siguientes.
    if (streak != null && streak.days > 0) {
      for (var i = streak.doneToday ? 1 : 0; i < 3; i++) {
        out.add((
          at: DateTime(today.year, today.month, today.day + i, 20),
          title: 'Tu racha te espera',
          body: 'Tacha una tarea o apunta una comida para no perderla.',
        ));
      }
    }

    return (out.where((r) => r.at.isAfter(now)).toList()
          ..sort((a, b) => a.at.compareTo(b.at)))
        .take(_max)
        .toList();
  }
}
