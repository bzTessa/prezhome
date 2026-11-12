import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/taper_sync.dart';

void main() {
  test('solo quedan los tápers automáticos que el plan nuevo ya no come', () {
    final items = [
      // Sigue en el plan: se queda.
      {
        'id': 'a',
        'name': 'Lentejas (vie 14)',
        'recipe_id': 'r1',
        'best_before': '2026-11-14',
      },
      // El plan nuevo come otra cosa ese día: huérfano.
      {
        'id': 'b',
        'name': 'Arroz al horno (sáb 15)',
        'recipe_id': 'r2',
        'best_before': '2026-11-15',
      },
      // Puesto a mano (sin "(día N)"): no se toca.
      {
        'id': 'c',
        'name': 'Sopa de la abuela',
        'recipe_id': 'r3',
        'best_before': '2026-11-15',
      },
      // Su comida se marcó "como fuera": huérfano.
      {
        'id': 'd',
        'name': 'Crema (dom 16)',
        'recipe_id': 'r4',
        'best_before': '2026-11-16T00:00:00',
      },
    ];
    final plan = [
      {'plan_date': '2026-11-14', 'recipe_id': 'r1', 'skipped': false},
      {'plan_date': '2026-11-15', 'recipe_id': 'r9', 'skipped': false},
      {'plan_date': '2026-11-16', 'recipe_id': 'r4', 'skipped': true},
    ];
    expect(orphanTapers(items, plan).map((o) => o.id), ['b', 'd']);
  });
}
