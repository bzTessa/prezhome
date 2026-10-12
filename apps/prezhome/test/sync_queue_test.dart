import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/local_store.dart';
import 'package:prezhome/services/sync_queue.dart';

// Helper para construir operaciones de forma concisa en los tests.
PendingOp op(
  String type,
  String id, {
  String table = 'shopping_list_items',
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
  group('PendingOp (modelo puro)', () {
    test('key agrupa por table + id', () {
      expect(op(SyncOpType.insert, 'a').key, 'shopping_list_items::a');
    });

    test('round-trip toJson/fromJson conserva los campos', () {
      final original = op(
        SyncOpType.update,
        'x',
        payload: {'checked': true, 'name': 'Leche'},
        timestamp: 123,
        seq: 7,
      );
      final back = PendingOp.fromJson(original.toJson());
      expect(back.table, original.table);
      expect(back.type, original.type);
      expect(back.id, original.id);
      expect(back.payload, original.payload);
      expect(back.timestamp, original.timestamp);
      expect(back.seq, original.seq);
    });

    test('fromJson es tolerante a campos ausentes', () {
      final back = PendingOp.fromJson({'id': 'z'});
      expect(back.id, 'z');
      expect(back.type, SyncOpType.update);
      expect(back.payload, isEmpty);
      expect(back.timestamp, 0);
    });
  });

  group('SyncQueue: orden FIFO estable', () {
    test('ordena por timestamp y desempata por seq', () {
      final q = SyncQueue();
      q.enqueue(op(SyncOpType.insert, 'a', timestamp: 20, seq: 2));
      q.enqueue(op(SyncOpType.insert, 'b', timestamp: 10, seq: 1));
      q.enqueue(op(SyncOpType.insert, 'c', timestamp: 10, seq: 0));

      final ids = q.drain().map((o) => o.id).toList();
      // timestamp 10 antes que 20; dentro de 10, seq 0 antes que seq 1.
      expect(ids, ['c', 'b', 'a']);
    });

    test('drain no vacía la cola; markSent sí la quita', () {
      final q = SyncQueue();
      final o = op(SyncOpType.insert, 'a', timestamp: 1, seq: 1);
      q.enqueue(o);
      expect(q.drain().length, 1);
      expect(q.length, 1); // drain no borra
      q.markSent(o);
      expect(q.length, 0);
    });
  });

  group('SyncQueue: colapso/dedup por (table,id)', () {
    test('(a) insert + update se funden en un único insert combinado', () {
      final q = SyncQueue();
      q.enqueue(
        op(
          SyncOpType.insert,
          'a',
          payload: {'name': 'Pan', 'checked': false},
          timestamp: 1,
          seq: 1,
        ),
      );
      q.enqueue(
        op(
          SyncOpType.update,
          'a',
          payload: {'checked': true},
          timestamp: 2,
          seq: 2,
        ),
      );

      expect(q.length, 1);
      final only = q.drain().single;
      expect(only.type, SyncOpType.insert);
      expect(only.payload, {'name': 'Pan', 'checked': true});
    });

    test('(b) insert-offline + delete elimina ambas (no se envía nada)', () {
      final q = SyncQueue();
      q.enqueue(op(SyncOpType.insert, 'a', timestamp: 1, seq: 1));
      q.enqueue(op(SyncOpType.delete, 'a', timestamp: 2, seq: 2));
      expect(q.isEmpty, isTrue);
      expect(q.drain(), isEmpty);
    });

    test('(c) delete sobre id de servidor colapsa updates previos', () {
      final q = SyncQueue();
      q.enqueue(
        op(
          SyncOpType.update,
          'a',
          payload: {'checked': true},
          timestamp: 1,
          seq: 1,
        ),
      );
      q.enqueue(op(SyncOpType.delete, 'a', timestamp: 2, seq: 2));
      expect(q.length, 1);
      expect(q.drain().single.type, SyncOpType.delete);
    });

    test('(d) updates consecutivos: last-write-wins por campo', () {
      final q = SyncQueue();
      q.enqueue(
        op(
          SyncOpType.update,
          'a',
          payload: {'name': 'Leche', 'quantity': 1},
          timestamp: 1,
          seq: 1,
        ),
      );
      q.enqueue(
        op(
          SyncOpType.update,
          'a',
          payload: {'quantity': 2, 'unit': 'litros'},
          timestamp: 2,
          seq: 2,
        ),
      );

      expect(q.length, 1);
      final merged = q.drain().single;
      expect(merged.type, SyncOpType.update);
      // name se conserva; quantity la pisa el update más reciente; unit se añade.
      expect(merged.payload, {
        'name': 'Leche',
        'quantity': 2,
        'unit': 'litros',
      });
    });

    test('ops sobre filas distintas NO se colapsan', () {
      final q = SyncQueue();
      q.enqueue(op(SyncOpType.insert, 'a', timestamp: 1, seq: 1));
      q.enqueue(op(SyncOpType.insert, 'b', timestamp: 2, seq: 2));
      expect(q.length, 2);
    });

    test('misma id en tablas distintas NO se colapsa', () {
      final q = SyncQueue();
      q.enqueue(op(SyncOpType.insert, 'a', table: 'shopping_list_items'));
      q.enqueue(op(SyncOpType.insert, 'a', table: 'inventory_items'));
      expect(q.length, 2);
    });
  });

  group('SyncQueue: serialización de toda la cola', () {
    test('round-trip toJson/fromJson preserva orden y contenido', () {
      final q = SyncQueue();
      q.enqueue(
        op(
          SyncOpType.insert,
          'a',
          payload: {'name': 'Pan'},
          timestamp: 5,
          seq: 1,
        ),
      );
      q.enqueue(op(SyncOpType.delete, 'b', timestamp: 1, seq: 2));

      final json = q.toJson();
      final restored = SyncQueue.fromJson(json);

      final ids = restored.drain().map((o) => o.id).toList();
      expect(ids, ['b', 'a']); // ordenado por timestamp
      expect(restored.length, 2);
      expect(restored.drain().last.payload, {'name': 'Pan'});
    });

    test('persistencia simulada vía InMemoryLocalStore', () async {
      final store = InMemoryLocalStore();
      final q = SyncQueue();
      q.enqueue(
        op(SyncOpType.insert, 'a', payload: {'name': 'Pan'}, timestamp: 1),
      );

      // Serializamos a String y lo guardamos como haría la capa de red.
      await store.write('queue', q.toJson().toString());
      final read = await store.read('queue');
      expect(read, contains('Pan'));
    });
  });
}
