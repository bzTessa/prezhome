import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/scan_ticket_screen.dart';
import 'package:prezhome/widgets/food_category_icon.dart';

void main() {
  test('Categoría del ticket: la suya si es nuestra, si no por el nombre', () {
    expect(guessTicketCategory('lacteos', 'Yogur'), FoodCategory.lacteos);
    expect(
      guessTicketCategory('otros', 'Garbanzos cocidos'),
      CategoryIcons.categoryFor('Garbanzos cocidos'),
    );
    expect(guessTicketCategory('higiene', 'Xyz'), FoodCategory.otros);
  });
}
