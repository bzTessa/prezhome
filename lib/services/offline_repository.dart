/// Repositorio OFFLINE-FIRST que une el núcleo puro (caché + cola + merge) con
/// la red y el disco, SIN acoplarse a Supabase ni al binding de Flutter.
///
/// Objetivo del Paso 7: la lista de la compra y la despensa deben PINTARSE AL
/// INSTANTE desde la caché local (aunque no haya cobertura, p. ej. dentro del
/// supermercado), y los cambios hechos sin conexión deben encolarse y
/// SINCRONIZARSE con Supabase en segundo plano en cuanto vuelva la red.
///
/// Diseño:
/// - [LocalStore] inyectado -> persistencia (en memoria en tests, en disco en
///   producción con `FileLocalStore`).
/// - [RemoteSender] inyectado -> abstrae las llamadas a Supabase (insert/
///   update/delete/fetch). La implementación real (`SupabaseRemoteSender`) es
///   la ÚNICA que importa `supabase_flutter`; este archivo NO lo importa.
/// - `home_id` -> todas las claves de caché y cola van NAMESPACED por hogar
///   para que la caché local nunca mezcle datos de hogares distintos
///   (ver steering de seguridad).
///
/// CONECTIVIDAD: no usamos `connectivity_plus`. Inferimos online/offline del
/// éxito o fallo de las llamadas a [RemoteSender]. Un fetch/envío con éxito
/// cuenta como "online"; un fallo cuenta como "offline" y DETIENE el drenado
/// (sin perder las ops restantes y sin reintentar en bucle).
///
/// RESOLUCIÓN DE CONFLICTOS: last-write-wins por timestamp (ver
/// `offline_merge.dart`): la operación local gana en los campos que tocó salvo
/// que el remoto sea estrictamente más nuevo.
library;

import 'dart:convert';

import 'local_store.dart';
import 'offline_merge.dart';
import 'sync_queue.dart';

/// Abstracción PURA de la red: traduce operaciones de sincronización a llamadas
/// remotas. La implementación real vive aparte (`SupabaseRemoteSender`) para
/// que el repositorio sea testeable con un sender FALSO en memoria.
///
/// Cualquier método puede LANZAR para señalar "sin conexión" (o error de red);
/// el repositorio interpreta ese lanzamiento como "offline" y detiene el
/// drenado conservando las ops.
abstract class RemoteSender {
  /// Inserta una fila nueva en [table] con [payload].
  Future<void> sendInsert(String table, Map<String, dynamic> payload);

  /// Actualiza la fila [id] de [table] con los campos de [payload].
  Future<void> sendUpdate(
    String table,
    Map<String, dynamic> payload,
    String id,
  );

  /// Borra la fila [id] de [table].
  Future<void> sendDelete(String table, String id);

  /// Trae todas las filas de [table] para el hogar actual.
  Future<List<Map<String, dynamic>>> fetch(String table);
}

/// Gate PURO con estado que decide CUÁNDO intentar drenar la cola, para evitar
/// reintentos en bucle que spameen la red cuando seguimos sin cobertura.
///
/// Reglas (estilo `RealtimeNoticeGate`):
/// - Un intento FALLIDO abre una "ventana de espera" de [minRetryGapMs]: hasta
///   que pase ese tiempo no se vuelve a intentar (salvo que se fuerce).
/// - Un intento con ÉXITO rearma el gate: el siguiente disparo puede intentar
///   de inmediato.
/// - El reloj se inyecta (`nowMillis`) para poder testear sin esperar tiempo
///   real.
///
/// No toca red ni UI: solo responde "¿debo intentar ahora?".
class DrainGate {
  /// Separación mínima (ms) entre dos intentos tras un fallo. Evita martillear
  /// la red mientras seguimos offline.
  final int minRetryGapMs;

  /// Reloj inyectable (ms desde época). Por defecto el reloj real.
  final int Function() nowMillis;

  int _lastFailureAt = -1;

  DrainGate({this.minRetryGapMs = 5000, int Function()? nowMillis})
    : nowMillis = nowMillis ?? _defaultNow;

  static int _defaultNow() => DateTime.now().millisecondsSinceEpoch;

  /// Decide si debe intentarse un drenado AHORA. Si [force] es `true` (p. ej.
  /// un refresco manual de la usuaria) ignora la ventana de espera.
  bool shouldAttempt({bool force = false}) {
    if (force) return true;
    if (_lastFailureAt < 0) return true; // nunca ha fallado: adelante
    return nowMillis() - _lastFailureAt >= minRetryGapMs;
  }

  /// Registra el resultado del último intento. Un éxito rearma el gate; un
  /// fallo abre la ventana de espera desde ahora.
  void registerResult({required bool success}) {
    if (success) {
      _lastFailureAt = -1;
    } else {
      _lastFailureAt = nowMillis();
    }
  }

  /// Rearma el gate (equivale a "vuelve a estar bien"): el próximo disparo
  /// podrá intentar de inmediato.
  void reset() {
    _lastFailureAt = -1;
  }
}

/// Resultado de un intento de drenado, útil para que las pantallas sepan si
/// quedó algo pendiente (p. ej. para mostrar un indicador discreto).
class DrainResult {
  /// Operaciones enviadas con éxito en este intento.
  final int sent;

  /// `true` si se interrumpió por un fallo (se asume offline).
  final bool stoppedByFailure;

  /// Operaciones que siguen pendientes tras el intento.
  final int remaining;

  const DrainResult({
    required this.sent,
    required this.stoppedByFailure,
    required this.remaining,
  });
}

/// Repositorio offline-first para UNA tabla por hogar. Normalmente se crea uno
/// por tabla (p. ej. `shopping_list_items`, `inventory_items`) compartiendo el
/// mismo [LocalStore] y [RemoteSender].
class OfflineRepository {
  /// Tabla gestionada (p. ej. `shopping_list_items`).
  final String table;

  /// Persistencia inyectada (memoria en tests, disco en producción).
  final LocalStore store;

  /// Capa de red inyectada (Supabase en producción, fake en tests).
  final RemoteSender sender;

  /// Clave remota donde leer la marca temporal para el last-write-wins.
  final String remoteTimestampKey;

  /// Gate de reintentos (puro, testeable).
  final DrainGate gate;

  /// Hogar actual: namespacea TODAS las claves de caché y cola.
  String _homeId;

  /// Cola de sincronización en memoria (se persiste tras cada cambio).
  SyncQueue _queue = SyncQueue();

  bool _queueLoaded = false;

  OfflineRepository({
    required this.table,
    required this.store,
    required this.sender,
    required String homeId,
    this.remoteTimestampKey = kDefaultRemoteTimestampKey,
    DrainGate? gate,
  }) : _homeId = homeId,
       gate = gate ?? DrainGate();

  /// Hogar activo.
  String get homeId => _homeId;

  /// Número de operaciones pendientes de sincronizar (tras cargar la cola).
  int get pendingCount => _queue.length;

  /// Clave de caché de la lista remota, namespaced por hogar.
  String get _cacheKey => 'cache:$table:$_homeId';

  /// Clave de la cola de sincronización, namespaced por hogar. La cola es
  /// compartida por todas las tablas del mismo hogar, pero cada repositorio
  /// solo drena/mezcla las ops de SU tabla.
  String get _queueKey => 'queue:$_homeId';

  // --------------------------------------------------------------------------
  // Carga/persistencia de la cola
  // --------------------------------------------------------------------------

  Future<void> _ensureQueueLoaded() async {
    if (_queueLoaded) return;
    final raw = await store.read(_queueKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _queue = SyncQueue.fromJson(decoded);
        }
      } catch (_) {
        // Cola corrupta: empezamos limpio en lugar de romper el arranque.
        _queue = SyncQueue();
      }
    }
    _queueLoaded = true;
  }

  Future<void> _persistQueue() async {
    await store.write(_queueKey, jsonEncode(_queue.toJson()));
  }

  Future<void> _persistCache(List<Map<String, dynamic>> rows) async {
    await store.write(_cacheKey, jsonEncode(rows));
  }

  List<Map<String, dynamic>> _decodeRows(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    } catch (_) {
      // Caché corrupta: devolvemos vacío (la red la repondrá).
    }
    return [];
  }

  // --------------------------------------------------------------------------
  // API pública
  // --------------------------------------------------------------------------

  /// Lee la lista EFECTIVA desde la caché local, AL INSTANTE y SIN tocar la
  /// red, aplicando las ops pendientes para que lo que la usuaria cambió sin
  /// conexión siga visible. Pensada para pintar antes de que llegue el fetch.
  Future<List<Map<String, dynamic>>> readCached() async {
    await _ensureQueueLoaded();
    final remote = _decodeRows(await store.read(_cacheKey));
    return mergeRemoteWithPending(
      table: table,
      remote: remote,
      pending: _queue.pending,
      remoteTimestampKey: remoteTimestampKey,
    );
  }

  /// Refresca desde Supabase: hace fetch, guarda la lista remota en caché y
  /// devuelve la lista EFECTIVA mezclando las ops pendientes. Aprovecha que la
  /// red respondió para intentar drenar la cola (estamos "online"). Si el fetch
  /// falla (sin red), cae de vuelta a [readCached] para no romper la UI.
  Future<List<Map<String, dynamic>>> refreshFromRemote() async {
    await _ensureQueueLoaded();
    try {
      final remote = await sender.fetch(table);
      await _persistCache(remote);
      // El fetch funcionó: la red está disponible, aprovechamos para drenar.
      gate.reset();
      await _drainInternal();
      return mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: _queue.pending,
        remoteTimestampKey: remoteTimestampKey,
      );
    } catch (_) {
      // Sin conexión: devolvemos lo que haya en caché + pendientes.
      gate.registerResult(success: false);
      return readCached();
    }
  }

  /// Aplica un cambio local de forma OPTIMISTA: lo encola, persiste la cola,
  /// actualiza la caché efectiva en disco e intenta drenar en segundo plano.
  /// El cambio NO se pierde aunque no haya red: queda en la cola.
  Future<void> applyLocalWrite(PendingOp op) async {
    await _ensureQueueLoaded();
    _queue.enqueue(op);
    await _persistQueue();

    // Actualizamos la caché efectiva para que un readCached inmediato ya vea el
    // cambio (optimista) sin esperar a la red.
    final remote = _decodeRows(await store.read(_cacheKey));
    final effective = mergeRemoteWithPending(
      table: table,
      remote: remote,
      pending: _queue.pending,
      remoteTimestampKey: remoteTimestampKey,
    );
    await _persistCache(effective);

    // Intento de drenado en segundo plano (idempotente, respeta el gate).
    await tryDrain();
  }

  /// Intenta drenar la cola SOLO si el gate lo permite (idempotente: un intento
  /// por disparo, sin bucles). Las pantallas lo invocan en momentos naturales
  /// (refresco, evento Realtime, reconexión del canal, volver a primer plano).
  Future<DrainResult> tryDrain({bool force = false}) async {
    await _ensureQueueLoaded();
    if (!gate.shouldAttempt(force: force)) {
      return DrainResult(
        sent: 0,
        stoppedByFailure: false,
        remaining: _pendingForTable().length,
      );
    }
    return _drainInternal();
  }

  /// Drena la cola de ESTA tabla en orden FIFO. Envía cada op; si una tiene
  /// éxito la quita y persiste; si FALLA (sin red), DETIENE el drenado sin
  /// perder las restantes y marca el gate como "offline". Documentado como
  /// parada ante el primer fallo para no spamear reintentos.
  Future<DrainResult> _drainInternal() async {
    final ops = _pendingForTable();
    if (ops.isEmpty) {
      return const DrainResult(sent: 0, stoppedByFailure: false, remaining: 0);
    }

    var sent = 0;
    var stopped = false;

    for (final op in ops) {
      try {
        await _send(op);
        _queue.markSent(op);
        await _persistQueue();
        sent++;
      } catch (_) {
        // Primer fallo: asumimos offline y paramos (conservando el resto).
        stopped = true;
        gate.registerResult(success: false);
        break;
      }
    }

    if (!stopped) {
      // Todo lo de esta tabla salió: la red responde, rearmamos el gate.
      gate.registerResult(success: true);
    }

    return DrainResult(
      sent: sent,
      stoppedByFailure: stopped,
      remaining: _pendingForTable().length,
    );
  }

  /// Ops pendientes de ESTA tabla, en orden.
  List<PendingOp> _pendingForTable() =>
      _queue.pending.where((op) => op.table == table).toList();

  Future<void> _send(PendingOp op) async {
    switch (op.type) {
      case SyncOpType.insert:
        await sender.sendInsert(op.table, op.payload);
        break;
      case SyncOpType.update:
        await sender.sendUpdate(op.table, op.payload, op.id);
        break;
      case SyncOpType.delete:
        await sender.sendDelete(op.table, op.id);
        break;
      default:
        // Tipo desconocido: lo descartamos para no bloquear la cola.
        break;
    }
  }

  // --------------------------------------------------------------------------
  // Aislamiento por hogar
  // --------------------------------------------------------------------------

  /// Limpia la caché y la cola del hogar ACTUAL. Se invoca al CERRAR SESIÓN
  /// para que la caché local nunca arrastre datos de otro hogar
  /// (ver steering de seguridad).
  Future<void> clearForLogout() async {
    await store.remove(_cacheKey);
    await store.remove(_queueKey);
    _queue = SyncQueue();
    _queueLoaded = true;
    gate.reset();
  }

  /// Cambia de hogar: separa por completo la caché/cola del hogar anterior
  /// (borrándolas) y pasa a operar sobre [newHomeId] con estado limpio. Así los
  /// datos de dos hogares nunca se mezclan.
  Future<void> switchHome(String newHomeId) async {
    if (newHomeId == _homeId) return;
    // Borramos lo del hogar anterior antes de cambiar las claves.
    await store.remove(_cacheKey);
    await store.remove(_queueKey);
    _homeId = newHomeId;
    _queue = SyncQueue();
    _queueLoaded = false;
    gate.reset();
    await _ensureQueueLoaded();
  }
}
