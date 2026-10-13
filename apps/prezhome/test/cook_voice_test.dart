import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/cook_voice.dart';

void main() {
  test('entiende las órdenes del modo cocina', () {
    expect(parseCookCommand('Siguiente'), CookCommand.next);
    expect(parseCookCommand('vale, listo'), CookCommand.next);
    expect(parseCookCommand('vuelve atrás'), CookCommand.previous);
    expect(parseCookCommand('repítelo otra vez'), CookCommand.repeat);
    expect(parseCookCommand('pon el temporizador'), CookCommand.startTimer);
    expect(parseCookCommand('para el temporizador'), CookCommand.stopTimer);
    expect(parseCookCommand('¿qué ingredientes?'), CookCommand.ingredients);
  });

  test('ignora lo que no es una orden', () {
    expect(parseCookCommand('pásame el listón'), isNull);
    expect(parseCookCommand(''), isNull);
    expect(parseCookCommand('para la cena'), isNull);
  });
}
