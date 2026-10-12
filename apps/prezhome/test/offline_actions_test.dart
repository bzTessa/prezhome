import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/sync_queue.dart';
import 'package:prezhome/utils/offline_actions.dart';

void main() {
  group('shouldShowPendingIndicator (función pura)', () {
    test('sin pendientes NO se muestra', () {
      expect(shouldShowPendingIndicator(0), isFalse);
    });

    test('con uno o más pendientes SÍ se muestra', () {
      expect(shouldShowPendingIndicator(1), isTrue);
      expect(shouldShowPendingIndicator(7), isTrue);
    });

    test('un conteo negativo (defensivo) NO se muestra', () {
      expect(shouldShowPendingIndicator(-1), isFalse);
    });
  });

  group('newLocalId / isLocalId', () {
    test('genera un id con el prefijo local y es reconocible', () {
      final id = newLocalId(nowMillis: 1700000000000, seq: 3);
      expect(id.startsWith(kLocalIdPrefix), isTrue);
      expect(isLocalId(id), isTrue);
    });

    test('ids con distinto seq son distintos (desempate estable)', () {
      final a = newLocalId(nowMillis: 1700000000000, seq: 1);
      final b = newLocalId(nowMillis: 1700000000000, seq: 2);
      expect(a == b, isFalse);
    });

    test('un id real de Supabase NO se confunde con uno local', () {
      expect(isLocalId('b3f1c2d4-0000-1111-2222-333344445555'), isFalse);
    });
  });

  group('builders de PendingOp (qué op genera cada acción)', () {
    test('buildInsertOp produce un insert con el payload tal cual', () {
      final op = buildInsertOp(
        table: 'shopping_list_items',
        id: 'local-1-0',
        payload: {'name': 'Tomates', 'checked': false},
        nowMillis: 1700000000000,
        seq: 0,
      );
      expect(op.type, SyncOpType.insert);
      expect(op.table, 'shopping_list_items');
      expect(op.id, 'local-1-0');
      expect(op.payload['name'], 'Tomates');
      expect(op.timestamp, 1700000000000);
      expect(op.seq, 0);
    });

    test(
      'buildUpdateOp produce un update que parchea solo los campos dados',
      () {
        final op = buildUpdateOp(
          table: 'shopping_list_items',
          id: 'abc',
          changes: {'checked': true},
          nowMillis: 1700000000001,
          seq: 1,
        );
        expect(op.type, SyncOpType.update);
        expect(op.id, 'abc');
        expect(op.payload, {'checked': true});
      },
    );

    test('buildDeleteOp produce un delete con payload vacío', () {
      final op = buildDeleteOp(
        table: 'inventory_items',
        id: 'xyz',
        nowMillis: 1700000000002,
        seq: 2,
      );
      expect(op.type, SyncOpType.delete);
      expect(op.table, 'inventory_items');
      expect(op.id, 'xyz');
      expect(op.payload, isEmpty);
    });

    test(
      'insert local seguido de delete sobre el mismo id se cancela en la cola',
      () {
        // Simula un alta offline y su posterior borrado antes de sincronizar:
        // la cola debe quedar vacía (no se envía nada al servidor).
        final queue = SyncQueue();
        final localId = newLocalId(nowMillis: 1700000000000, seq: 0);
        queue.enqueue(
          buildInsertOp(
            table: 'shopping_list_items',
            id: localId,
            payload: {'name': 'Pan'},
            nowMillis: 1700000000000,
            seq: 0,
          ),
        );
        queue.enqueue(
          buildDeleteOp(
            table: 'shopping_list_items',
            id: localId,
            nowMillis: 1700000000005,
            seq: 1,
          ),
        );
        expect(queue.isEmpty, isTrue);
      },
    );

    test('insert local + update del checked se funde en un solo insert', () {
      final queue = SyncQueue();
      final localId = newLocalId(nowMillis: 1700000000000, seq: 0);
      queue.enqueue(
        buildInsertOp(
          table: 'shopping_list_items',
          id: localId,
          payload: {'name': 'Leche', 'checked': false},
          nowMillis: 1700000000000,
          seq: 0,
        ),
      );
      queue.enqueue(
        buildUpdateOp(
          table: 'shopping_list_items',
          id: localId,
          changes: {'checked': true},
          nowMillis: 1700000000010,
          seq: 1,
        ),
      );
      final pending = queue.pending;
      expect(pending.length, 1);
      expect(pending.first.type, SyncOpType.insert);
      expect(pending.first.payload['checked'], true);
      expect(pending.first.payload['name'], 'Leche');
    });
  });
}
