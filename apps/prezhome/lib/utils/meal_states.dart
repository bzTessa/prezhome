/// Estado de una comida del día en el Plan: ya pasada, la siguiente que toca
/// o ninguna de las dos.
enum MealSlotState { normal, done, next }

/// Estados de las comidas de hoy. Una comida con plato pasa a hecha una hora
/// después de su hora ("14:00"); la primera con plato que aún no ha pasado
/// es la que toca. Las comidas sin plato o sin hora se quedan normales.
Map<String, MealSlotState> mealSlotStates(
  List<({String type, String? time, bool filled})> slots,
  DateTime now,
) {
  final out = <String, MealSlotState>{};
  var nextFound = false;
  for (final s in slots) {
    final at = _at(s.time, now);
    if (!s.filled || at == null) {
      out[s.type] = MealSlotState.normal;
    } else if (!now.isBefore(at.add(const Duration(hours: 1)))) {
      out[s.type] = MealSlotState.done;
    } else if (!nextFound) {
      nextFound = true;
      out[s.type] = MealSlotState.next;
    } else {
      out[s.type] = MealSlotState.normal;
    }
  }
  return out;
}

DateTime? _at(String? hhmm, DateTime day) {
  final parts = hhmm?.split(':');
  if (parts == null || parts.length != 2) return null;
  final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}
