/// Lógica PURA de presentación para la capa offline-first (Paso 7).
///
/// Vive aquí (sin Supabase ni Flutter) para poder testearla en la Dart VM:
/// - [shouldShowPendingIndicator]: decide si mostrar el indicador cozy de
///   "cambios por sincronizar" (solo cuando hay cola no vacía).
/// - Constructores de [PendingOp] para cada acción de las pantallas (tachar,
///   borrar, alta manual, staple...): centralizan QUÉ operación genera cada
///   gesto, de modo que el repositorio reciba siempre la op correcta y el test
///   pueda comprobarlo sin montar widgets.
///
/// El id de un INSERT hecho offline es un id TEMPORAL local (ver [newLocalId]):
/// la fila aún no existe en el servidor, así que generamos un id propio para
/// poder identificarla y colapsar updates/deletes posteriores en la cola.
library;

import '../services/sync_queue.dart';

/// Decide si debe mostrarse el indicador discreto de "cambios por sincronizar".
///
/// Regla simple y testable: se muestra SOLO cuando hay al menos una operación
/// pendiente en la cola. Al vaciarse la cola (drenado con éxito) desaparece.
bool shouldShowPendingIndicator(int pendingCount) => pendingCount > 0;

/// Prefijo de los ids temporales locales (inserts hechos sin conexión). Permite
/// distinguir de un vistazo una fila aún no confirmada por el servidor.
const String kLocalIdPrefix = 'local-';

/// Genera un id TEMPORAL local único para un insert offline. Usa el reloj y un
/// contador monótono inyectables para ser determinista en tests.
String newLocalId({required int nowMillis, required int seq}) =>
    '$kLocalIdPrefix$nowMillis-$seq';

/// `true` si [id] es un id temporal generado localmente (insert aún no
/// sincronizado), por oposición a un id real de Supabase.
bool isLocalId(String id) => id.startsWith(kLocalIdPrefix);

/// Construye la [PendingOp] de un INSERT optimista a [table] con [payload]
/// (que debe incluir ya el `id` temporal local). El payload se cachea tal cual
/// para que la UI lo pinte al instante.
PendingOp buildInsertOp({
  required String table,
  required String id,
  required Map<String, dynamic> payload,
  required int nowMillis,
  required int seq,
}) {
  return PendingOp(
    table: table,
    type: SyncOpType.insert,
    id: id,
    payload: payload,
    timestamp: nowMillis,
    seq: seq,
  );
}

/// Construye la [PendingOp] de un UPDATE optimista sobre la fila [id] de
/// [table], parcheando solo los campos de [changes].
PendingOp buildUpdateOp({
  required String table,
  required String id,
  required Map<String, dynamic> changes,
  required int nowMillis,
  required int seq,
}) {
  return PendingOp(
    table: table,
    type: SyncOpType.update,
    id: id,
    payload: changes,
    timestamp: nowMillis,
    seq: seq,
  );
}

/// Construye la [PendingOp] de un DELETE optimista de la fila [id] de [table].
PendingOp buildDeleteOp({
  required String table,
  required String id,
  required int nowMillis,
  required int seq,
}) {
  return PendingOp(
    table: table,
    type: SyncOpType.delete,
    id: id,
    payload: const {},
    timestamp: nowMillis,
    seq: seq,
  );
}
