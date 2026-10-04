import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/dashboard_prefs.dart';

void main() {
  group('DashboardPrefs tolerante al id "calendar" heredado', () {
    test('DashboardCard.byId("calendar") ya no existe y devuelve null', () {
      expect(DashboardCard.byId('calendar'), isNull);
    });

    test('defaults() ya no incluye la tarjeta calendar', () {
      final prefs = DashboardPrefs.defaults();
      expect(prefs.order.map((c) => c.id), isNot(contains('calendar')));
      expect(prefs.visibleCards.map((c) => c.id), isNot(contains('calendar')));
    });

    test('fromJson ignora un id "calendar" guardado en "cards" sin romper', () {
      final prefs = DashboardPrefs.fromJson({
        'cards': ['meals', 'calendar', 'tasks'],
        'hidden': [],
        'quick': [],
      });
      // El id heredado no aparece y el resto del orden se conserva.
      expect(prefs.order.map((c) => c.id), isNot(contains('calendar')));
      expect(prefs.order, contains(DashboardCard.meals));
      expect(prefs.order, contains(DashboardCard.tasks));
    });

    test(
      'fromJson ignora un id "calendar" guardado en "hidden" sin romper',
      () {
        final prefs = DashboardPrefs.fromJson({
          'cards': [],
          'hidden': ['calendar'],
          'quick': [],
        });
        expect(prefs.hidden.map((c) => c.id), isNot(contains('calendar')));
        // Un perfil antiguo con solo 'calendar' oculto no oculta nada real.
        expect(prefs.hidden, isEmpty);
      },
    );
  });
}
