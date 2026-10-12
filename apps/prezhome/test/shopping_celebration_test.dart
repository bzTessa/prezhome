import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/shopping_celebration.dart';

void main() {
  group('shouldCelebratePurchase (función pura del gate)', () {
    test('dispara al pasar de >0 a 0 con comprados', () {
      expect(
        shouldCelebratePurchase(
          previousPending: 3,
          currentPending: 0,
          hasPurchased: true,
        ),
        isTrue,
      );
    });

    test('NO dispara en el primer fetch (previo null) aunque esté a 0', () {
      // Arranque directo con la lista ya completa: no hubo transición.
      expect(
        shouldCelebratePurchase(
          previousPending: null,
          currentPending: 0,
          hasPurchased: true,
        ),
        isFalse,
      );
    });

    test('NO dispara si ya estaba en 0 y se recarga a 0', () {
      expect(
        shouldCelebratePurchase(
          previousPending: 0,
          currentPending: 0,
          hasPurchased: true,
        ),
        isFalse,
      );
    });

    test('NO dispara si no hay comprados (lista vaciada por borrado)', () {
      expect(
        shouldCelebratePurchase(
          previousPending: 2,
          currentPending: 0,
          hasPurchased: false,
        ),
        isFalse,
      );
    });

    test('NO dispara si todavía quedan pendientes', () {
      expect(
        shouldCelebratePurchase(
          previousPending: 3,
          currentPending: 1,
          hasPurchased: true,
        ),
        isFalse,
      );
    });
  });

  group('ShoppingCelebrationGate (estado + consumo, sin replay)', () {
    test('dispara una vez al completar la compra y se CONSUME', () {
      final gate = ShoppingCelebrationGate();
      // Primer fetch: lista con pendientes, nada comprado aún.
      expect(
        gate.registerFetch(currentPending: 2, hasPurchased: false),
        isFalse,
      );
      // Se marca todo como comprado: transición de >0 a 0 con comprados.
      expect(gate.registerFetch(currentPending: 0, hasPurchased: true), isTrue);
      expect(gate.isCelebrationPending, isTrue);
      // build() consume el flag una sola vez.
      expect(gate.consume(), isTrue);
      expect(gate.isCelebrationPending, isFalse);
      // Rebuilds posteriores sin nuevo fetch NO reproducen la celebración.
      expect(gate.consume(), isFalse);
    });

    test('NO re-dispara si ya estaba en 0 y se recarga (replay del bug)', () {
      final gate = ShoppingCelebrationGate();
      gate.registerFetch(currentPending: 1, hasPurchased: false);
      expect(gate.registerFetch(currentPending: 0, hasPurchased: true), isTrue);
      expect(gate.consume(), isTrue);
      // Borrar un comprado estando en 0 pendientes -> otro fetch a 0 pendientes.
      // Esto reproducía el confeti; ahora NO debe volver a disparar ni dejar
      // una celebración pendiente.
      expect(
        gate.registerFetch(currentPending: 0, hasPurchased: true),
        isFalse,
      );
      expect(gate.isCelebrationPending, isFalse);
      expect(gate.consume(), isFalse);
    });

    test('se REARMA cuando vuelve a haber pendientes y se vacía de nuevo', () {
      final gate = ShoppingCelebrationGate();
      gate.registerFetch(currentPending: 2, hasPurchased: false);
      expect(gate.registerFetch(currentPending: 0, hasPurchased: true), isTrue);
      gate.consume();
      // Vuelve a haber pendientes (añadir algo a la lista).
      expect(
        gate.registerFetch(currentPending: 1, hasPurchased: true),
        isFalse,
      );
      // Y se vuelve a vaciar: debe celebrar otra vez.
      expect(gate.registerFetch(currentPending: 0, hasPurchased: true), isTrue);
      expect(gate.consume(), isTrue);
    });

    test('el primer fetch directo a 0 con comprados NO celebra', () {
      final gate = ShoppingCelebrationGate();
      expect(
        gate.registerFetch(currentPending: 0, hasPurchased: true),
        isFalse,
      );
      expect(gate.isCelebrationPending, isFalse);
    });
  });
}
