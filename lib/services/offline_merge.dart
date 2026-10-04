/// Merge PURO caché<->remoto para la arquitectura offline-first (Paso 7).
///
/// Cuando llega un refresco remoto de Supabase (p. ej. tras recuperar la red o
/// por un evento Realtime), ese remoto puede NO incluir todavía los cambios que
/// la usuaria hizo sin conexión y que siguen en la cola de sincronización. Si
/// pintáramos el remoto tal cual, esos cambios "desaparecerían" ante sus ojos.
///
/// [mergeRemoteWithPending] resuelve esto: aplica las operaciones pendientes
/// ([PendingOp]) SOBRE la lista remota para producir la lista EFECTIVA que debe
/// ver la UI, de forma optimista:
/// - INSERT pendiente -> añade (o repone) la fila optimista.
/// - UPDATE pendiente -> parchea los campos tocados sobre la fila remota.
/// - DELETE pendiente -> oculta la fila (no aparece en el resultado).
///
/// Resolución de conflictos LAST-WRITE-WINS por `timestamp`: la fila remota
/// expone cuándo se escribió por última vez (vía la clave [remoteTimestampKey],
/// p. ej. `updated_at`/`created_at`); si la op local es MÁS NUEVA, la op gana en
/// los campos que tocó; si el remoto es más nuevo, se respeta el remoto. Un
/// DELETE local se respeta salvo que el remoto sea estrictamente más nuevo que
/// el delete (señal de que el servidor ya reescribió esa fila después).
///
/// Es Dart PURO (sin Supabase ni Flutter) y DETERMINISTA: trabaja con filas
/// crudas `Map<String, dynamic>` para no acoplarse a los modelos.
library;

import 'sync_queue.dart';

/// Clave por defecto donde la fila remota declara su última escritura.
/// Si no existe en la fila, se interpreta como "sin marca" (timestamp 0), de
/// modo que la op local, que siempre lleva timestamp, tiende a ganar.
const String kDefaultRemoteTimestampKey = 'updated_at';

/// Extrae el id lógico de una fila cruda. Por convención la columna es `id`.
String? _rowId(Map<String, dynamic> row) {
  final value = row['id'];
  return value?.toString();
}

/// Convierte la marca temporal remota a milisegundos desde época.
/// Acepta int (millis), String ISO-8601 o DateTime. Si no se puede leer,
/// devuelve 0 (equivale a "muy antiguo", así la op local gana).
int _remoteMillis(Map<String, dynamic> row, String key) {
  final raw = row[key];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is DateTime) return raw.millisecondsSinceEpoch;
  if (raw is String && raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.millisecondsSinceEpoch;
  }
  return 0;
}

/// Produce la lista EFECTIVA aplicando [pending] sobre [remote] para la tabla
/// [table]. Determinista: conserva el orden del remoto y añade al final, en
/// orden FIFO de la cola, las filas que SOLO existen localmente (inserts
/// offline todavía no presentes en el remoto).
///
/// [remoteTimestampKey] indica dónde lee la marca temporal del remoto para el
/// last-write-wins (por defecto [kDefaultRemoteTimestampKey]).
List<Map<String, dynamic>> mergeRemoteWithPending({
  required String table,
  required List<Map<String, dynamic>> remote,
  required List<PendingOp> pending,
  String remoteTimestampKey = kDefaultRemoteTimestampKey,
}) {
  // Solo nos interesan las ops de esta tabla, en orden FIFO estable.
  final ops = pending.where((op) => op.table == table).toList()
    ..sort((a, b) {
      final byTime = a.timestamp.compareTo(b.timestamp);
      if (byTime != 0) return byTime;
      return a.seq.compareTo(b.seq);
    });

  // Indexamos las ops por id de fila (la cola ya está colapsada: como mucho una
  // op efectiva por fila, pero recorremos por si hubiera varias históricas).
  final opById = <String, PendingOp>{};
  for (final op in ops) {
    opById[op.id] = op;
  }

  final result = <Map<String, dynamic>>[];
  final consumed = <String>{};

  // 1) Recorremos el remoto en su orden y aplicamos la op pendiente (si la hay)
  //    sobre cada fila.
  for (final row in remote) {
    final id = _rowId(row);
    if (id == null) {
      result.add(Map<String, dynamic>.from(row));
      continue;
    }
    final op = opById[id];
    if (op == null) {
      result.add(Map<String, dynamic>.from(row));
      continue;
    }
    consumed.add(id);

    final remoteMillis = _remoteMillis(row, remoteTimestampKey);

    switch (op.type) {
      case SyncOpType.delete:
        // El delete local se respeta salvo que el remoto sea ESTRICTAMENTE más
        // nuevo que el delete (el servidor reescribió la fila después).
        if (remoteMillis > op.timestamp) {
          result.add(Map<String, dynamic>.from(row));
        }
        // En otro caso ocultamos la fila (no se añade).
        break;

      case SyncOpType.update:
      case SyncOpType.insert:
        if (remoteMillis > op.timestamp) {
          // El remoto es más nuevo: gana el remoto tal cual.
          result.add(Map<String, dynamic>.from(row));
        } else {
          // La op local es igual o más nueva: parchea los campos que tocó.
          final merged = Map<String, dynamic>.from(row)..addAll(op.payload);
          result.add(merged);
        }
        break;

      default:
        result.add(Map<String, dynamic>.from(row));
    }
  }

  // 2) Añadimos las filas que SOLO existen localmente (inserts/updates offline
  //    cuyo id aún no está en el remoto), en orden FIFO, para que un cambio sin
  //    conexión no desaparezca ante un refresco remoto que todavía no lo trae.
  for (final op in ops) {
    if (consumed.contains(op.id)) continue;
    if (op.type == SyncOpType.delete) continue; // nada que borrar en el remoto
    final row = <String, dynamic>{'id': op.id, ...op.payload};
    result.add(row);
    consumed.add(op.id);
  }

  return result;
}
