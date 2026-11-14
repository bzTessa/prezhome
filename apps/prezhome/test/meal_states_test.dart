import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/meal_states.dart';

void main() {
  final slots = [
    (type: 'breakfast', time: '08:30', filled: true),
    (type: 'lunch', time: '14:00', filled: true),
    (type: 'snack', time: '17:30', filled: false),
    (type: 'dinner', time: '21:00', filled: true),
  ];

  test('a las 16:00 la comida está hecha y toca la cena', () {
    final s = mealSlotStates(slots, DateTime(2026, 11, 14, 16));
    expect(s['breakfast'], MealSlotState.done);
    expect(s['lunch'], MealSlotState.done);
    expect(s['snack'], MealSlotState.normal);
    expect(s['dinner'], MealSlotState.next);
  });

  test('a las 14:30 aún toca la comida', () {
    final s = mealSlotStates(slots, DateTime(2026, 11, 14, 14, 30));
    expect(s['lunch'], MealSlotState.next);
    expect(s['dinner'], MealSlotState.normal);
  });

  test('sin hora no hay estado', () {
    final s = mealSlotStates([
      (type: 'lunch', time: null, filled: true),
    ], DateTime(2026, 11, 14, 23));
    expect(s['lunch'], MealSlotState.normal);
  });
}
