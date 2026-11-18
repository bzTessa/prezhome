import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/shelf_life.dart';
import 'package:prezhome/services/shelf_life_memory.dart';

void main() {
  tearDown(() => ShelfLife.learned = const {});

  test('lo corregido a mano manda sobre la tabla, por producto y zona', () {
    expect(ShelfLife.estimateDays('Nata montada', 'Nevera'), 5);
    ShelfLife.learned = {
      ShelfLife.learnedKey(ShelfLife.normalizedName('Nata montada'), 'Nevera'):
          12,
    };
    expect(ShelfLife.estimateDays('  nata  MONTADA', 'Nevera'), 12);
    expect(ShelfLife.estimateDays('Nata montada', 'Despensa'), 150);
  });

  test('días aprendidos: en un alta, de hoy a la fecha elegida', () {
    final today = DateTime(2026, 11, 17, 18);
    expect(learnedShelfDays(picked: DateTime(2027, 4, 17), today: today), 151);
    expect(
      learnedShelfDays(picked: DateTime(2026, 11, 17), today: today),
      isNull,
    );
  });

  test('al editar suma lo que se movió la fecha a lo que proponía la app', () {
    // Entró hace días con 5 de vida; la persona la alarga 25 días.
    expect(
      learnedShelfDays(
        picked: DateTime(2026, 12, 15),
        previous: DateTime(2026, 11, 20),
        estimatedDays: 5,
        today: DateTime(2026, 11, 17),
      ),
      30,
    );
  });
}
