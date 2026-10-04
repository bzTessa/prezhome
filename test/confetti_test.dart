import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/animations/confetti.dart';

void main() {
  group('generateConfetti (determinista y acotado)', () {
    test('devuelve exactamente el numero de particulas pedido', () {
      expect(generateConfetti().length, kConfettiParticleCount);
      expect(generateConfetti(count: 10).length, 10);
      expect(generateConfetti(count: 0).length, 0);
    });

    test('mismo seed -> mismas particulas (determinismo)', () {
      final a = generateConfetti(seed: 7);
      final b = generateConfetti(seed: 7);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].x, b[i].x);
        expect(a[i].drift, b[i].drift);
        expect(a[i].delay, b[i].delay);
        expect(a[i].speed, b[i].speed);
        expect(a[i].colorIndex, b[i].colorIndex);
      }
    });

    test('seeds distintos producen conjuntos distintos', () {
      final a = generateConfetti(seed: 1);
      final b = generateConfetti(seed: 2);
      final iguales = List.generate(a.length, (i) => a[i].x == b[i].x);
      // No todas las x pueden coincidir con seeds distintos.
      expect(iguales.every((e) => e), isFalse);
    });

    test('los parametros caen dentro de sus rangos esperados', () {
      for (final p in generateConfetti(seed: 99)) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.drift, inInclusiveRange(-0.5, 0.5));
        expect(p.delay, inInclusiveRange(0.0, 0.35));
        expect(p.speed, inInclusiveRange(0.6, 1.0));
        expect(p.size, inInclusiveRange(7.0, 14.0));
        expect(p.colorIndex, inInclusiveRange(0, 4));
      }
    });

    test('colorIndex nunca excede paletteSize', () {
      for (final p in generateConfetti(seed: 3, paletteSize: 2)) {
        expect(p.colorIndex, inInclusiveRange(0, 1));
      }
    });
  });

  group('ConfettiParticle.localProgress (funcion pura del progreso)', () {
    const p = ConfettiParticle(
      x: 0.5,
      drift: 0,
      delay: 0.2,
      speed: 1,
      rotation: 0,
      spin: 0,
      size: 10,
      colorIndex: 0,
    );

    test('antes del delay no ha salido (0)', () {
      expect(p.localProgress(0), 0);
      expect(p.localProgress(0.1), 0);
      expect(p.localProgress(0.2), 0);
    });

    test('tras el delay avanza linealmente hasta 1', () {
      // A mitad del tramo restante (0.2..1.0) => 0.5.
      expect(p.localProgress(0.6), closeTo(0.5, 1e-9));
      expect(p.localProgress(1), 1);
    });

    test('esta acotado a [0,1] (monotono no decreciente)', () {
      double prev = -1;
      for (var t = 0.0; t <= 1.0; t += 0.05) {
        final v = p.localProgress(t);
        expect(v, inInclusiveRange(0.0, 1.0));
        expect(v, greaterThanOrEqualTo(prev));
        prev = v;
      }
    });
  });

  group('ConfettiParticle.verticalAt (caida acotada)', () {
    const p = ConfettiParticle(
      x: 0,
      drift: 0,
      delay: 0,
      speed: 0.8,
      rotation: 0,
      spin: 0,
      size: 10,
      colorIndex: 0,
    );

    test('empieza arriba (0) y cae segun speed, siempre en [0,1]', () {
      expect(p.verticalAt(0), 0);
      expect(p.verticalAt(1), closeTo(0.8, 1e-9));
      for (var t = 0.0; t <= 1.0; t += 0.1) {
        expect(p.verticalAt(t), inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
