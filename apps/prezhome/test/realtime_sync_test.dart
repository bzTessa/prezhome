import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/realtime_sync.dart';

void main() {
  group('isRealtimeFailure (función pura)', () {
    test('subscribed NO es fallo', () {
      expect(isRealtimeFailure(RealtimeChannelState.subscribed), isFalse);
    });

    test('error, closed y timedOut SÍ son fallo', () {
      expect(isRealtimeFailure(RealtimeChannelState.error), isTrue);
      expect(isRealtimeFailure(RealtimeChannelState.closed), isTrue);
      expect(isRealtimeFailure(RealtimeChannelState.timedOut), isTrue);
    });
  });

  group('RealtimeNoticeGate (avisar una sola vez, rearmar al reconectar)', () {
    test('un suscrito correcto nunca avisa', () {
      final gate = RealtimeNoticeGate();
      expect(gate.registerStatus(RealtimeChannelState.subscribed), isFalse);
      expect(gate.hasNotified, isFalse);
    });

    test('fallos repetidos: avisa solo en el primero', () {
      final gate = RealtimeNoticeGate();
      expect(gate.registerStatus(RealtimeChannelState.error), isTrue);
      expect(gate.hasNotified, isTrue);
      // Encadenar más fallos no vuelve a avisar.
      expect(gate.registerStatus(RealtimeChannelState.timedOut), isFalse);
      expect(gate.registerStatus(RealtimeChannelState.closed), isFalse);
      expect(gate.registerStatus(RealtimeChannelState.error), isFalse);
    });

    test('una reconexión correcta REARMA y vuelve a avisar una vez', () {
      final gate = RealtimeNoticeGate();
      expect(gate.registerStatus(RealtimeChannelState.error), isTrue);
      expect(gate.registerStatus(RealtimeChannelState.error), isFalse);
      // Vuelve a suscribirse bien -> rearma el gate.
      expect(gate.registerStatus(RealtimeChannelState.subscribed), isFalse);
      expect(gate.hasNotified, isFalse);
      // Nuevo fallo tras reconectar: avisa otra vez (una sola vez).
      expect(gate.registerStatus(RealtimeChannelState.timedOut), isTrue);
      expect(gate.registerStatus(RealtimeChannelState.timedOut), isFalse);
    });

    test('reset() rearma manualmente el gate', () {
      final gate = RealtimeNoticeGate();
      expect(gate.registerStatus(RealtimeChannelState.error), isTrue);
      expect(gate.registerStatus(RealtimeChannelState.error), isFalse);
      gate.reset();
      expect(gate.hasNotified, isFalse);
      expect(gate.registerStatus(RealtimeChannelState.error), isTrue);
    });

    test(
      'arranque directo con suscripción correcta no deja aviso pendiente',
      () {
        final gate = RealtimeNoticeGate();
        expect(gate.registerStatus(RealtimeChannelState.subscribed), isFalse);
        expect(gate.registerStatus(RealtimeChannelState.subscribed), isFalse);
        expect(gate.hasNotified, isFalse);
      },
    );
  });
}
