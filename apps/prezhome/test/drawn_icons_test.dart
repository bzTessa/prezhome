import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/drawn_icons.dart';

void main() {
  tearDown(() => DrawnIcons.fetch = null);

  test('sin fetch no hay dibujos', () {
    expect(DrawnIcons.urlFor('Quinoa'), isNull);
  });

  test('una petición por producto y los fallos se quedan sin dibujo', () async {
    final asked = <String>[];
    DrawnIcons.fetch = (key, {again = false}) async {
      asked.add(key);
      if (key == 'tofu') throw Exception('sin cupo');
      return 'https://x/storage/v1/object/public/recipe-images/icons/$key.png';
    };
    expect(await DrawnIcons.urlFor('Quinoa'), contains('/icons/quinoa.png'));
    expect(await DrawnIcons.urlFor('quinoa'), contains('/icons/quinoa.png'));
    expect(await DrawnIcons.urlFor('Tofu'), isNull);
    expect(asked, ['quinoa', 'tofu']);
    // Pedido por la persona: se reintenta y el fallo llega a la pantalla.
    expect(DrawnIcons.urlFor('Tofu', retry: true), throwsException);
  });

  test('reconoce las URL de iconos dibujados', () {
    expect(
      DrawnIcons.isDrawn(
        'https://x.supabase.co/storage/v1/object/public/recipe-images/icons/quinoa.png',
      ),
      isTrue,
    );
    expect(
      DrawnIcons.isDrawn(
        'https://x.supabase.co/storage/v1/object/public/recipe-images/generic/cebolla.jpg',
      ),
      isFalse,
    );
    expect(DrawnIcons.isDrawn(null), isFalse);
  });
}
