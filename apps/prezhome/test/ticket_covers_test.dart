import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/shopping_checkout.dart';

void main() {
  test('El ticket tacha lo que es de la lista y nada más', () {
    expect(ticketCovers('Garbanzos cocidos', 'garbanzos'), isTrue);
    expect(ticketCovers('Tomates pera', 'Tomate'), isTrue);
    expect(ticketCovers('Leche entera Hacendado', 'Leche entera'), isTrue);
    expect(ticketCovers('Leche entera', 'Leche de avena'), isFalse);
    expect(ticketCovers('Coulant de chocolate', 'Pan'), isFalse);
    expect(ticketCovers('Panceta', 'Pan'), isFalse);
    expect(ticketCovers('Limones', 'limón'), isTrue);
    expect(ticketCovers('Pan', ''), isFalse);
  });
}
