import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/services/calendar_sync.dart';
import 'package:prezhome/services/plan_prefs.dart';

void main() {
  group('Ayuno', () {
    const p = PlanPrefs(fastHours: 16); // cena 21:00 → come de 14:00 a 22:00

    test('ventana para comer según la cena', () {
      expect(p.eatingWindow, (start: 14 * 60, end: 22 * 60));
      expect(p.inFast('breakfast'), isTrue);
      expect(p.inFast('lunch'), isFalse);
      expect(const PlanPrefs().inFast('breakfast'), isFalse);
    });

    test('estado y cuánto queda', () {
      final morning = p.fastAt(DateTime(2026, 10, 14, 10))!;
      expect(morning.fasting, isTrue);
      expect(morning.until, DateTime(2026, 10, 14, 14));
      final night = p.fastAt(DateTime(2026, 10, 14, 23))!;
      expect(night.fasting, isTrue);
      expect(night.until, DateTime(2026, 10, 15, 14));
      final lunch = p.fastAt(DateTime(2026, 10, 14, 15))!;
      expect(lunch.fasting, isFalse);
      expect(lunch.until, DateTime(2026, 10, 14, 22));
    });

    test('cena tarde: la ventana cruza la medianoche', () {
      const late = PlanPrefs(fastHours: 16, times: {'dinner': 23 * 60 + 30});
      final s = late.fastAt(DateTime(2026, 10, 15, 0, 15))!;
      expect(s.fasting, isFalse);
      expect(s.until, DateTime(2026, 10, 15, 0, 30));
    });
  });

  group('Calendario', () {
    test('primer hueco libre que no pisa nada', () {
      final day = DateTime(2026, 10, 14);
      final busy = [
        (start: DateTime(2026, 10, 14, 8), end: DateTime(2026, 10, 14, 9, 15)),
      ];
      expect(
        CalendarSync.freeSlot(busy, day, DateTime(2026, 10, 13)),
        9 * 60 + 30,
      );
      expect(
        CalendarSync.freeSlot(const [], day, DateTime(2026, 10, 14, 18, 10)),
        18 * 60 + 30,
      );
      expect(
        CalendarSync.freeSlot(const [], day, DateTime(2026, 10, 15)),
        isNull,
      );
    });

    test('tareas con hora repetidas dentro de la semana', () {
      final from = DateTime(2026, 10, 14);
      final until = from.add(const Duration(days: 7));
      final events = CalendarSync.taskEvents(
        [
          HomeTask(
            id: '1',
            homeId: 'h',
            title: 'Regar',
            recurrence: 'custom_weekdays',
            weekdays: const [1, 4],
            dueTime: '19:00',
            nextDue: DateTime(2026, 10, 12), // atrasada: va hoy
          ),
          HomeTask(id: '2', homeId: 'h', title: 'Sin hora', nextDue: from),
        ],
        from,
        until,
      );
      expect(events.map((e) => e.start), [
        DateTime(2026, 10, 14, 19),
        DateTime(2026, 10, 15, 19),
        DateTime(2026, 10, 19, 19),
      ]);
    });
  });
}
