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

  group('DashboardPrefs módulos activables y estilo de cocina', () {
    test('defaults() activa los tres módulos y usa el estilo por defecto', () {
      final prefs = DashboardPrefs.defaults();
      expect(prefs.enabledModules, {
        HomeModule.points,
        HomeModule.tasks,
        HomeModule.batchCooking,
      });
      expect(prefs.enabledModules.length, HomeModule.values.length);
      expect(prefs.cookingStyle, CookingStyle.defaultStyle);
      // isModuleEnabled refleja el conjunto activado.
      for (final m in HomeModule.values) {
        expect(prefs.isModuleEnabled(m), isTrue);
      }
    });

    test(
      'toJson incluye "modules" y "cooking_style" junto a las claves previas',
      () {
        final json = DashboardPrefs.defaults().toJson();
        expect(json.keys, containsAll(['cards', 'hidden', 'quick']));
        expect(json.keys, containsAll(['modules', 'cooking_style']));
        expect(
          json['modules'],
          containsAll(['points', 'tasks', 'batch_cooking']),
        );
        expect(json['cooking_style'], CookingStyle.defaultStyle.id);
      },
    );

    test('round-trip fromJson(toJson()) conserva módulos y estilo', () {
      final original = DashboardPrefs.defaults().copyWith(
        enabledModules: {HomeModule.points, HomeModule.batchCooking},
        cookingStyle: CookingStyle.batch,
      );
      final restored = DashboardPrefs.fromJson(original.toJson());
      expect(restored.enabledModules, original.enabledModules);
      expect(restored.cookingStyle, CookingStyle.batch);
    });

    test('fromJson sin clave "modules" (datos antiguos) activa todos', () {
      final prefs = DashboardPrefs.fromJson({
        'cards': ['meals', 'tasks'],
        'hidden': [],
        'quick': [],
      });
      expect(prefs.enabledModules, {
        HomeModule.points,
        HomeModule.tasks,
        HomeModule.batchCooking,
      });
    });

    test('fromJson con "modules": [] respeta ninguno activado', () {
      final prefs = DashboardPrefs.fromJson({
        'cards': [],
        'hidden': [],
        'quick': [],
        'modules': <String>[],
      });
      expect(prefs.enabledModules, isEmpty);
      for (final m in HomeModule.values) {
        expect(prefs.isModuleEnabled(m), isFalse);
      }
    });

    test('fromJson ignora ids de módulo desconocidos y conserva válidos', () {
      final prefs = DashboardPrefs.fromJson({
        'modules': ['tasks', 'desconocido'],
      });
      expect(prefs.enabledModules, {HomeModule.tasks});
    });

    test('fromJson con "cooking_style" desconocido cae al default', () {
      final prefs = DashboardPrefs.fromJson({'cooking_style': 'no-existe'});
      expect(prefs.cookingStyle, CookingStyle.defaultStyle);
    });

    test('fromJson con "cooking_style" ausente cae al default', () {
      final prefs = DashboardPrefs.fromJson({'modules': <String>[]});
      expect(prefs.cookingStyle, CookingStyle.defaultStyle);
    });

    test('fromJson con "cooking_style" conocido lo respeta', () {
      final prefs = DashboardPrefs.fromJson({'cooking_style': 'batch'});
      expect(prefs.cookingStyle, CookingStyle.batch);
    });

    test(
      'JSON antiguo (solo cards/hidden/quick) parsea con defaults nuevos',
      () {
        final prefs = DashboardPrefs.fromJson({
          'cards': ['meals', 'expiry'],
          'hidden': ['tasks'],
          'quick': ['shopping'],
        });
        // Las claves nuevas ausentes -> todos los módulos + estilo por defecto.
        expect(prefs.enabledModules.length, HomeModule.values.length);
        expect(prefs.cookingStyle, CookingStyle.defaultStyle);
        // La lógica previa de cards/hidden/quick sigue intacta.
        expect(prefs.hidden, contains(DashboardCard.tasks));
        expect(prefs.quick, contains(QuickAction.shopping));
      },
    );

    test('HomeModule.byId devuelve el módulo o null si desconocido', () {
      expect(HomeModule.byId('points'), HomeModule.points);
      expect(HomeModule.byId('batch_cooking'), HomeModule.batchCooking);
      expect(HomeModule.byId('nope'), isNull);
    });

    test('CookingStyle.byId devuelve el estilo o null si desconocido', () {
      expect(CookingStyle.byId('batch'), CookingStyle.batch);
      expect(CookingStyle.byId('daily'), CookingStyle.daily);
      expect(CookingStyle.byId('nope'), isNull);
    });
  });
}
