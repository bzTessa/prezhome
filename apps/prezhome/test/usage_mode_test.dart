import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/dashboard_prefs.dart';
import 'package:prezhome/models/usage_mode.dart';

void main() {
  test('aplicar un modo y reconocerlo después', () {
    final base = DashboardPrefs.defaults();
    for (final m in UsageMode.choices) {
      final p = m.applyTo(base);
      expect(UsageMode.of(p), m);
      expect(p.order, base.order);
    }
  });

  test('una mezcla a mano es personalizada', () {
    final p = UsageMode.essential
        .applyTo(DashboardPrefs.defaults())
        .copyWith(enabledModules: {HomeModule.tasks});
    expect(UsageMode.of(p), UsageMode.custom);
  });

  test('esencial apaga tareas, puntos y calorías', () {
    final p = UsageMode.essential.applyTo(DashboardPrefs.defaults());
    expect(p.isModuleEnabled(HomeModule.tasks), isFalse);
    expect(p.isModuleEnabled(HomeModule.points), isFalse);
    expect(p.trackCalories, isFalse);
  });
}
