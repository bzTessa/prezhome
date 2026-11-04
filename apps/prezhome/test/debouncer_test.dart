import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/debouncer.dart';

void main() {
  group('Debouncer agrupa ráfagas en una sola ejecución', () {
    test('N llamadas rápidas disparan la acción una sola vez', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 60));
      var runs = 0;
      // Ráfaga de toques (como subir la cantidad 5 veces seguidas).
      for (var i = 0; i < 5; i++) {
        d.run(() => runs++);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      // Durante la ráfaga, antes del delay desde el último toque: no corre.
      expect(runs, 0);
      expect(d.isPending, isTrue);
      // Pasado el delay desde el último toque: una única ejecución.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(runs, 1);
      expect(d.isPending, isFalse);
    });

    test('ejecuciones separadas en el tiempo corren cada una', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 40));
      var runs = 0;
      d.run(() => runs++);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      d.run(() => runs++);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(runs, 2);
    });

    test('cancel evita la ejecución pendiente', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 40));
      var runs = 0;
      d.run(() => runs++);
      d.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(runs, 0);
      expect(d.isPending, isFalse);
    });
  });
}
