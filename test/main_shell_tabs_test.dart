import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/main_shell.dart';
import 'package:prezhome/models/dashboard_prefs.dart';

void main() {
  group('computeVisibleTabIds (índices por identidad semántica)', () {
    test('con módulos por defecto están las 5 pestañas en el orden fijo', () {
      final ids = computeVisibleTabIds(DashboardPrefs.defaults());
      expect(ids, [
        TabId.comidas,
        TabId.despensa,
        TabId.inicio,
        TabId.tareas,
        TabId.hogar,
      ]);
    });

    test('con módulos por defecto Inicio arranca y Despensa es válido', () {
      final ids = computeVisibleTabIds(DashboardPrefs.defaults());
      // La app arranca en Inicio.
      expect(ids.indexOf(TabId.inicio), 2);
      // La navegación 'Caducidades -> Despensa' tiene un índice válido.
      final despensa = ids.indexOf(TabId.despensa);
      expect(despensa, isNonNegative);
      expect(despensa, lessThan(ids.length));
    });

    test('con Tareas desactivado desaparece su pestaña y quedan 4', () {
      final prefs = DashboardPrefs.defaults().copyWith(
        enabledModules: {HomeModule.points, HomeModule.batchCooking},
      );
      final ids = computeVisibleTabIds(prefs);
      expect(ids, [TabId.comidas, TabId.despensa, TabId.inicio, TabId.hogar]);
      expect(ids, isNot(contains(TabId.tareas)));
    });

    test(
      'sin Tareas, Inicio sigue siendo el arranque y Despensa sigue válido',
      () {
        final prefs = DashboardPrefs.defaults().copyWith(
          enabledModules: <HomeModule>{},
        );
        final ids = computeVisibleTabIds(prefs);
        // Inicio presente para arrancar ahí (índice recalculado, no 2 fijo).
        expect(ids.contains(TabId.inicio), isTrue);
        // Despensa presente para 'Caducidades -> Despensa'.
        final despensa = ids.indexOf(TabId.despensa);
        expect(despensa, isNonNegative);
        expect(despensa, lessThan(ids.length));
      },
    );

    test('Tareas es la ÚNICA pestaña condicional', () {
      // Sin ningún módulo activado solo falta Tareas; el resto permanece.
      final ids = computeVisibleTabIds(
        DashboardPrefs.defaults().copyWith(enabledModules: <HomeModule>{}),
      );
      expect(ids, [TabId.comidas, TabId.despensa, TabId.inicio, TabId.hogar]);
    });
  });
}
