import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import 'reminders.dart';

/// Resultado de avisar a casa.
enum PushResult { sent, nobody, notConfigured, failed }

/// Avisos push entre la gente de casa (Firebase Cloud Messaging).
///
/// Por ahora solo Android: iOS necesita la clave APNs de Apple y su
/// GoogleService-Info.plist. Al entrar se guarda el token del móvil en
/// push_tokens; la función notify-home los usa para avisar a los demás.
class Push {
  static bool get supported => !kIsWeb && Platform.isAndroid;

  static bool _started = false;
  static StreamSubscription<String>? _refresh;

  /// Pide permiso, guarda el token y escucha los avisos. Nunca rompe el
  /// arranque: si algo falla, la app sigue sin avisos push.
  static Future<void> register(SupabaseClient client) async {
    if (!supported) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission();
      final token = await fcm.getToken();
      if (token != null) await _save(client, token);
      await _refresh?.cancel();
      _refresh = fcm.onTokenRefresh.listen((t) => _save(client, t));
      if (_started) return;
      _started = true;
      // Con la app abierta Android no lo pinta: lo mostramos nosotros.
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await fcm.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('push.register: $e');
    }
  }

  /// Al salir de la cuenta, este móvil deja de recibir avisos de esa casa.
  static Future<void> unregister(SupabaseClient client) async {
    if (!supported || Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await client.from('push_tokens').delete().eq('token', token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('push.unregister: $e');
    }
  }

  static Future<void> _save(SupabaseClient client, String token) =>
      client.from('push_tokens').upsert({
        'token': token,
        'user_id': client.auth.currentUser?.id,
        'platform': 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

  static void _open(RemoteMessage m) {
    final open = m.data['open'];
    if (open is String) Reminders.opened.value = open;
  }

  static void _showForeground(RemoteMessage m) {
    final d = m.data;
    final who = '${d['who'] ?? ''}';
    final shopping = d['kind'] == 'shopping_run';
    Reminders.showNow(
      id: shopping ? 900001 : 900002 + DateTime.now().second,
      title: shopping ? appL10n.pushShoppingTitle : appL10n.pushTaskTitle,
      body: shopping
          ? appL10n.pushShoppingBody(who)
          : appL10n.pushTaskBody(who, '${d['task'] ?? ''}'),
      open: shopping ? 'shopping' : 'tasks',
    );
  }

  /// "Voy al súper": avisa a los demás de casa para que añadan lo que falte.
  static Future<PushResult> shoppingRun(SupabaseClient client) =>
      _notify(client, {'kind': 'shopping_run'});

  /// Avisa a [to] de que le han puesto la tarea [title]. Sin respuesta: si
  /// falla, la tarea ya está guardada igual.
  static Future<void> taskAssigned(
    SupabaseClient client, {
    required String to,
    required String title,
  }) async {
    if (to == client.auth.currentUser?.id) return;
    await _notify(client, {'kind': 'task_assigned', 'to': to, 'task': title});
  }

  static Future<PushResult> _notify(
    SupabaseClient client,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await client.functions.invoke('notify-home', body: body);
      final sent = (res.data is Map ? res.data['sent'] : null) as num? ?? 0;
      return sent > 0 ? PushResult.sent : PushResult.nobody;
    } on FunctionException catch (e) {
      if (e.status == 503) return PushResult.notConfigured;
      debugPrint('push.notify: ${e.status} ${e.details}');
      return PushResult.failed;
    } catch (e) {
      debugPrint('push.notify: $e');
      return PushResult.failed;
    }
  }
}
