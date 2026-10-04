/// Lógica PURA del "gate" (guarda) de la celebración de la lista de la compra.
///
/// Decide, a partir del conteo ANTERIOR y ACTUAL de pendientes y de si hay
/// items comprados, si debe DETONARSE la celebración (Miau celebrando + rebote
/// + confeti). Se extrae como lógica pura y testable para no depender del
/// ciclo de `build()` del `FutureBuilder`: la detección de la transición a 0
/// pendientes se hace al COMPLETAR el fetch, no dentro de `build()`, lo que
/// evita el replay del confeti cuando un rebuild no cambia el conteo (p. ej.
/// borrar un comprado desde el menú estando ya en 0 pendientes).
///
/// Regla: la celebración se dispara SOLO en la TRANSICIÓN de >0 a 0 pendientes
/// teniendo al menos un comprado. No se re-dispara si ya se estaba en 0 y se
/// recarga. Se rearma cuando vuelve a haber pendientes (>0).
library;

/// Decide si debe dispararse la celebración dada la transición de conteos.
///
/// - [previousPending]: pendientes del fetch anterior; `null` en el primer
///   fetch (arranque directo con la lista ya completa NO debe celebrar).
/// - [currentPending]: pendientes del fetch actual.
/// - [hasPurchased]: si hay al menos un item ya comprado.
///
/// Devuelve `true` solo cuando se pasa de >0 pendientes a 0 teniendo comprados.
/// Función PURA: mismos argumentos -> mismo resultado, sin estado global.
bool shouldCelebratePurchase({
  required int? previousPending,
  required int currentPending,
  required bool hasPurchased,
}) {
  if (previousPending == null) return false;
  return previousPending > 0 && currentPending == 0 && hasPurchased;
}

/// Guarda con estado para la pantalla de la compra. Recuerda el conteo anterior
/// de pendientes y, en cada fetch resuelto, decide si celebrar aplicando
/// [shouldCelebratePurchase]. El disparo se CONSUME: una vez leído con
/// [consume], no se vuelve a reportar hasta la siguiente transición.
class ShoppingCelebrationGate {
  int? _previousPending;
  bool _pending = false;

  /// Conteo de pendientes del fetch anterior (para tests/depuración).
  int? get previousPending => _previousPending;

  /// Registra el resultado de un fetch recién completado y actualiza el estado
  /// interno. Devuelve `true` si ESTE fetch representa la transición a 0 que
  /// debe celebrarse. Idempotente dentro del mismo conteo: recargar con el
  /// mismo número de pendientes (p. ej. seguir en 0) NO vuelve a disparar.
  bool registerFetch({
    required int currentPending,
    required bool hasPurchased,
  }) {
    final celebrate = shouldCelebratePurchase(
      previousPending: _previousPending,
      currentPending: currentPending,
      hasPurchased: hasPurchased,
    );
    _previousPending = currentPending;
    if (celebrate) _pending = true;
    return celebrate;
  }

  /// `true` si hay una celebración pendiente de mostrarse (aún no consumida).
  bool get isCelebrationPending => _pending;

  /// Consume la celebración pendiente: devuelve `true` una sola vez tras un
  /// disparo y limpia el flag para evitar el REPLAY en rebuilds posteriores que
  /// no cambian el conteo.
  bool consume() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }
}
