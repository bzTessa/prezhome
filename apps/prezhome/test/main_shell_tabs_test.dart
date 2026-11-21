import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/main_shell.dart';
import 'package:prezhome/models/dashboard_prefs.dart';
import 'package:prezhome/models/usage_mode.dart';

void main() {
  group('computeVisibleTabIds (índices por identidad semántica)', () {
    test('con módulos por defecto están las 4 pestañas en el orden diario', () {
      final ids = computeVisibleTabIds(DashboardPrefs.defaults());
      expect(ids, [TabId.inicio, TabId.comidas, TabId.compra, TabId.tareas]);
    });

    test('con módulos por defecto Inicio arranca y Compra es válido', () {
      final ids = computeVisibleTabIds(DashboardPrefs.defaults());
      // La app arranca en Inicio.
      expect(ids.indexOf(TabId.inicio), 0);
      // La navegación 'Caducidades -> En casa' pasa por Compra y tiene índice válido.
      final compra = ids.indexOf(TabId.compra);
      expect(compra, isNonNegative);
      expect(compra, lessThan(ids.length));
    });

    test('en modo Esencial (sin tareas) no sale la pestaña Tareas', () {
      final ids = computeVisibleTabIds(
        UsageMode.essential.applyTo(DashboardPrefs.defaults()),
      );
      expect(ids, [TabId.inicio, TabId.comidas, TabId.compra]);
    });

    test('Hoy no enseña calorías ni tareas si el modo las apaga', () {
      final esencial = UsageMode.essential.applyTo(DashboardPrefs.defaults());
      expect(esencial.activeCards, isNot(contains(DashboardCard.calories)));
      expect(esencial.activeCards, isNot(contains(DashboardCard.tasks)));
      expect(esencial.activeCards, contains(DashboardCard.meals));
      final completo = UsageMode.complete.applyTo(DashboardPrefs.defaults());
      expect(completo.activeCards, DashboardPrefs.defaults().visibleCards);
    });
  });
}
