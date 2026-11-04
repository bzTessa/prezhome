import 'dart:async';

/// Agrupa ráfagas de llamadas en una sola ejecución: cada [run] reinicia el
/// temporizador, de modo que la acción corre UNA vez, [delay] después de la
/// última llamada. Útil para que subir/bajar la cantidad o marcar varios
/// productos seguidos no dispare un refresco pesado en cada toque.
///
/// Lógica pura y testeable: inyecta el reloj con [schedule] para no depender de
/// Timer real en los tests (por defecto usa Timer). Acuérdate de [cancel] al
/// desechar el dueño.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  /// Espera tras la última llamada antes de ejecutar la acción.
  final Duration delay;

  Timer? _timer;

  /// Programa [action] para dentro de [delay], cancelando cualquier ejecución
  /// pendiente anterior. Varias llamadas seguidas => una sola ejecución.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// true si hay una ejecución pendiente (programada y aún no disparada).
  bool get isPending => _timer?.isActive ?? false;

  /// Cancela la ejecución pendiente, si la hubiera.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
