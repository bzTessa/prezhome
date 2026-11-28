import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/ready_learning.dart';

void main() {
  test('Reconoce lo comprado ya hecho', () {
    expect(ReadyLearning.kindOf('Pizza barbacoa Hacendado'), 'main');
    expect(ReadyLearning.kindOf('Lasaña boloñesa congelada'), 'main');
    expect(ReadyLearning.kindOf('Coulant de chocolate'), 'dessert');
    expect(ReadyLearning.kindOf('Helado de vainilla'), 'dessert');
  });

  test('Los ingredientes no cuentan', () {
    expect(ReadyLearning.kindOf('Masa de pizza'), isNull);
    expect(ReadyLearning.kindOf('Tomate frito para pizza'), isNull);
    expect(ReadyLearning.kindOf('Leche entera'), isNull);
    expect(ReadyLearning.kindOf('Fresas'), isNull);
  });

  test('No repite lo guardado, lo rechazado ni duplicados', () {
    final c = ReadyLearning.candidates(
      ['Pizza 4 quesos', 'Pizza 4 quesos', 'Lasaña', 'Coulant', 'Pan'],
      saved: ['lasaña'],
      declined: ['Coulant'],
    );
    expect(c.map((x) => x.name), ['Pizza 4 quesos']);
  });
}
