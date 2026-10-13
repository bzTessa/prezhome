import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/spend_forecast.dart';

void main() {
  test('sin historial, extrapola el ritmo del mes', () {
    final f = forecastMonthSpend(
      spentSoFar: 100,
      today: DateTime(2026, 4, 10), // abril: 30 días
      previousMonths: const [],
    );
    expect(f, closeTo(300, 0.01));
  });

  test('al principio del mes pesa la media de meses anteriores', () {
    final f = forecastMonthSpend(
      spentSoFar: 10,
      today: DateTime(2026, 4, 1),
      previousMonths: const [400, 0, 400],
    );
    expect(f, greaterThan(380));
  });

  test('nunca baja de lo ya gastado', () {
    final f = forecastMonthSpend(
      spentSoFar: 500,
      today: DateTime(2026, 4, 29),
      previousMonths: const [100],
    );
    expect(f, greaterThanOrEqualTo(500));
  });
}
