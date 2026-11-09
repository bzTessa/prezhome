import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/inventory_item.dart';
import '../models/task.dart';
import 'calendar_sync.dart';
import 'file_local_store.dart';
import 'streak.dart';

/// [kind] es una clave de [Reminders.kinds]: decide el canal del aviso y a
/// qué pestaña lleva al tocarlo.
typedef Reminder = ({DateTime at, String title, String body, String kind});

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

  /// Tipo del aviso que la persona acaba de tocar; el shell lo consume para
  /// abrir la pestaña que toca y lo vuelve a poner a null.
  static final opened = ValueNotifier<String?>(null);

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

  static Future<bool?> _init() => _ready ??= _initialize();

  static Future<bool?> _initialize() async {
    final ok = await _plugin.initialize(
      settings: _settings,
      onDidReceiveNotificationResponse: (r) => opened.value = r.payload,
    );
    // La app estaba cerrada y se abrió tocando un aviso.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      opened.value = launch!.notificationResponse?.payload;
    }
    // Antes había un solo canal para todo; ahora cada tipo tiene el suyo.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.deleteNotificationChannel(channelId: 'recordatorios');
    return ok;
  }

  static const _settings = InitializationSettings(
    // Silueta blanca: el icono de la app a color sale como un cuadrado.
    android: AndroidInitializationSettings('ic_notification'),
    // El permiso se pide en [sync], no al arrancar.
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );

  static const _brand = Color(0xFFD85A32);

  static NotificationDetails _details(Reminder r) => NotificationDetails(
    android: AndroidNotificationDetails(
      r.kind,
      kinds[r.kind]!,
      color: _brand,
      // El texto entero al desplegar, no cortado en una línea.
      styleInformation: BigTextStyleInformation(r.body),
      category: r.kind == 'tasks'
          ? AndroidNotificationCategory.reminder
          : AndroidNotificationCategory.recommendation,
    ),
    iOS: DarwinNotificationDetails(threadIdentifier: r.kind),
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
          notificationDetails: _details(r),
          payload: r.kind,
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
    final out = <Reminder>[];

    // Tareas a la misma hora, en un solo aviso.
    final byTime = <DateTime, List<String>>{};
    for (final e in CalendarSync.taskEvents(tasks, today, until)) {
      (byTime[e.start] ??= []).add(e.title);
    }
    byTime.forEach((at, titles) {
      out.add((
        at: at,
        title: titles.length == 1
            ? 'Toca: ${titles.first}'
            : 'Tocan ${titles.length} tareas',
        body: titles.length == 1
            ? 'Cuando la acabes, táchala para sumar puntos.'
            : '${_list(titles)}. Táchalas al acabar para sumar puntos.',
        kind: 'tasks',
      ));
    });

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
            ? 'Mañana caduca: ${names.first}'
            : 'Mañana caducan ${names.length} productos',
        body:
            '${names.length == 1 ? '' : '${_list(names)}. '}'
            'Cocina hoy con ello o congela lo que no vayas a usar.',
        kind: 'expiry',
      ));
    });

    // A las 20:00 de hoy (si aún no cuenta) y de los dos días siguientes,
    // con un texto distinto cada día para que no canse.
    if (streak != null && streak.days > 0) {
      final next = streak.doneToday ? streak.days : streak.days + 1;
      final texts = [
        Streak.milestones.contains(next)
            ? (
                'Hoy llegas a $next días',
                'Tacha una tarea o apunta una comida y lo celebras.',
              )
            : (
                'Llevas ${streak.days} días con la casa al día',
                'Tacha una tarea o apunta una comida para no perder la racha.',
              ),
        (
          '¿Cómo va la casa hoy?',
          'Un gesto basta para sumar un día más a tu racha.',
        ),
        (
          'Tu racha sigue viva',
          'Apunta lo que has comido o tacha una tarea antes de dormir.',
        ),
      ];
      for (var i = streak.doneToday ? 1 : 0; i < 3; i++) {
        out.add((
          at: DateTime(today.year, today.month, today.day + i, 20),
          title: texts[i].$1,
          body: texts[i].$2,
          kind: 'streak',
        ));
      }
    }

    return (out.where((r) => r.at.isAfter(now)).toList()
          ..sort((a, b) => a.at.compareTo(b.at)))
        .take(_max)
        .toList();
  }

  /// "a, b y c"; con más de 4, "a, b, c, d y 3 más".
  static String _list(List<String> names) {
    final shown = names.take(4).toList();
    final rest = names.length - shown.length;
    if (rest > 0) return '${shown.join(', ')} y $rest más';
    if (shown.length == 1) return shown.first;
    return '${shown.sublist(0, shown.length - 1).join(', ')} y ${shown.last}';
  }
}
