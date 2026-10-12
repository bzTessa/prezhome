import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/smart_reminders.dart';

void main() {
  group('buildReminders', () {
    test('ordena por urgencia: urgente antes que hoy antes que pronto', () {
      final r = buildReminders(
        mealsToday: ['Lentejas'], // hoy
        stock: [
          const ReminderStockItem(name: 'Yogur', daysUntilExpiry: 2), // pronto
          const ReminderStockItem(
            name: 'Leche',
            daysUntilExpiry: -1,
          ), // urgente
        ],
        takeOuts: const [],
        tasksToday: const [],
        pendingShopping: 0,
      );
      expect(r.first.urgency, ReminderUrgency.urgente);
      expect(r.first.kind, ReminderKind.caducidad);
      // El último debería ser el "pronto".
      expect(r.last.urgency, ReminderUrgency.pronto);
    });

    test('sacar del congelador: hoy, ya tocaba y mañana', () {
      final r = buildReminders(
        mealsToday: const [],
        stock: const [],
        takeOuts: const [
          ReminderTakeOut(name: 'Pollo', daysUntilTakeOut: 0),
          ReminderTakeOut(name: 'Merluza', daysUntilTakeOut: -2),
          ReminderTakeOut(name: 'Guiso', daysUntilTakeOut: 1),
        ],
        tasksToday: const [],
        pendingShopping: 0,
      );
      final congel = r.where((x) => x.kind == ReminderKind.congelador).toList();
      expect(congel.length, 3);
      expect(
        congel.any((x) => x.urgency == ReminderUrgency.urgente),
        isTrue, // Merluza ya tocaba
      );
    });

    test('no avisa de caducidad de lo que está congelado', () {
      final r = buildReminders(
        mealsToday: const [],
        stock: const [
          ReminderStockItem(
            name: 'Ternera',
            daysUntilExpiry: 0,
            isFrozen: true,
          ),
        ],
        takeOuts: const [],
        tasksToday: const [],
        pendingShopping: 0,
      );
      expect(r.where((x) => x.kind == ReminderKind.caducidad), isEmpty);
    });

    test('compra pendiente genera un único recordatorio resumen', () {
      final r = buildReminders(
        mealsToday: const [],
        stock: const [],
        takeOuts: const [],
        tasksToday: const [],
        pendingShopping: 3,
      );
      final compra = r.where((x) => x.kind == ReminderKind.compra).toList();
      expect(compra.length, 1);
      expect(compra.first.text.contains('3'), isTrue);
    });

    test('caduca a 5 días no aparece (solo <=3)', () {
      final r = buildReminders(
        mealsToday: const [],
        stock: const [ReminderStockItem(name: 'Arroz', daysUntilExpiry: 5)],
        takeOuts: const [],
        tasksToday: const [],
        pendingShopping: 0,
      );
      expect(r, isEmpty);
    });
  });
}
