/// Vigila si el servidor responde y lee el aviso de incidencias.
///
/// Si Supabase se cae, la app no debe parecer rota: la compra y la despensa
/// siguen funcionando con su caché y su cola (ver [OfflineProvider]). Aquí:
/// - Comprobamos cada cierto tiempo si el servidor responde (más a menudo
///   mientras está caído) y, al volver, enviamos los cambios pendientes.
/// - Leemos un aviso editable desde `status.json` del repositorio en GitHub,
///   que vive FUERA de Supabase y por eso se puede cambiar durante una caída.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_provider.dart';

/// Aviso de incidencias. Se edita en GitHub (fichero `status.json` de la raíz
/// del repo, campo "mensaje"); vacío = sin aviso.
const String kStatusUrl =
    'https://raw.githubusercontent.com/bzTessa/prezhome/main/status.json';

/// Cada cuánto se comprueba con el servidor arriba y con el servidor caído.
const Duration kCheckWhenOnline = Duration(minutes: 2);
const Duration kCheckWhenOffline = Duration(seconds: 20);

/// `true` si el error de la comprobación (o su ausencia) indica que el
/// servidor ha respondido. Un error de PostgREST con código propio (permiso,
/// tabla...) significa que la base de datos contestó; un 5xx, un timeout o un
/// fallo de red, que no.
bool serverReachable(Object? error) {
  if (error == null) return true;
  if (error is PostgrestException) {
    return !RegExp(r'^5\d\d$').hasMatch(error.code ?? '');
  }
  return false;
}

/// Extrae el aviso de `status.json`. Cualquier cosa rara = sin aviso.
String? parseStatusNotice(String body) {
  try {
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final msg = json['mensaje'];
    if (msg is! String || msg.trim().isEmpty) return null;
    return msg.trim();
  } catch (_) {
    return null;
  }
}

class ConnectionStatus {
  ConnectionStatus._();

  static final ConnectionStatus instance = ConnectionStatus._();

  /// `false` mientras el servidor no responde.
  final ValueNotifier<bool> online = ValueNotifier(true);

  /// Aviso de incidencias vigente, o `null`.
  final ValueNotifier<String?> notice = ValueNotifier(null);

  Timer? _timer;
  bool _checking = false;
  bool _running = false;

  /// Arranca las comprobaciones (idempotente). Se llama al entrar en la app y
  /// al volver a primer plano.
  void start() {
    if (_running) return;
    _running = true;
    unawaited(check());
  }

  /// Para las comprobaciones (app en segundo plano o sesión cerrada).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    _timer?.cancel();
    try {
      final results = await Future.wait([_pingServer(), _fetchNotice()]);
      final up = results[0] as bool;
      final wasOnline = online.value;
      online.value = up;
      notice.value = results[1] as String?;
      if (up && !wasOnline) await _sendPending();
    } finally {
      _checking = false;
      if (_running) {
        _timer = Timer(
          online.value ? kCheckWhenOnline : kCheckWhenOffline,
          check,
        );
      }
    }
  }

  Future<bool> _pingServer() async {
    try {
      await Supabase.instance.client
          .from('homes')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      return serverReachable(e);
    }
  }

  Future<String?> _fetchNotice() async {
    try {
      final res = await http
          .get(Uri.parse(kStatusUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return notice.value;
      return parseStatusNotice(utf8.decode(res.bodyBytes));
    } catch (_) {
      // Sin red del todo: conservamos el último aviso leído.
      return notice.value;
    }
  }

  /// Al volver el servidor, envía lo apuntado mientras estaba caído.
  Future<void> _sendPending() async {
    final offline = OfflineProvider.instance;
    try {
      await offline.shopping.tryDrain(force: true);
      await offline.inventory.tryDrain(force: true);
    } catch (_) {
      // Si falla, la cola sigue intacta y se reintenta en la próxima vuelta.
    }
  }
}
