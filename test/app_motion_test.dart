import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/theme/app_motion.dart';

void main() {
  group('AppMotion tokens (duraciones y curvas en rango medido)', () {
    test('las duraciones están en el rango ~150-350 ms', () {
      expect(AppMotion.fast, const Duration(milliseconds: 150));
      expect(AppMotion.base, const Duration(milliseconds: 250));
      expect(AppMotion.slow, const Duration(milliseconds: 350));
    });

    test('fast < base < slow (escala coherente creciente)', () {
      expect(AppMotion.fast < AppMotion.base, isTrue);
      expect(AppMotion.base < AppMotion.slow, isTrue);
    });

    test('ninguna duración se sale del rango 150-350 ms', () {
      for (final d in [AppMotion.fast, AppMotion.base, AppMotion.slow]) {
        expect(d.inMilliseconds, greaterThanOrEqualTo(150));
        expect(d.inMilliseconds, lessThanOrEqualTo(350));
      }
    });
  });

  group('AppMotion.effectiveDuration (respeta reduce-motion)', () {
    test('reduceMotion=false devuelve la duración pedida tal cual', () {
      expect(
        AppMotion.effectiveDuration(AppMotion.base, reduceMotion: false),
        AppMotion.base,
      );
      expect(
        AppMotion.effectiveDuration(AppMotion.slow, reduceMotion: false),
        AppMotion.slow,
      );
      expect(
        AppMotion.effectiveDuration(
          const Duration(milliseconds: 999),
          reduceMotion: false,
        ),
        const Duration(milliseconds: 999),
      );
    });

    test('reduceMotion=true devuelve Duration.zero', () {
      expect(
        AppMotion.effectiveDuration(AppMotion.base, reduceMotion: true),
        Duration.zero,
      );
      expect(
        AppMotion.effectiveDuration(AppMotion.fast, reduceMotion: true),
        Duration.zero,
      );
      expect(
        AppMotion.effectiveDuration(
          const Duration(seconds: 5),
          reduceMotion: true,
        ),
        Duration.zero,
      );
    });

    test('Duration.zero se mantiene en zero con reduceMotion=false', () {
      expect(
        AppMotion.effectiveDuration(Duration.zero, reduceMotion: false),
        Duration.zero,
      );
    });
  });

  group('AppMotion.staggerDelay (escalonado por índice)', () {
    test('con reduceMotion=false el delay crece con el índice', () {
      final d0 = AppMotion.staggerDelay(0, reduceMotion: false);
      final d1 = AppMotion.staggerDelay(1, reduceMotion: false);
      final d2 = AppMotion.staggerDelay(2, reduceMotion: false);
      final d3 = AppMotion.staggerDelay(3, reduceMotion: false);

      expect(d0, Duration.zero);
      expect(d1 > d0, isTrue);
      expect(d2 > d1, isTrue);
      expect(d3 > d2, isTrue);
    });

    test('el delay es múltiplo del step por índice', () {
      const step = Duration(milliseconds: 60);
      expect(
        AppMotion.staggerDelay(1, step: step, reduceMotion: false),
        step * 1,
      );
      expect(
        AppMotion.staggerDelay(3, step: step, reduceMotion: false),
        step * 3,
      );
    });

    test('con reduceMotion=true el delay es 0 para todos los índices', () {
      for (final i in [0, 1, 2, 5, 10, 100]) {
        expect(AppMotion.staggerDelay(i, reduceMotion: true), Duration.zero);
      }
    });

    test('índices negativos o 0 devuelven Duration.zero', () {
      expect(AppMotion.staggerDelay(0, reduceMotion: false), Duration.zero);
      expect(AppMotion.staggerDelay(-3, reduceMotion: false), Duration.zero);
    });

    test('maxItems limita el retardo acumulado en listas largas', () {
      const step = Duration(milliseconds: 60);
      final atLimit = AppMotion.staggerDelay(
        8,
        step: step,
        reduceMotion: false,
        maxItems: 8,
      );
      final beyond = AppMotion.staggerDelay(
        50,
        step: step,
        reduceMotion: false,
        maxItems: 8,
      );
      expect(beyond, atLimit);
      expect(beyond, step * 8);
    });
  });

  group('AppMotion.lerpDouble (interpolación del contador)', () {
    test('t=0 devuelve el valor inicial', () {
      expect(AppMotion.lerpDouble(10, 20, 0), 10);
    });

    test('t=1 devuelve el valor final', () {
      expect(AppMotion.lerpDouble(10, 20, 1), 20);
    });

    test('t=0.5 devuelve el punto medio', () {
      expect(AppMotion.lerpDouble(10, 20, 0.5), 15);
      expect(AppMotion.lerpDouble(0, 100, 0.5), 50);
    });

    test('t fuera de rango se recorta a [0, 1]', () {
      expect(AppMotion.lerpDouble(10, 20, -1), 10);
      expect(AppMotion.lerpDouble(10, 20, 2), 20);
    });

    test('interpola correctamente valores decrecientes', () {
      expect(AppMotion.lerpDouble(20, 10, 0.5), 15);
    });

    test('formateo euros: punto intermedio con dos decimales', () {
      final mid = AppMotion.lerpDouble(0, 12.5, 0.5);
      expect(mid.toStringAsFixed(2), '6.25');
    });

    test('formateo kcal: punto intermedio redondeado', () {
      final mid = AppMotion.lerpDouble(0, 2000, 0.5);
      expect(mid.round(), 1000);
    });
  });
}
