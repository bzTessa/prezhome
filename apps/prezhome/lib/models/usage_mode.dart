import 'dashboard_prefs.dart';

/// Cómo usa cada casa PrezHome. Cada modo enciende un grupo de módulos para
/// que la app enseñe solo lo que se va a usar; se puede cambiar cuando
/// quieras y, si se tocan los módulos a mano, queda en [custom].
enum UsageMode {
  /// Compra, despensa y qué comer. Sin tareas, puntos ni calorías.
  essential({}, trackCalories: false),

  /// Lo esencial más cocina en lote y calorías.
  kitchen({HomeModule.batchCooking}, trackCalories: true),

  /// Todo: tareas por turnos, puntos, cocina en lote y calorías.
  complete({
    HomeModule.tasks,
    HomeModule.points,
    HomeModule.batchCooking,
  }, trackCalories: true),

  /// Combinación hecha a mano (no coincide con ningún modo).
  custom({}, trackCalories: true);

  const UsageMode(this.modules, {required this.trackCalories});

  final Set<HomeModule> modules;
  final bool trackCalories;

  /// Los modos que se ofrecen (sin [custom]).
  static const choices = [essential, kitchen, complete];

  /// El modo que corresponde a unas preferencias, o [custom].
  static UsageMode of(DashboardPrefs p) {
    for (final m in choices) {
      if (p.enabledModules.length == m.modules.length &&
          p.enabledModules.containsAll(m.modules) &&
          p.trackCalories == m.trackCalories) {
        return m;
      }
    }
    return custom;
  }

  /// Aplica el modo a [p] conservando todo lo demás.
  DashboardPrefs applyTo(DashboardPrefs p) =>
      p.copyWith(enabledModules: {...modules}, trackCalories: trackCalories);
}
