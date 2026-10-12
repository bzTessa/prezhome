/// Cola de sincronización PURA para la arquitectura offline-first (Paso 7).
///
/// Cuando la usuaria cambia la lista de la compra o la despensa SIN conexión,
/// no podemos escribir en Supabase todavía. En su lugar encolamos una
/// "operación pendiente" ([PendingOp]) y la enviamos en segundo plano en cuanto
/// vuelve la red. Esta cola:
/// - mantiene un ORDEN FIFO estable por (timestamp, seq);
/// - COLAPSA/DEDUPLICA operaciones sobre la misma fila (misma table + id) para
///   no mandar trabajo redundante ni, peor, operaciones contradictorias;
/// - se serializa a JSON para persistirse vía `LocalStore` entre arranques.
///
/// Es Dart PURO: NO importa `package:supabase_flutter` ni
/// `package:flutter/material.dart`. El envío real a la red lo hará una capa
/// superior en una feature posterior, consumiendo [drain] y confirmando con
/// [markSent].
library;

/// Tipos de operación que soporta la cola. Mapean 1:1 con las escrituras que
/// hacen las pantallas (insert/update/delete) sobre las tablas de Supabase.
class SyncOpType {
  SyncOpType._();

  /// Alta de una fila nueva (p. ej. añadir un producto a la compra).
  static const String insert = 'insert';

  /// Modificación de una fila existente (p. ej. tachar un producto).
  static const String update = 'update';

  /// Borrado de una fila (p. ej. quitar un producto de la lista).
  static const String delete = 'delete';
}

/// Operación pendiente de sincronizar con Supabase. Representa UN cambio
/// local todavía no confirmado por el servidor.
class PendingOp {
  /// Tabla destino, p. ej. `shopping_list_items` o `inventory_items`.
  final String table;

  /// Tipo de operación: [SyncOpType.insert] | [SyncOpType.update] |
  /// [SyncOpType.delete].
  final String type;

  /// Id LÓGICO de la fila afectada. Para un insert hecho offline (la fila aún
  /// no existe en el servidor) se usa un id temporal/UUID generado localmente,
  /// de forma que updates/deletes posteriores sobre esa misma fila puedan
  /// identificarse y colapsarse antes de llegar a la red.
  final String id;

  /// Datos de la operación (columnas a insertar/actualizar). Para un delete
  /// suele ir vacío.
  final Map<String, dynamic> payload;

  /// Marca temporal del cambio en milisegundos desde época. Base de la
  /// resolución de conflictos last-write-wins y del orden FIFO.
  final int timestamp;

  /// Contador monótono para desempatar de forma ESTABLE operaciones con el
  /// mismo [timestamp] (dos cambios en el mismo milisegundo conservan el orden
  /// en que se encolaron).
  final int seq;

  PendingOp({
    required this.table,
    required this.type,
    required this.id,
    Map<String, dynamic>? payload,
    required this.timestamp,
    required this.seq,
  }) : payload = payload ?? <String, dynamic>{};

  /// Clave de agrupación para colapso/dedup: dos ops con la misma clave actúan
  /// sobre la MISMA fila.
  String get key => '$table::$id';

  /// Copia con algunos campos sustituidos (inmutable: no mutamos en sitio).
  PendingOp copyWith({
    String? type,
    Map<String, dynamic>? payload,
    int? timestamp,
    int? seq,
  }) {
    return PendingOp(
      table: table,
      type: type ?? this.type,
      id: id,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      seq: seq ?? this.seq,
    );
  }

  /// Serialización a JSON (para persistir la cola vía LocalStore).
  Map<String, dynamic> toJson() {
    return {
      'table': table,
      'type': type,
      'id': id,
      'payload': payload,
      'timestamp': timestamp,
      'seq': seq,
    };
  }

  /// Lectura TOLERANTE desde JSON: si falta un campo usamos valores por
  /// defecto razonables para no romper el arranque al releer una caché vieja.
  factory PendingOp.fromJson(Map<String, dynamic> json) {
    return PendingOp(
      table: (json['table'] ?? '') as String,
      type: (json['type'] ?? SyncOpType.update) as String,
      id: (json['id'] ?? '') as String,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Cola de operaciones pendientes con colapso/dedup y orden FIFO estable.
///
/// Reglas de colapso al [enqueue] una op nueva sobre una fila (misma `key`)
/// que ya tiene operaciones pendientes:
/// - (a) INSERT + UPDATE  -> se funde en un único INSERT con el payload
///   combinado (el insert "absorbe" los campos del update: la fila aún no
///   existe en servidor, así que basta con mandar un insert ya actualizado).
/// - (b) INSERT-offline + DELETE -> se ELIMINAN AMBAS: la fila nunca llegó al
///   servidor, así que no hay nada que enviar.
/// - (c) DELETE sobre una fila que SÍ existe en servidor (sin insert pendiente)
///   -> colapsa cualquier update previo y queda SOLO el delete.
/// - (d) UPDATE + UPDATE -> se funden (merge de payload, last-write-wins por
///   campo: el update más reciente pisa los campos que toca).
/// - (e) DELETE + INSERT (reaparición del mismo id) -> se trata como un UPDATE
///   del delete pendiente, dejando una sola op que refleja el estado final.
///
/// El orden de salida siempre es FIFO estable ordenado por (timestamp, seq).
class SyncQueue {
  final List<PendingOp> _ops = [];

  /// Vista inmutable de las operaciones pendientes, ya ordenadas.
  List<PendingOp> get pending => List.unmodifiable(_sorted());

  /// Número de operaciones pendientes.
  int get length => _ops.length;

  /// `true` si no hay nada pendiente de sincronizar.
  bool get isEmpty => _ops.isEmpty;

  List<PendingOp> _sorted() {
    final copy = List<PendingOp>.from(_ops);
    copy.sort((a, b) {
      final byTime = a.timestamp.compareTo(b.timestamp);
      if (byTime != 0) return byTime;
      return a.seq.compareTo(b.seq);
    });
    return copy;
  }

  int _indexOfKey(String key) => _ops.indexWhere((op) => op.key == key);

  /// Encola [op] aplicando las reglas de colapso/dedup documentadas arriba.
  void enqueue(PendingOp op) {
    final existingIndex = _indexOfKey(op.key);

    // No hay nada previo sobre esta fila: simplemente la añadimos.
    if (existingIndex == -1) {
      _ops.add(op);
      return;
    }

    final existing = _ops[existingIndex];

    switch (op.type) {
      case SyncOpType.delete:
        if (existing.type == SyncOpType.insert) {
          // (b) insert-offline + delete: la fila nunca existió en servidor.
          _ops.removeAt(existingIndex);
          return;
        }
        // (c) delete gana sobre update(s) previos de una fila ya en servidor.
        _ops[existingIndex] = op.copyWith(seq: existing.seq);
        return;

      case SyncOpType.update:
        if (existing.type == SyncOpType.insert) {
          // (a) insert + update -> insert con payload combinado.
          _ops[existingIndex] = existing.copyWith(
            payload: _mergePayload(existing.payload, op.payload),
            timestamp: op.timestamp,
          );
          return;
        }
        if (existing.type == SyncOpType.delete) {
          // Update sobre un delete pendiente: la fila se va a borrar; el update
          // no aporta nada, mantenemos el delete.
          return;
        }
        // (d) update + update -> merge last-write-wins por campo.
        _ops[existingIndex] = existing.copyWith(
          payload: _mergePayload(existing.payload, op.payload),
          timestamp: op.timestamp,
        );
        return;

      case SyncOpType.insert:
        if (existing.type == SyncOpType.delete) {
          // (e) delete + insert (reaparición): dejamos un insert con el nuevo
          // payload, conservando la posición original en la cola.
          _ops[existingIndex] = op.copyWith(seq: existing.seq);
          return;
        }
        // Insert sobre insert/update: reemplazamos por el insert más reciente
        // con payload combinado (idempotente).
        _ops[existingIndex] = op.copyWith(
          payload: _mergePayload(existing.payload, op.payload),
          seq: existing.seq,
        );
        return;

      default:
        // Tipo desconocido: lo tratamos como reemplazo conservando la posición.
        _ops[existingIndex] = op.copyWith(seq: existing.seq);
        return;
    }
  }

  /// Combina dos payloads: los campos de [next] pisan los de [base]
  /// (last-write-wins por campo).
  Map<String, dynamic> _mergePayload(
    Map<String, dynamic> base,
    Map<String, dynamic> next,
  ) {
    return {...base, ...next};
  }

  /// Devuelve las operaciones pendientes en ORDEN para enviarlas a Supabase.
  /// No las elimina: quien envía confirma cada una con [markSent].
  List<PendingOp> drain() => _sorted();

  /// Quita de la cola la operación con la clave (table::id) indicada, p. ej.
  /// cuando su envío a Supabase ha tenido éxito.
  void removeByKey(String key) {
    _ops.removeWhere((op) => op.key == key);
  }

  /// Alias semántico de [removeByKey]: marca como enviada (y por tanto elimina)
  /// la operación [op] tras confirmarse en el servidor.
  void markSent(PendingOp op) => removeByKey(op.key);

  /// Vacía la cola por completo (p. ej. al cerrar sesión o cambiar de hogar).
  void clear() => _ops.clear();

  /// Serializa toda la cola a una lista JSON (para persistir vía LocalStore).
  List<Map<String, dynamic>> toJson() =>
      _sorted().map((op) => op.toJson()).toList();

  /// Reconstruye una cola desde su JSON. Tolerante: ignora entradas no válidas.
  factory SyncQueue.fromJson(List<dynamic> json) {
    final queue = SyncQueue();
    for (final raw in json) {
      if (raw is Map) {
        queue._ops.add(PendingOp.fromJson(raw.cast<String, dynamic>()));
      }
    }
    return queue;
  }

  SyncQueue();
}
