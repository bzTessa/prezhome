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
          id: '3',
          homeId: 'h',
          title: 'Tender',
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
        (DateTime(2026, 10, 22, 18, 30), 'Tocan 2 tareas'),
        (DateTime(2026, 10, 22, 20), 'Llevas 4 días con la casa al día'),
        (DateTime(2026, 10, 23, 10), 'Mañana caducan 2 productos'),
        (DateTime(2026, 10, 23, 20), '¿Cómo va la casa hoy?'),
        (DateTime(2026, 10, 24, 20), 'Tu racha sigue viva'),
      ],
    );
    expect(list[0].body, startsWith('Regar y Tender.'));
    expect(list[2].body, startsWith('leche y yogur.'));
    expect(
      [for (final r in list) r.kind],
      ['tasks', 'streak', 'expiry', 'streak', 'streak'],
    );
  });

  test('avisa del hito de racha que se alcanza hoy', () {
    final list = Reminders.plan(
      tasks: const [],
      items: const [],
      streak: const Streak(days: 6, doneToday: false),
      now: now,
    );
    expect(list.first.title, 'Hoy llegas a 7 días');
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

  test('la noche antes: sacar del congelador y cocinar en lote', () {
    final list = Reminders.plan(
      tasks: const [],
      items: const [],
      streak: null,
      now: now,
      defrost: {
        DateTime(2026, 10, 23): ['Lentejas'],
        DateTime(2026, 10, 25): ['Pisto', 'Albóndigas'],
      },
      cookDays: {DateTime(2026, 10, 24): 8},
    );
    expect(list.every((r) => r.kind == 'kitchen'), isTrue);
    expect(list.map((r) => r.at), [
      DateTime(2026, 10, 22, 21, 30),
      DateTime(2026, 10, 23, 20, 30),
      DateTime(2026, 10, 24, 21, 30),
    ]);
    expect(list[0].title, 'Saca Lentejas del congelador');
    expect(list[1].title, 'Mañana toca cocinar en lote');
    expect(list[1].body, contains('8 raciones'));
    expect(list[2].title, 'Saca 2 platos del congelador');
    expect(list[2].body, startsWith('Pisto y Albóndigas.'));
  });
}
