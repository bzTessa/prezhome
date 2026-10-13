import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';

HomeTask t(String id, {String? to, DateTime? due}) =>
    HomeTask(id: id, homeId: 'h', title: id, assignedTo: to, nextDue: due);

void main() {
  final today = DateTime(2026, 10, 13); // martes

  test('Filtro: sin asignar sale siempre', () {
    expect(taskMatchesFilter(t('a'), 'u1'), isTrue);
    expect(taskMatchesFilter(t('a', to: 'u2'), 'u1'), isFalse);
    expect(taskMatchesFilter(t('a', to: 'u2'), null), isTrue);
  });

  test('Próximas agrupa por día y deja Sin fecha al final', () {
    final g = groupUpcomingByDay([
      t('a', due: DateTime(2026, 10, 14)),
      t('b', due: DateTime(2026, 10, 14)),
      t('c', due: DateTime(2026, 10, 15)),
      t('d'),
    ], today);
    expect(g.map((e) => e.key), ['Mañana', 'Jueves 15', 'Sin fecha']);
    expect(g.first.value.length, 2);
  });
}
