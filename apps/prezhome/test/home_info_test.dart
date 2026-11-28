import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/home_info_screen.dart';

void main() {
  final today = DateTime(2026, 11, 28);

  test('garantía: caducada, a punto de acabar o bien', () {
    expect(warrantyState(null, today), isNull);
    expect(warrantyState(DateTime(2026, 11, 27), today), 'expired');
    expect(warrantyState(DateTime(2026, 11, 28), today), 'soon');
    expect(warrantyState(DateTime(2027, 1, 27), today), 'soon');
    expect(warrantyState(DateTime(2027, 6, 1), today), 'ok');
  });

  test('el wifi se comparte con red y contraseña', () {
    const w = HomeInfoItem(
      homeId: 'h',
      kind: 'wifi',
      title: 'MiCasa_5G',
      detail: 'gato1234',
    );
    expect(
      wifiShareText(w, 'Red', 'Contraseña'),
      'Red: MiCasa_5G\nContraseña: gato1234',
    );
  });

  test('los campos vacíos se guardan como null', () {
    const c = HomeInfoItem(
      homeId: 'h',
      kind: 'contact',
      title: ' Fontanero ',
      detail: '  ',
      phone: '600 000 000',
    );
    expect(c.toMap(), {
      'home_id': 'h',
      'kind': 'contact',
      'title': 'Fontanero',
      'detail': null,
      'phone': '600 000 000',
      'valid_until': null,
    });
  });
}
