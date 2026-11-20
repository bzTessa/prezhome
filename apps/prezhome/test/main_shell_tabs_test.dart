import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/main_shell.dart';
import 'package:prezhome/models/dashboard_prefs.dart';

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

    test('Tareas se ve aunque su módulo esté desactivado', () {
      final ids = computeVisibleTabIds(
        DashboardPrefs.defaults().copyWith(enabledModules: <HomeModule>{}),
      );
      expect(ids.last, TabId.tareas);
      expect(ids.indexOf(TabId.inicio), 0);
    });
  });
}
