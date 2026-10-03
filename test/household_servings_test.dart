import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/household_servings.dart';

void main() {
  group('servingsForMeal · por defecto (todos cuentan)', () {
    test('sin configuración, todos los miembros comen en casa cualquier día', () {
      final members = [
        const HouseholdMember(name: 'Tessa', isMe: true),
        const HouseholdMember(name: 'Pablo'),
      ];
      // Lunes (1) y domingo (7): da igual, no hay restricciones.
      for (final weekday in [1, 7]) {
        for (final type in ['breakfast', 'lunch', 'dinner']) {
          expect(servingsCountForMeal(members, type, weekday), 2);
        }
      }
      final res = servingsForMeal(members, 'lunch', 1);
      expect(res.count, 2);
      expect(res.names, ['tú', 'Pablo']);
    });

    test('lista vacía para una comida equivale a todos los días', () {
      final members = [
        const HouseholdMember(name: 'Pablo', mealsAtHome: {'lunch': []}),
      ];
      expect(servingsCountForMeal(members, 'lunch', 3), 1);
    });
  });

  group('servingsForMeal · restricción por días', () {
    test('meals_at_home {lunch:[6,7]} solo cuenta en comida de finde', () {
      final members = [
        const HouseholdMember(
          name: 'Pablo',
          mealsAtHome: {
            'lunch': [6, 7],
          },
        ),
      ];
      // Entre semana (Lun=1..Vie=5) NO come en casa a la hora de comer.
      for (final weekday in [1, 2, 3, 4, 5]) {
        expect(servingsCountForMeal(members, 'lunch', weekday), 0);
      }
      // Sábado (6) y domingo (7) sí.
      expect(servingsCountForMeal(members, 'lunch', 6), 1);
      expect(servingsCountForMeal(members, 'lunch', 7), 1);
      // Otras comidas no están restringidas => cuenta siempre.
      expect(servingsCountForMeal(members, 'dinner', 1), 1);
    });
  });

  group('servingsForMeal · suma multi-miembro', () {
    test('cada miembro suma según su propia configuración por día/comida', () {
      final members = [
        const HouseholdMember(name: 'Tessa', isMe: true), // siempre en casa
        const HouseholdMember(
          name: 'Pablo',
          mealsAtHome: {
            'lunch': [6, 7],
          },
        ),
        const HouseholdMember(
          name: 'Ana',
          mealsAtHome: {
            'dinner': [1, 2, 3, 4, 5],
          },
        ),
      ];
      // Lunes comida: Tessa sí, Pablo no (solo finde), Ana sin restricción => 2.
      expect(servingsCountForMeal(members, 'lunch', 1), 2);
      // Sábado comida: Tessa sí, Pablo sí (finde), Ana sin restricción => 3.
      expect(servingsCountForMeal(members, 'lunch', 6), 3);
      // Lunes cena: Tessa sí, Pablo sin restricción, Ana sí (entre semana) => 3.
      expect(servingsCountForMeal(members, 'dinner', 1), 3);
      // Domingo cena: Tessa sí, Pablo sin restricción, Ana no (solo L-V) => 2.
      expect(servingsCountForMeal(members, 'dinner', 7), 2);
    });
  });

  group('ServingsResult · etiqueta de nombres', () {
    test('coloca "tú" primero y luego el resto en orden', () {
      final members = [
        const HouseholdMember(name: 'Pablo'),
        const HouseholdMember(name: 'Tessa', isMe: true),
        const HouseholdMember(name: 'Ana'),
      ];
      final res = servingsForMeal(members, 'dinner', 3);
      expect(res.count, 3);
      expect(res.names, ['tú', 'Pablo', 'Ana']);
      expect(res.label, '3 raciones: tú, Pablo, Ana');
    });

    test('una sola persona usa "ración" en singular', () {
      final members = [const HouseholdMember(name: 'Tessa', isMe: true)];
      final res = servingsForMeal(members, 'breakfast', 2);
      expect(res.label, '1 ración: tú');
    });

    test('nadie en casa => 0 raciones sin nombres', () {
      final members = [
        const HouseholdMember(
          name: 'Pablo',
          mealsAtHome: {
            'lunch': [6, 7],
          },
        ),
      ];
      final res = servingsForMeal(members, 'lunch', 1);
      expect(res.count, 0);
      expect(res.names, isEmpty);
      expect(res.label, '0 raciones');
    });
  });
}
