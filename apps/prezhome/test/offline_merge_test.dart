import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/offline_merge.dart';
import 'package:prezhome/services/sync_queue.dart';

const String table = 'shopping_list_items';

PendingOp op(
  String type,
  String id, {
  Map<String, dynamic>? payload,
  int timestamp = 0,
  int seq = 0,
}) {
  return PendingOp(
    table: table,
    type: type,
    id: id,
    payload: payload,
    timestamp: timestamp,
    seq: seq,
  );
}

void main() {
  group('mergeRemoteWithPending: aplicar ops pendientes sobre el remoto', () {
    test('UPDATE pendiente parchea los campos de la fila remota', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'checked': false, 'updated_at': 100},
      ];
      final pending = [
        op(SyncOpType.update, 'a', payload: {'checked': true}, timestamp: 200),
      ];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      expect(merged.single['checked'], isTrue);
      expect(merged.single['name'], 'Pan');
    });

    test('DELETE pendiente oculta la fila remota', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'updated_at': 100},
        {'id': 'b', 'name': 'Leche', 'updated_at': 100},
      ];
      final pending = [op(SyncOpType.delete, 'a', timestamp: 200)];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      expect(merged.length, 1);
      expect(merged.single['id'], 'b');
    });

    test('INSERT offline sobrevive a un refresco remoto que no lo trae', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'updated_at': 100},
      ];
      final pending = [
        op(
          SyncOpType.insert,
          'tmp-1',
          payload: {'name': 'Huevos', 'checked': false},
          timestamp: 150,
        ),
      ];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      // El remoto 'a' sigue; el insert offline 'tmp-1' se añade al final.
      expect(merged.length, 2);
      expect(merged.first['id'], 'a');
      expect(merged.last['id'], 'tmp-1');
      expect(merged.last['name'], 'Huevos');
    });

    test('solo afecta a la tabla indicada', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'updated_at': 100},
      ];
      final pending = [
        PendingOp(
          table: 'inventory_items',
          type: SyncOpType.delete,
          id: 'a',
          timestamp: 200,
          seq: 0,
        ),
      ];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      // La op es de otra tabla, no debe borrar la fila de la lista de compra.
      expect(merged.length, 1);
    });
  });

  group('mergeRemoteWithPending: resolución last-write-wins por timestamp', () {
    test('la op local gana si es más nueva que el remoto', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'checked': false, 'updated_at': 100},
      ];
      final pending = [
        op(SyncOpType.update, 'a', payload: {'checked': true}, timestamp: 300),
      ];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      expect(merged.single['checked'], isTrue);
    });

    test('el remoto gana si es estrictamente más nuevo que la op local', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'checked': false, 'updated_at': 500},
      ];
      final pending = [
        op(SyncOpType.update, 'a', payload: {'checked': true}, timestamp: 300),
      ];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      // El remoto es más nuevo -> conserva checked:false.
      expect(merged.single['checked'], isFalse);
    });

    test('DELETE local se ignora si el remoto reescribió la fila después', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'updated_at': 500},
      ];
      final pending = [op(SyncOpType.delete, 'a', timestamp: 300)];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      // Remoto más nuevo que el delete -> la fila reaparece.
      expect(merged.length, 1);
      expect(merged.single['id'], 'a');
    });

    test('acepta timestamp remoto en formato ISO-8601', () {
      final remote = [
        {
          'id': 'a',
          'name': 'Pan',
          'checked': false,
          'updated_at': '2026-01-01T00:00:00.000Z',
        },
      ];
      final oldOp = DateTime.utc(2025, 1, 1).millisecondsSinceEpoch;
      final pending = [
        op(
          SyncOpType.update,
          'a',
          payload: {'checked': true},
          timestamp: oldOp,
        ),
      ];
      final merged = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      // El remoto (2026) es más nuevo que la op (2025) -> gana el remoto.
      expect(merged.single['checked'], isFalse);
    });
  });

  group('mergeRemoteWithPending: determinismo', () {
    test('mismo input produce mismo output y conserva orden del remoto', () {
      final remote = [
        {'id': 'a', 'name': 'Pan', 'updated_at': 100},
        {'id': 'b', 'name': 'Leche', 'updated_at': 100},
        {'id': 'c', 'name': 'Café', 'updated_at': 100},
      ];
      final pending = [
        op(
          SyncOpType.insert,
          'z',
          payload: {'name': 'Té'},
          timestamp: 150,
          seq: 2,
        ),
        op(
          SyncOpType.insert,
          'y',
          payload: {'name': 'Sal'},
          timestamp: 140,
          seq: 1,
        ),
      ];
      final first = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      final second = mergeRemoteWithPending(
        table: table,
        remote: remote,
        pending: pending,
      );
      final ids = first.map((r) => r['id']).toList();
      // Remoto en su orden; luego inserts offline en orden FIFO (y antes que z).
      expect(ids, ['a', 'b', 'c', 'y', 'z']);
      expect(
        first.map((r) => r['id']).toList(),
        second.map((r) => r['id']).toList(),
      );
    });
  });
}
