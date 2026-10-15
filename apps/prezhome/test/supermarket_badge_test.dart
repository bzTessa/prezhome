import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/supermarket_badge.dart';

void main() {
  test('iniciales de la insignia del súper', () {
    expect(SupermarketBadge.initials('Mercadona'), 'M');
    expect(SupermarketBadge.initials('El Corte Inglés / Hipercor'), 'EC');
    expect(SupermarketBadge.initials('Dia'), 'D');
  });
}
