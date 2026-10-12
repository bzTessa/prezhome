/// Lógica PURA de sincronización en vivo (Realtime), sin tipos de Supabase.
///
/// Las pantallas de la lista de la compra y de tareas abren un canal Realtime
/// para refrescarse al instante cuando el OTRO miembro del hogar cambia algo
/// (tachar un producto, completar una tarea). La parte de red
/// (canal, suscripción) vive en las pantallas; aquí queda SOLO la decisión
/// testable: ¿debemos avisar de que no hay conexión en vivo? y ¿debemos
/// recargar ante un evento?
///
/// Se extrae como helper puro siguiendo el estilo de `shopping_celebration.dart`
/// (una función pura + una pequeña clase con estado), para poder cubrirlo con
/// tests unitarios sin depender de `Supabase.instance.client`.
library;

/// Estado de la suscripción al canal Realtime, en términos PUROS (sin importar
/// `RealtimeSubscribeStatus` de Supabase). Las pantallas traducen el estado
/// real a uno de estos antes de pasarlo al gate.
enum RealtimeChannelState {
  /// Suscripción correcta (el canal está escuchando cambios).
  subscribed,

  /// Error en el canal.
  error,

  /// Canal cerrado.
  closed,

  /// La suscripción expiró sin confirmarse.
  timedOut,
}

/// Decide si un estado de canal representa un FALLO de conexión en vivo
/// (cualquier estado distinto de `subscribed`). Función PURA.
bool isRealtimeFailure(RealtimeChannelState state) {
  return state != RealtimeChannelState.subscribed;
}

/// Guarda con estado que decide cuándo mostrar el aviso discreto de "sin
/// conexión en vivo" EXACTAMENTE UNA VEZ, para no spamear a la usuaria con
/// SnackBars repetidos cuando el canal encadena errores/timeouts/cierres.
///
/// Reglas:
/// - El primer fallo (error/closed/timedOut) dispara el aviso una sola vez.
/// - Fallos sucesivos NO vuelven a avisar mientras no haya una reconexión.
/// - Una suscripción correcta (`subscribed`) REARMA el gate: si vuelve a
///   caerse después, se avisa de nuevo una vez.
///
/// Clase PURA: no toca UI ni Supabase; las pantallas la consultan y, si
/// devuelve `true`, muestran el SnackBar con diseño de tarjeta.
class RealtimeNoticeGate {
  bool _notified = false;

  /// `true` si el aviso ya se mostró y aún no se ha rearmado por reconexión.
  bool get hasNotified => _notified;

  /// Registra un nuevo [state] del canal y devuelve `true` SOLO si en este
  /// momento debe mostrarse el aviso de "sin conexión en vivo".
  ///
  /// Un `subscribed` nunca avisa pero rearma el gate (permite volver a avisar
  /// si hay un fallo posterior). Un fallo avisa solo la primera vez tras el
  /// último rearme.
  bool registerStatus(RealtimeChannelState state) {
    if (!isRealtimeFailure(state)) {
      // Reconexión correcta: rearmamos para futuros fallos.
      _notified = false;
      return false;
    }
    if (_notified) return false;
    _notified = true;
    return true;
  }

  /// Rearma manualmente el gate (p. ej. al reabrir el canal). Equivale a una
  /// reconexión correcta: el próximo fallo volverá a avisar una vez.
  void reset() {
    _notified = false;
  }
}
