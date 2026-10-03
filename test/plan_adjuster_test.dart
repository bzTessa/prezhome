import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/plan_adjuster.dart';

/// Semana fija de referencia: lunes 2024-01-01 .. domingo 2024-01-07.
/// Al ser fechas concretas los tests son deterministas y no dependen de hoy.
DateTime _day(int offsetDesdeLunes) =>
    DateTime(2024, 1, 1).add(Duration(days: offsetDesdeLunes));

/// Construye un hueco de la semana. El id combina día y tipo para legibilidad.
PlanSlot _slot(
  int offsetDesdeLunes,
  String mealType, {
  String? recipeId,
  bool skipped = false,
}) {
  return PlanSlot(
    id: 'd$offsetDesdeLunes-$mealType',
    date: _day(offsetDesdeLunes),
    mealType: mealType,
    recipeId: recipeId,
    skipped: skipped,
  );
}

/// Plan de ejemplo: comida y cena de lunes a domingo con algunos huecos libres.
List<PlanSlot> _semana() {
  return [
    _slot(0, 'lunch', recipeId: 'lentejas'),
    _slot(0, 'dinner', recipeId: 'tortilla'),
    _slot(1, 'lunch'), // martes comida libre
    _slot(1, 'dinner', recipeId: 'sopa'),
    _slot(2, 'lunch', recipeId: 'pasta'),
    _slot(2, 'dinner'), // miércoles cena libre
    _slot(3, 'lunch'), // jueves comida libre
    _slot(3, 'dinner', recipeId: 'pescado'),
  ];
}

PlanSlot _byId(List<PlanSlot> slots, String id) =>
    slots.firstWhere((s) => s.id == id);

void main() {
  const adjuster = PlanAdjuster();

  group('adjustForSkipped: recolocación al mismo tipo de comida', () {
    test('skip recoloca al siguiente día libre del mismo tipo', () {
      final result = adjuster.adjustForSkipped(_semana(), 'd0-lunch');

      // El lunes queda "fuera" y sin plato activo.
      final lunes = _byId(result.slots, 'd0-lunch');
      expect(lunes.skipped, isTrue);
      expect(lunes.recipeId, isNull);

      // Las lentejas se mueven al martes (primera comida libre posterior).
      final martes = _byId(result.slots, 'd1-lunch');
      expect(martes.recipeId, 'lentejas');

      expect(result.movedRecipeId, 'lentejas');
      expect(result.movedToDate, _day(1));
    });

    test('elige el PRIMER hueco posterior, no uno más lejano', () {
      // Ocupamos el martes para forzar que vaya al jueves (siguiente libre).
      final slots = _semana();
      final idx = slots.indexWhere((s) => s.id == 'd1-lunch');
      slots[idx] = _slot(1, 'lunch', recipeId: 'arroz');

      final result = adjuster.adjustForSkipped(slots, 'd0-lunch');
      final jueves = _byId(result.slots, 'd3-lunch');
      expect(jueves.recipeId, 'lentejas');
      expect(result.movedToDate, _day(3));
    });
  });

  group('adjustForSkipped: sin hueco posterior', () {
    test('no se pierde el plato pero no se recoloca', () {
      // El jueves (último lunch) marcado como fuera: no hay lunch posterior.
      final result = adjuster.adjustForSkipped(_semana(), 'd3-lunch');

      final jueves = _byId(result.slots, 'd3-lunch');
      expect(jueves.skipped, isTrue);
      expect(jueves.recipeId, isNull);

      // No hubo movimiento.
      expect(result.movedRecipeId, isNull);
      expect(result.movedToDate, isNull);

      // El plan sigue coherente: mismas cantidad de huecos.
      expect(result.slots.length, _semana().length);
    });
  });

  group('aislamiento por tipo de comida', () {
    test('un skip de comida no toca las cenas', () {
      final result = adjuster.adjustForSkipped(_semana(), 'd0-lunch');

      // La cena del miércoles sigue libre (no se usó como destino del lunch).
      final cenaMiercoles = _byId(result.slots, 'd2-dinner');
      expect(cenaMiercoles.recipeId, isNull);

      // Las cenas con plato se mantienen intactas.
      expect(_byId(result.slots, 'd0-dinner').recipeId, 'tortilla');
      expect(_byId(result.slots, 'd1-dinner').recipeId, 'sopa');
      expect(_byId(result.slots, 'd3-dinner').recipeId, 'pescado');
    });
  });

  group('reactivate', () {
    test('reactivar devuelve la comida a estado activo', () {
      // Partimos de un lunes marcado como fuera.
      final slots = _semana();
      final idx = slots.indexWhere((s) => s.id == 'd0-lunch');
      slots[idx] = _slot(0, 'lunch', recipeId: 'lentejas', skipped: true);

      final result = adjuster.reactivate(slots, 'd0-lunch');
      final lunes = _byId(result.slots, 'd0-lunch');
      expect(lunes.skipped, isFalse);
      expect(lunes.recipeId, 'lentejas');
    });
  });

  group('miauMoveMessage', () {
    test('mensaje con día destino correcto cuando hubo movimiento', () {
      final result = adjuster.adjustForSkipped(_semana(), 'd0-lunch');
      final msg = miauMoveMessage(result, recipeTitle: 'Lentejas');
      // El martes es el destino (2024-01-02, weekday 2).
      expect(msg, 'Movido Lentejas al martes');
    });

    test('mensaje de "otro momento" cuando no hubo hueco', () {
      final result = adjuster.adjustForSkipped(_semana(), 'd3-lunch');
      final msg = miauMoveMessage(result, recipeTitle: 'Lentejas');
      expect(msg, 'Lo dejo para otro momento');
    });

    test('usa "el plato" si no se conoce el título', () {
      final result = adjuster.adjustForSkipped(_semana(), 'd0-lunch');
      final msg = miauMoveMessage(result);
      expect(msg, 'Movido el plato al martes');
    });
  });
}
