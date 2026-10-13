/// Convierte errores técnicos en frases que cualquiera entiende.
///
/// Antes la app enseñaba cosas como "Error: PostgrestException(message: ...)".
/// Lógica PURA (solo mira el texto del error) para poder testearla.
library;

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

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
  // servidor) ya están en español y pensados para el usuario.
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
    return 'Parece que no hay conexión. Inténtalo de nuevo en un momento.';
  }
  if (has(['invalid login credentials', 'invalid_credentials'])) {
    return 'El correo o la contraseña no son correctos.';
  }
  if (has(['email not confirmed'])) {
    return 'Confirma tu correo (revisa tu bandeja de entrada) y vuelve a '
        'intentarlo.';
  }
  if (has(['authexception', 'jwt', 'refresh_token'])) {
    return 'Tu sesión ha caducado. Vuelve a iniciar sesión.';
  }
  if (has(['42501', 'row-level security', 'permission denied'])) {
    return 'No tienes permiso para hacer esto en este hogar.';
  }
  if (has(['429', 'quota', 'rate limit', 'límite de ia'])) {
    return 'Demasiadas peticiones seguidas. Prueba en un rato.';
  }
  if (has(['23505', 'duplicate key'])) {
    return 'Eso ya existe.';
  }
  if (has(['payload too large', '413', 'storageexception'])) {
    return 'No se pudo subir la imagen. Prueba con otra más pequeña.';
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

const String _generic = 'Algo ha fallado. Inténtalo de nuevo.';
