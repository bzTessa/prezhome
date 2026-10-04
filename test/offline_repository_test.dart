import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/local_store.dart';
import 'package:prezhome/services/offline_repository.dart';
import 'package:prezhome/services/sync_queue.dart';

/// RemoteSender FALSO en memoria para tests PUROS (sin red ni Supabase).
///
/// - Guarda las filas de cada tabla (simula el servidor).
/// - Registra el orden EXACTO en que recibió las operaciones (`log`).
/// - Puede simular "sin cobertura" poniendo [online] a `false`: entonces
///   cualquier send*/fetch LANZA, igual que una llamada de red fallida.
class FakeRemoteSender implements RemoteSender {
  final Map<String, List<Map<String, dynamic>>> tables = {};
  final List<String> log = [];
  bool online = true;

  void _ensureOnline() {
    if (!online) throw 'sin conexión';
  }

  List<Map<String, dynamic>> _rows(String table) =>
      tables.putIfAbsent(table, () => []);

  @override
  Future<void> sendInsert(String table, Map<String, dynamic> payload) async {
    _ensureOnline();
    log.add('insert:$table:${payload['id']}');
    _rows(table).add(Map<String, dynamic>.from(payload));
  }

  @override
  Future<void> sendUpdate(
    String table,
    Map<String, dynamic> payload,
    String id,
  ) async {
    _ensureOnline();
    log.add('update:$table:$id');
    final rows = _rows(table);
    final idx = rows.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      rows[idx] = {...rows[idx], ...payload};
    }
  }

  @override
  Future<void> sendDelete(String table, String id) async {
    _ensureOnline();
    log.add('delete:$table:$id');
    _rows(table).removeWhere((r) => r['id'] == id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table) async {
    _ensureOnline();
    log.add('fetch:$table');
    return _rows(table).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

const String kTable = 'shopping_list_items';

PendingOp insertOp(String id, Map<String, dynamic> payload, int ts) =>
    PendingOp(
      table: kTable,
      type: SyncOpType.insert,
      id: id,
      payload: {'id': id, ...payload},
      timestamp: ts,
      seq: ts,
    );

PendingOp updateOp(String id, Map<String, dynamic> payload, int ts) =>
    PendingOp(
      table: kTable,
      type: SyncOpType.update,
      id: id,
      payload: payload,
      timestamp: ts,
      seq: ts,
    );

PendingOp deleteOp(String id, int ts) => PendingOp(
  table: kTable,
  type: SyncOpType.delete,
  id: id,
  timestamp: ts,
  seq: ts,
);

OfflineRepository buildRepo(
  InMemoryLocalStore store,
  RemoteSender sender, {
  String homeId = 'home-A',
}) {
  return OfflineRepository(
    table: kTable,
    store: store,
    sender: sender,
    homeId: homeId,
    // Gate con reloj controlado para que shouldAttempt sea determinista: con
    // minRetryGap 0 y un reloj fijo, cada tryDrain forzado o no reintenta ya.
    gate: DrainGate(minRetryGapMs: 0, nowMillis: () => 0),
  );
}

void main() {
  group('readCached (lectura instantánea sin red)', () {
    test('devuelve lo último persistido en caché sin tocar la red', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender();
      // Precargamos la caché del hogar A como si viniera de un fetch anterior.
      await store.write('cache:$kTable:home-A', '[{"id":"1","name":"Leche"}]');
      final repo = buildRepo(store, sender);

      final rows = await repo.readCached();

      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Leche');
      // No se tocó la red en absoluto.
      expect(sender.log, isEmpty);
    });

    test('aplica las ops pendientes sobre la caché (optimista)', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender();
      final repo = buildRepo(store, sender);

      // Simulamos offline para que el cambio quede en cola.
      sender.online = false;
      await repo.applyLocalWrite(insertOp('tmp-1', {'name': 'Pan'}, 100));

      final rows = await repo.readCached();
      expect(rows.map((r) => r['name']), contains('Pan'));
    });
  });

  group('applyLocalWrite offline (escritura optimista sin perder cambios)', () {
    test('estando offline encola y conserva el cambio', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender()..online = false;
      final repo = buildRepo(store, sender);

      await repo.applyLocalWrite(insertOp('tmp-1', {'name': 'Pan'}, 100));

      // La op NO se envió (sin red) pero sigue en la cola.
      expect(sender.log.where((l) => l.startsWith('insert')), isEmpty);
      expect(repo.pendingCount, 1);

      // Un repositorio nuevo sobre el MISMO store relee la cola persistida: el
      // cambio no se perdió aunque se "reinicie" la app.
      final repo2 = buildRepo(store, sender);
      final rows = await repo2.readCached();
      expect(rows.map((r) => r['name']), contains('Pan'));
      expect(repo2.pendingCount, 1);
    });
  });

  group('tryDrain al reconectar (envía en orden y vacía la cola)', () {
    test('al volver online envía las ops EN ORDEN y vacía la cola', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender()..online = false;
      final repo = buildRepo(store, sender);

      await repo.applyLocalWrite(insertOp('tmp-1', {'name': 'Pan'}, 100));
      await repo.applyLocalWrite(insertOp('tmp-2', {'name': 'Agua'}, 200));
      await repo.applyLocalWrite(
        updateOp('tmp-2', {'name': 'Agua con gas'}, 300),
      );

      expect(repo.pendingCount, 2); // insert+update de tmp-2 se colapsan

      // Vuelve la red.
      sender.online = true;
      final result = await repo.tryDrain();

      expect(result.stoppedByFailure, isFalse);
      expect(result.remaining, 0);
      expect(repo.pendingCount, 0);
      // El orden de envío respeta el FIFO por (timestamp, seq).
      expect(sender.log, ['insert:$kTable:tmp-1', 'insert:$kTable:tmp-2']);
      // El insert de tmp-2 ya lleva el nombre actualizado (colapso insert+update).
      final agua = sender.tables[kTable]!.firstWhere((r) => r['id'] == 'tmp-2');
      expect(agua['name'], 'Agua con gas');
    });

    test('tryDrain es idempotente: un segundo intento no reenvía', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender()..online = false;
      final repo = buildRepo(store, sender);
      await repo.applyLocalWrite(insertOp('tmp-1', {'name': 'Pan'}, 100));

      sender.online = true;
      await repo.tryDrain();
      final logLen = sender.log.length;
      await repo.tryDrain();
      expect(sender.log.length, logLen); // nada nuevo que enviar
    });
  });

  group('parada ante fallo a mitad (conserva las ops restantes)', () {
    test('si una op falla, el drenado se detiene y guarda el resto', () async {
      final store = InMemoryLocalStore();
      // Sender que falla a partir de la segunda operación de envío.
      final sender = _FlakyRemoteSender(failAfter: 1);
      final repo = buildRepo(store, sender);

      // Encolamos tres inserts estando OFFLINE (failAfter 0 -> todo lanza), de
      // modo que las ops quedan en la cola sin enviarse.
      sender.failAfter = 0;
      await repo.applyLocalWrite(insertOp('a', {'name': 'A'}, 100));
      await repo.applyLocalWrite(insertOp('b', {'name': 'B'}, 200));
      await repo.applyLocalWrite(insertOp('c', {'name': 'C'}, 300));
      expect(repo.pendingCount, 3);
      sender.sent.clear();

      // Ahora solo deja pasar 1 envío y falla en el segundo.
      sender.failAfter = 1;
      final result = await repo.tryDrain();

      expect(result.stoppedByFailure, isTrue);
      expect(result.sent, 1);
      // Se envió 'a'; 'b' y 'c' siguen pendientes (no se pierden).
      expect(sender.sent, ['a']);
      expect(result.remaining, 2);
      expect(repo.pendingCount, 2);
    });
  });

  group('refreshFromRemote (mezcla pendientes sobre el remoto)', () {
    test(
      'un insert offline sigue visible aunque el remoto no lo traiga',
      () async {
        final store = InMemoryLocalStore();
        final sender = FakeRemoteSender();
        // El servidor ya tiene una fila.
        sender.tables[kTable] = [
          {'id': 'srv-1', 'name': 'Leche', 'updated_at': 1},
        ];
        // Primer refresco con red: trae 'Leche' y la deja en caché.
        final repo = buildRepo(store, sender);
        await repo.refreshFromRemote();

        // La usuaria añade algo SIN cobertura: queda en la cola sin llegar al
        // servidor. Al refrescar de nuevo (seguimos offline en el fetch), el
        // insert pendiente debe seguir visible mezclado sobre la caché remota.
        sender.online = false;
        await repo.applyLocalWrite(insertOp('tmp-9', {'name': 'Pan'}, 500));

        final rows = await repo.refreshFromRemote();
        final names = rows.map((r) => r['name']).toList();
        expect(names, contains('Leche'));
        expect(names, contains('Pan'));
      },
    );

    test(
      'refreshFromRemote persiste el remoto en caché y drena pendientes',
      () async {
        final store = InMemoryLocalStore();
        final sender = FakeRemoteSender();
        sender.tables[kTable] = [
          {'id': 'srv-1', 'name': 'Leche', 'updated_at': 1},
        ];
        final repo = buildRepo(store, sender);

        // Op pendiente que debe drenarse al refrescar (hay red).
        sender.online = false;
        await repo.applyLocalWrite(insertOp('tmp-1', {'name': 'Pan'}, 100));
        sender.online = true;

        await repo.refreshFromRemote();

        // Se drenó la cola (se envió el insert) y quedó vacía.
        expect(repo.pendingCount, 0);
        expect(sender.log, contains('insert:$kTable:tmp-1'));
        // La caché local se actualizó con el remoto.
        final cached = await store.read('cache:$kTable:home-A');
        expect(cached, isNotNull);
      },
    );

    test('si el fetch falla (offline) cae a la caché local', () async {
      final store = InMemoryLocalStore();
      await store.write(
        'cache:$kTable:home-A',
        '[{"id":"srv-1","name":"Leche"}]',
      );
      final sender = FakeRemoteSender()..online = false;
      final repo = buildRepo(store, sender);

      final rows = await repo.refreshFromRemote();
      expect(rows.map((r) => r['name']), contains('Leche'));
    });
  });

  group('aislamiento por hogar (clearForLogout / switchHome)', () {
    test('clearForLogout borra caché y cola del hogar actual', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender()..online = false;
      final repo = buildRepo(store, sender);
      await repo.applyLocalWrite(insertOp('tmp-1', {'name': 'Pan'}, 100));

      expect(repo.pendingCount, 1);
      await repo.clearForLogout();

      expect(repo.pendingCount, 0);
      expect(await store.read('cache:$kTable:home-A'), isNull);
      expect(await store.read('queue:$kTable:home-A'), isNull);
      final rows = await repo.readCached();
      expect(rows, isEmpty);
    });

    test('switchHome deja el hogar nuevo sin datos del anterior', () async {
      final store = InMemoryLocalStore();
      final sender = FakeRemoteSender()..online = false;
      final repo = buildRepo(store, sender);

      // Datos del hogar A.
      await repo.applyLocalWrite(insertOp('tmp-A', {'name': 'Pan A'}, 100));
      expect(repo.pendingCount, 1);

      // Cambiamos al hogar B: no debe arrastrar nada de A.
      await repo.switchHome('home-B');
      expect(repo.homeId, 'home-B');
      expect(repo.pendingCount, 0);
      final rowsB = await repo.readCached();
      expect(rowsB, isEmpty);

      // Y la caché/cola del hogar A quedó eliminada (no se mezclan hogares).
      expect(await store.read('cache:$kTable:home-A'), isNull);
      expect(await store.read('queue:$kTable:home-A'), isNull);
    });
  });

  group('durabilidad de la cola con DOS repos sobre el MISMO store', () {
    // Reproduce el issue 1 de la revisión: shopping e inventory comparten
    // LocalStore; si usaran la misma clave de cola en disco, una escritura en
    // un repo pisaría las ops pendientes del otro y se perderían al reiniciar
    // la app. Con claves namespaced por tabla (queue:<table>:<homeId>) cada
    // cola es independiente en disco y NINGUNA op se pierde.
    OfflineRepository buildTableRepo(
      String table,
      InMemoryLocalStore store,
      RemoteSender sender,
    ) {
      return OfflineRepository(
        table: table,
        store: store,
        sender: sender,
        homeId: 'home-A',
        gate: DrainGate(minRetryGapMs: 0, nowMillis: () => 0),
      );
    }

    test(
      'encolar en ambos repos no pierde ninguna op en disco al reiniciar',
      () async {
        const shoppingTable = 'shopping_list_items';
        const inventoryTable = 'inventory_items';
        final store = InMemoryLocalStore();
        final sender = FakeRemoteSender()..online = false;

        final shopping = buildTableRepo(shoppingTable, store, sender);
        final inventory = buildTableRepo(inventoryTable, store, sender);

        // Ambos cargan la cola (una vez) y luego cada uno encola una op
        // ESTANDO OFFLINE: queda en la cola en disco sin enviarse.
        await shopping.applyLocalWrite(
          PendingOp(
            table: shoppingTable,
            type: SyncOpType.insert,
            id: 'tmp-S',
            payload: {'id': 'tmp-S', 'name': 'Pan'},
            timestamp: 100,
            seq: 100,
          ),
        );
        await inventory.applyLocalWrite(
          PendingOp(
            table: inventoryTable,
            type: SyncOpType.insert,
            id: 'tmp-I',
            payload: {'id': 'tmp-I', 'name': 'Leche'},
            timestamp: 200,
            seq: 200,
          ),
        );

        // Simulamos un REINICIO de la app: repos nuevos sobre el MISMO store.
        // Cada uno debe recuperar SU op de disco; ninguna se perdió.
        final shopping2 = buildTableRepo(shoppingTable, store, sender);
        final inventory2 = buildTableRepo(inventoryTable, store, sender);

        final shopRows = await shopping2.readCached();
        final invRows = await inventory2.readCached();

        expect(
          shopRows.map((r) => r['name']),
          contains('Pan'),
          reason: 'la op de la compra sobrevive al reinicio',
        );
        expect(
          invRows.map((r) => r['name']),
          contains('Leche'),
          reason: 'la op del inventario sobrevive al reinicio',
        );
        expect(shopping2.pendingCount, 1);
        expect(inventory2.pendingCount, 1);
      },
    );
  });

  group('estado efectivo tras un drenado con éxito (ventana del issue 2)', () {
    test(
      'un insert recién drenado sigue visible y un delete no reaparece',
      () async {
        final store = InMemoryLocalStore();
        final sender = FakeRemoteSender();
        // El servidor arranca con una fila que luego borraremos offline.
        sender.tables[kTable] = [
          {'id': 'srv-del', 'name': 'A borrar', 'updated_at': 1},
        ];
        final repo = buildRepo(store, sender);
        // Primer refresco con red: deja 'A borrar' en caché.
        await repo.refreshFromRemote();

        // SIN cobertura: insertamos una fila nueva y borramos la existente.
        sender.online = false;
        await repo.applyLocalWrite(insertOp('tmp-new', {'name': 'Nuevo'}, 500));
        await repo.applyLocalWrite(deleteOp('srv-del', 600));
        expect(repo.pendingCount, 2);

        // Vuelve la red: refreshFromRemote drena AMBAS ops y debe devolver el
        // estado efectivo YA sincronizado (sin ventana de inconsistencia).
        sender.online = true;
        final rows = await repo.refreshFromRemote();
        final names = rows.map((r) => r['name']).toList();

        // La cola quedó vacía (todo drenado).
        expect(repo.pendingCount, 0);
        // El insert drenado sigue visible (no desaparece).
        expect(names, contains('Nuevo'));
        // El delete drenado NO reaparece.
        expect(names, isNot(contains('A borrar')));
      },
    );

    test(
      'readCached inmediato tras refreshFromRemote refleja lo drenado',
      () async {
        final store = InMemoryLocalStore();
        final sender = FakeRemoteSender();
        final repo = buildRepo(store, sender);
        await repo.refreshFromRemote();

        sender.online = false;
        await repo.applyLocalWrite(insertOp('tmp-x', {'name': 'Café'}, 700));
        sender.online = true;
        await repo.refreshFromRemote();

        // La caché persistida ya incluye lo drenado: una lectura instantánea
        // (sin red) desde otro repo "reiniciado" lo ve sin cola pendiente.
        final repo2 = buildRepo(store, sender);
        final rows = await repo2.readCached();
        expect(rows.map((r) => r['name']), contains('Café'));
        expect(repo2.pendingCount, 0);
      },
    );
  });

  group('DrainGate (gate puro de reintentos)', () {
    test('tras un fallo no reintenta hasta pasar la ventana', () {
      var now = 1000;
      final gate = DrainGate(minRetryGapMs: 5000, nowMillis: () => now);

      expect(gate.shouldAttempt(), isTrue); // primera vez
      gate.registerResult(success: false);
      expect(gate.shouldAttempt(), isFalse); // dentro de la ventana
      now += 5000;
      expect(gate.shouldAttempt(), isTrue); // pasó la ventana
    });

    test('force ignora la ventana de espera', () {
      final gate = DrainGate(minRetryGapMs: 5000, nowMillis: () => 0);
      gate.registerResult(success: false);
      expect(gate.shouldAttempt(), isFalse);
      expect(gate.shouldAttempt(force: true), isTrue);
    });

    test('un éxito rearma el gate', () {
      var now = 0;
      final gate = DrainGate(minRetryGapMs: 5000, nowMillis: () => now);
      gate.registerResult(success: false);
      expect(gate.shouldAttempt(), isFalse);
      gate.registerResult(success: true);
      expect(gate.shouldAttempt(), isTrue);
    });
  });
}

/// Sender que deja pasar [failAfter] envíos y luego LANZA, para probar la
/// parada ante fallo a mitad del drenado. `fetch` siempre funciona.
class _FlakyRemoteSender implements RemoteSender {
  int failAfter;
  final List<String> sent = [];

  _FlakyRemoteSender({required this.failAfter});

  void _tick() {
    if (sent.length >= failAfter) throw 'sin conexión';
  }

  @override
  Future<void> sendInsert(String table, Map<String, dynamic> payload) async {
    _tick();
    sent.add(payload['id'] as String);
  }

  @override
  Future<void> sendUpdate(
    String table,
    Map<String, dynamic> payload,
    String id,
  ) async {
    _tick();
    sent.add(id);
  }

  @override
  Future<void> sendDelete(String table, String id) async {
    _tick();
    sent.add(id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table) async => [];
}
