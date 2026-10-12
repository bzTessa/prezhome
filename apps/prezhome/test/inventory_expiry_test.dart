import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';

/// Construye un InventoryItem mínimo para probar la lógica de caducidades.
/// Las fechas se pasan relativas a DateTime.now() desde cada test para que no
/// sean frágiles con el paso del tiempo.
InventoryItem _item({
  required String category,
  DateTime? expirationDate,
  DateTime? bestBefore,
  DateTime? frozenOn,
}) {
  return InventoryItem(
    id: 'id',
    homeId: 'home',
    name: 'producto',
    category: category,
    quantity: 1,
    unit: 'unidades',
    expirationDate: expirationDate,
    bestBefore: bestBefore,
    frozenOn: frozenOn,
  );
}

DateTime _daysFromNow(int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.add(Duration(days: days));
}

void main() {
  group('ExpiryStatus en Nevera/Despensa (expiration_date)', () {
    test('caducado cuando la fecha ya pasó', () {
      final item = _item(category: 'Nevera', expirationDate: _daysFromNow(-1));
      expect(item.expiryStatus, ExpiryStatus.caducado);
      expect(item.expiryLabel, 'Caducado');
    });

    test('pronto para hoy (0 días)', () {
      final item = _item(category: 'Despensa', expirationDate: _daysFromNow(0));
      expect(item.daysUntilExpiry, 0);
      expect(item.expiryStatus, ExpiryStatus.pronto);
      expect(item.expiryLabel, 'Caduca pronto');
    });

    test('pronto para mañana (1 día)', () {
      final item = _item(category: 'Nevera', expirationDate: _daysFromNow(1));
      expect(item.expiryStatus, ExpiryStatus.pronto);
    });

    test('pronto en el límite (3 días)', () {
      final item = _item(category: 'Despensa', expirationDate: _daysFromNow(3));
      expect(item.daysUntilExpiry, 3);
      expect(item.expiryStatus, ExpiryStatus.pronto);
    });

    test('fresco para futuro lejano (10 días)', () {
      final item = _item(category: 'Nevera', expirationDate: _daysFromNow(10));
      expect(item.expiryStatus, ExpiryStatus.fresco);
      expect(item.expiryLabel, 'Fresco');
    });

    test('sinFecha cuando no hay ninguna fecha', () {
      final item = _item(category: 'Despensa');
      expect(item.effectiveExpiry, isNull);
      expect(item.daysUntilExpiry, isNull);
      expect(item.expiryStatus, ExpiryStatus.sinFecha);
      expect(item.expiryLabel, 'Sin fecha');
    });

    test('cae a best_before cuando no hay expiration_date', () {
      final bb = _daysFromNow(5);
      final item = _item(category: 'Nevera', bestBefore: bb);
      expect(item.effectiveExpiry, bb);
      expect(item.expiryStatus, ExpiryStatus.fresco);
    });

    test('expiration_date tiene prioridad sobre best_before', () {
      final exp = _daysFromNow(2);
      final bb = _daysFromNow(20);
      final item = _item(
        category: 'Nevera',
        expirationDate: exp,
        bestBefore: bb,
      );
      expect(item.effectiveExpiry, exp);
      expect(item.expiryStatus, ExpiryStatus.pronto);
    });
  });

  group('ExpiryStatus en Congelador (best_before / frozen_on)', () {
    test('usa best_before cuando está definido', () {
      final bb = _daysFromNow(1);
      final item = _item(
        category: 'Congelador',
        bestBefore: bb,
        frozenOn: _daysFromNow(-5),
      );
      expect(item.effectiveExpiry, bb);
      expect(item.expiryStatus, ExpiryStatus.pronto);
    });

    test('cae a frozen_on + defaultFreezerDays cuando best_before es null', () {
      final frozen = _daysFromNow(-10);
      final item = _item(category: 'Congelador', frozenOn: frozen);
      final expected = frozen.add(
        const Duration(days: InventoryItem.defaultFreezerDays),
      );
      expect(item.effectiveExpiry, expected);
      // -10 + 90 = 80 días por delante => fresco.
      expect(item.expiryStatus, ExpiryStatus.fresco);
    });

    test('sinFecha cuando no hay best_before ni frozen_on', () {
      final item = _item(category: 'Congelador');
      expect(item.effectiveExpiry, isNull);
      expect(item.expiryStatus, ExpiryStatus.sinFecha);
    });

    test('congelado hace mucho (ventana agotada) está caducado', () {
      final frozen = _daysFromNow(-(InventoryItem.defaultFreezerDays + 5));
      final item = _item(category: 'Congelador', frozenOn: frozen);
      expect(item.expiryStatus, ExpiryStatus.caducado);
    });
  });

  group('daysUntilBestBefore sigue existiendo', () {
    test('se mantiene por compatibilidad', () {
      final bb = _daysFromNow(4);
      final item = _item(category: 'Nevera', bestBefore: bb);
      expect(item.daysUntilBestBefore, 4);
    });
  });
}
