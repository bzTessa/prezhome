import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/plan_usage_screen.dart';

void main() {
  test('une cupos del plan con el uso del mes', () {
    final rows = buildPlanUsage(
      'free',
      [
        {'plan': 'free', 'feature': 'scan_ticket', 'monthly_limit': 15},
        {'plan': 'free', 'feature': 'recipes', 'monthly_limit': 15},
        {'plan': 'pro', 'feature': 'scan_ticket', 'monthly_limit': 100},
      ],
      [
        {'feature': 'scan_ticket', 'used': 15},
      ],
    );
    expect(rows.map((r) => r.label), ['Escanear tickets', 'Ideas y recetas']);
    expect(rows[0].left, 0);
    expect(rows[0].limit, 15);
    expect(rows[1].left, 15);
  });
}
