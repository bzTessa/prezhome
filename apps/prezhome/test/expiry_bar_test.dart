import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/utils/expiry_bar.dart';

/// Construye un InventoryItem mínimo para probar la barra de caducidad a partir
/// de un item real. Las fechas se pasan relativas a DateTime.now() desde cada
/// test para que no sean frágiles con el paso del tiempo (mismo patrón que
/// test/inventory_expiry_test.dart).
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
  group('expiryBarFraction: bordes por estado', () {
    test('sinFecha -> 0.0', () {
      expect(expiryBarFraction(ExpiryStatus.sinFecha, null), 0.0);
      // Aunque llegaran días, sinFecha siempre es 0.
      expect(expiryBarFraction(ExpiryStatus.sinFecha, 5), 0.0);
    });

    test('caducado -> 1.0 (barra llena de alarma)', () {
      expect(expiryBarFraction(ExpiryStatus.caducado, -1), 1.0);
      expect(expiryBarFraction(ExpiryStatus.caducado, -30), 1.0);
    });

    test('pronto hoy (0 días) -> fracción pequeña > 0', () {
      final hoy = expiryBarFraction(ExpiryStatus.pronto, 0);
      expect(hoy, greaterThan(0.0));
      expect(hoy, kProntoMinFraction);
      // Casi vacía pero visible.
      expect(hoy, lessThan(0.5));
    });

    test('pronto: no decreciente de 0 a 3 días', () {
      final d0 = expiryBarFraction(ExpiryStatus.pronto, 0);
      final d1 = expiryBarFraction(ExpiryStatus.pronto, 1);
      final d2 = expiryBarFraction(ExpiryStatus.pronto, 2);
      final d3 = expiryBarFraction(ExpiryStatus.pronto, 3);
      expect(d0, lessThanOrEqualTo(d1));
      expect(d1, lessThanOrEqualTo(d2));
      expect(d2, lessThanOrEqualTo(d3));
      // Y pronto hoy <= pronto a 3 días.
      expect(d0, lessThanOrEqualTo(d3));
    });

    test('fresco cerca del límite de la ventana -> ~1 y nunca > 1', () {
      final cerca = expiryBarFraction(
        ExpiryStatus.fresco,
        kFreshWindowDays - 1,
      );
      expect(cerca, lessThanOrEqualTo(1.0));
      expect(cerca, greaterThan(0.8));
      final enLimite = expiryBarFraction(ExpiryStatus.fresco, kFreshWindowDays);
      expect(enLimite, 1.0);
    });

    test('fresco muy lejano -> clamp a 1.0', () {
      expect(
        expiryBarFraction(ExpiryStatus.fresco, kFreshWindowDays * 10),
        1.0,
      );
    });

    test('fresco: no decreciente al crecer los días', () {
      final a = expiryBarFraction(ExpiryStatus.fresco, 4);
      final b = expiryBarFraction(ExpiryStatus.fresco, 7);
      final c = expiryBarFraction(ExpiryStatus.fresco, 10);
      expect(a, lessThanOrEqualTo(b));
      expect(b, lessThanOrEqualTo(c));
    });

    test('freshWindowDays personalizado reescala la fracción', () {
      // Con ventana de 7 días, 7 días -> lleno.
      expect(
        expiryBarFraction(ExpiryStatus.fresco, 7, freshWindowDays: 7),
        1.0,
      );
      // 3 de 6 días -> media barra.
      expect(
        expiryBarFraction(ExpiryStatus.fresco, 3, freshWindowDays: 6),
        0.5,
      );
    });
  });

  group('expiryBarFraction: siempre dentro de [0, 1]', () {
    test('para todos los estados y días representativos', () {
      final dias = <int?>[null, -100, -1, 0, 1, 2, 3, 7, 13, 14, 100, 1000];
      for (final status in ExpiryStatus.values) {
        for (final d in dias) {
          final f = expiryBarFraction(status, d);
          expect(f, greaterThanOrEqualTo(0.0), reason: '$status / $d');
          expect(f, lessThanOrEqualTo(1.0), reason: '$status / $d');
        }
      }
    });

    test('es determinista (misma entrada, misma salida)', () {
      expect(
        expiryBarFraction(ExpiryStatus.fresco, 5),
        expiryBarFraction(ExpiryStatus.fresco, 5),
      );
    });
  });

  group('helpers a partir de un InventoryItem', () {
    test('expiryBarStatusFor reenvía el estado del item', () {
      final caducado = _item(
        category: 'Nevera',
        expirationDate: _daysFromNow(-1),
      );
      final fresco = _item(
        category: 'Nevera',
        expirationDate: _daysFromNow(10),
      );
      final sinFecha = _item(category: 'Despensa');
      expect(expiryBarStatusFor(caducado), ExpiryStatus.caducado);
      expect(expiryBarStatusFor(fresco), ExpiryStatus.fresco);
      expect(expiryBarStatusFor(sinFecha), ExpiryStatus.sinFecha);
    });

    test('expiryBarFractionFor combina estado y días del item', () {
      final caducado = _item(
        category: 'Despensa',
        expirationDate: _daysFromNow(-2),
      );
      expect(expiryBarFractionFor(caducado), 1.0);

      final sinFecha = _item(category: 'Despensa');
      expect(expiryBarFractionFor(sinFecha), 0.0);

      final pronto = _item(category: 'Nevera', expirationDate: _daysFromNow(0));
      expect(expiryBarFractionFor(pronto), greaterThan(0.0));
      expect(expiryBarFractionFor(pronto), lessThan(0.5));

      final fresco = _item(
        category: 'Nevera',
        expirationDate: _daysFromNow(kFreshWindowDays + 5),
      );
      expect(expiryBarFractionFor(fresco), 1.0);
    });
  });
}
