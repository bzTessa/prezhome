/// Convierte errores técnicos en frases que cualquiera entiende.
///
/// Antes la app enseñaba cosas como "Error: PostgrestException(message: ...)".
/// Lógica PURA (solo mira el texto del error) para poder testearla.
library;

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;
import '../l10n/l10n.dart';

/// Mensaje para el usuario. [context] es lo que se intentaba hacer
/// ("No se pudo guardar") y va delante: "No se pudo guardar. Parece que no
/// hay conexión…".
String friendlyError(Object? error, [String? context]) {
  final reason = _reason(error);
  final c = context?.trim() ?? '';
  return c.isEmpty ? reason : '$c. $reason';
}

String _reason(Object? error) {
  // Los mensajes que lanza la propia app (o devuelven nuestras funciones del
  // servidor) ya están en el idioma de la persona.
  if (error is String) {
    final s = error.trim();
    if (s.isEmpty) return _generic;
    return s.endsWith('.') ? s : '$s.';
  }

  // Las funciones del servidor responden { error: '...' } con un mensaje ya
  // pensado para el usuario (p. ej. el límite del mes y cuándo se renueva).
  // supabase_flutter lo envuelve en FunctionException al no ser 2xx.
  if (error is FunctionException) {
    final msg = _serverMessage(error.details);
    if (msg != null) return _reason(msg);
  }

  final t = (error?.toString() ?? '').toLowerCase();
  bool has(List<String> needles) => needles.any(t.contains);

  if (has([
    'socketexception',
    'failed host lookup',
    'clientexception',
    'connection refused',
    'connection closed',
    'network is unreachable',
    'timeoutexception',
    'timed out',
    'xmlhttprequest',
  ])) {
    return appL10n.errNoConnection;
  }
  if (has(['invalid login credentials', 'invalid_credentials'])) {
    return appL10n.errBadLogin;
  }
  if (has(['email not confirmed'])) {
    return appL10n.errConfirmEmail;
  }
  if (has(['authexception', 'jwt', 'refresh_token'])) {
    return appL10n.errSession;
  }
  if (has(['42501', 'row-level security', 'permission denied'])) {
    return appL10n.errPermission;
  }
  if (has(['429', 'quota', 'rate limit', 'límite de ia'])) {
    return appL10n.errRateLimit;
  }
  if (has(['23505', 'duplicate key'])) {
    return appL10n.errExists;
  }
  if (has(['payload too large', '413', 'storageexception'])) {
    return appL10n.errUpload;
  }
  return _generic;
}

String? _serverMessage(dynamic details) {
  if (details is String) {
    try {
      details = jsonDecode(details);
    } catch (_) {
      return null;
    }
  }
  final msg = details is Map ? details['error'] : null;
  return msg is String && msg.trim().isNotEmpty ? msg : null;
}

String get _generic => appL10n.errGeneric;
