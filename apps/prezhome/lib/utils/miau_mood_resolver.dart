import '../widgets/miau_character.dart';

/// Decide la pose del gato en la cabecera de "Hoy" según el momento del día y
/// lo que pasa en casa. Función pura y testeable.
MiauMood resolveHomeCatMood({
  required int hour,
  required int expiredCount,
  required int expiringSoonCount,
  required int pendingTasks,
  required int doneTodayTasks,
  required bool hasMealsToday,
  required int pendingShopping,
}) {
  if (hour >= 22 || hour < 6) return MiauMood.sleeping;
  if (expiredCount > 0 || expiringSoonCount >= 2) return MiauMood.worried;
  if (pendingTasks == 0 && doneTodayTasks > 0) return MiauMood.celebrating;
  if (hasMealsToday &&
      ((hour >= 12 && hour < 15) || (hour >= 19 && hour < 22))) {
    return MiauMood.cooking;
  }
  if (pendingShopping >= 5 && hour >= 9 && hour < 20) {
    return MiauMood.shopping;
  }
  return MiauMood.greeting;
}

/// Pose del gato para cada página del cuestionario inicial.
MiauMood onboardingCatMood(int page, {bool hasSelection = false}) {
  switch (page) {
    case 0:
    case 1:
      return MiauMood.greeting;
    case 2:
      return hasSelection ? MiauMood.celebrating : MiauMood.curious;
    case 3:
      return MiauMood.cooking;
    case 4:
      return MiauMood.curious;
    case 5:
      return MiauMood.shopping;
    default:
      return MiauMood.celebrating;
  }
}
