import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/services/reminders.dart';
import 'package:prezhome/services/streak.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  InventoryItem item(String name, DateTime d) => InventoryItem(
    id: name,
    homeId: 'h',
    name: name,
    category: 'Nevera',
    quantity: 1,
    unit: 'ud',
    expirationDate: d,
  );

  test('tareas a su hora, caducidades agrupadas y racha', () {
    final list = Reminders.plan(
      tasks: [
        HomeTask(
          id: '1',
          homeId: 'h',
          title: 'Regar',
          dueDate: DateTime(2026, 10, 22),
          dueTime: '18:30',
        ),
        HomeTask(
          id: '2',
          homeId: 'h',
          title: 'Ya pasó',
          dueDate: DateTime(2026, 10, 22),
          dueTime: '09:00',
        ),
      ],
      items: [
        item('leche', DateTime(2026, 10, 24)),
        item('yogur', DateTime(2026, 10, 24)),
        item('pan', DateTime(2026, 10, 22)),
      ],
      streak: const Streak(days: 4, doneToday: false),
      now: now,
    );
    expect(
      [for (final r in list) (r.at, r.title)],
      [
        (DateTime(2026, 10, 22, 18, 30), 'Toca: Regar'),
        (DateTime(2026, 10, 22, 20), 'Tu racha te espera'),
        (DateTime(2026, 10, 23, 10), 'Mañana caducan 2 productos'),
        (DateTime(2026, 10, 23, 20), 'Tu racha te espera'),
        (DateTime(2026, 10, 24, 20), 'Tu racha te espera'),
      ],
    );
    expect(list[2].body, 'leche, yogur');
  });

  test('sin racha no se avisa; si hoy ya cuenta, empieza mañana', () {
    List<DateTime> streakAt(Streak s) => [
      for (final r in Reminders.plan(
        tasks: const [],
        items: const [],
        streak: s,
        now: now,
      ))
        r.at,
    ];
    expect(streakAt(const Streak(days: 0, doneToday: false)), isEmpty);
    expect(streakAt(const Streak(days: 3, doneToday: true)), [
      DateTime(2026, 10, 23, 20),
      DateTime(2026, 10, 24, 20),
    ]);
  });
}
