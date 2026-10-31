import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/ticket_date.dart';

void main() {
  final now = DateTime(2026, 10, 30);
  test('corrige un año mal leído', () {
    expect(
      plausibleTicketDate(DateTime(2023, 10, 6), now),
      DateTime(2026, 10, 6),
    );
  });
  test('una fecha razonable no cambia', () {
    expect(
      plausibleTicketDate(DateTime(2026, 9, 20), now),
      DateTime(2026, 9, 20),
    );
  });
  test('si al corregir queda en el futuro, usa el año anterior', () {
    expect(
      plausibleTicketDate(DateTime(2023, 12, 20), now),
      DateTime(2025, 12, 20),
    );
  });
}
