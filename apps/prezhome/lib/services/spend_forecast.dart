/// Previsión del gasto del mes: mezcla el ritmo de este mes con la media de
/// los meses anteriores. Al principio del mes pesa más la media; al final,
/// lo ya gastado. Nunca baja de lo gastado.
double forecastMonthSpend({
  required double spentSoFar,
  required DateTime today,
  required List<double> previousMonths,
}) {
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  final pace = spentSoFar / today.day * daysInMonth;
  final past = previousMonths.where((m) => m > 0).toList();
  if (past.isEmpty) return pace;
  final avg = past.reduce((a, b) => a + b) / past.length;
  final weight = today.day / daysInMonth;
  final mixed = weight * pace + (1 - weight) * avg;
  return mixed < spentSoFar ? spentSoFar : mixed;
}
