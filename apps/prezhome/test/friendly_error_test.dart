import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/friendly_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

class _FakeError {
  _FakeError(this.text);
  final String text;
  @override
  String toString() => text;
}

void main() {
  test('sin conexión', () {
    expect(
      friendlyError(_FakeError('ClientException: Failed host lookup')),
      'Parece que no hay conexión. Inténtalo de nuevo en un momento.',
    );
  });

  test('sesión caducada', () {
    expect(
      friendlyError(_FakeError('AuthException(message: JWT expired)')),
      'Tu sesión ha caducado. Vuelve a iniciar sesión.',
    );
  });

  test('credenciales incorrectas al entrar no dicen "sesión caducada"', () {
    expect(
      friendlyError(
        _FakeError('AuthException(message: Invalid login credentials)'),
      ),
      'El correo o la contraseña no son correctos.',
    );
  });

  test('permisos (RLS)', () {
    expect(
      friendlyError(
        _FakeError('PostgrestException(code: 42501, row-level security)'),
      ),
      'No tienes permiso para hacer esto en este hogar.',
    );
  });

  test('con contexto delante', () {
    expect(
      friendlyError(_FakeError('SocketException'), 'No se pudo guardar'),
      'No se pudo guardar. Parece que no hay conexión. '
      'Inténtalo de nuevo en un momento.',
    );
  });

  test('los mensajes propios en español se respetan', () {
    expect(
      friendlyError('No perteneces a ningún hogar.'),
      'No perteneces a ningún hogar.',
    );
    expect(
      friendlyError('La IA no devolvió una receta válida'),
      'La IA no devolvió una receta válida.',
    );
  });

  test('lo desconocido no enseña detalles técnicos', () {
    final msg = friendlyError(_FakeError('PostgrestException(code: XX000)'));
    expect(msg, 'Algo ha fallado. Inténtalo de nuevo.');
    expect(friendlyError(null), 'Algo ha fallado. Inténtalo de nuevo.');
  });

  test(
    'el límite del mes muestra el mensaje del servidor, no "demasiadas peticiones"',
    () {
      const msg =
          'Has llegado al límite de este mes. Se renueva el 1 de noviembre.';
      expect(
        friendlyError(
          FunctionException(status: 429, details: {'error': msg}),
          'Error al escanear',
        ),
        'Error al escanear. $msg',
      );
      expect(
        friendlyError(
          FunctionException(status: 429, details: '{"error":"$msg"}'),
        ),
        msg,
      );
    },
  );

  test(
    'un 429 sin mensaje del servidor sigue siendo "demasiadas peticiones"',
    () {
      expect(
        friendlyError(FunctionException(status: 429)),
        'Demasiadas peticiones seguidas. Prueba en un rato.',
      );
    },
  );
}
