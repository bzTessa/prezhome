import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/link_text.dart';

void main() {
  test('TikTok: lee la descripción completa, no la recortada', () {
    const html =
        '<meta property="og:title" content="Tarta La Viña">'
        '<meta property="og:description" content="TARTA DE QUESO...">'
        '<script>{"desc":"INGREDIENTES: 900 grs. queso \\"crema\\"\\n5 huevos"}</script>';
    expect(
      extractPostText(html, 'www.tiktok.com'),
      'Tarta La Viña. INGREDIENTES: 900 grs. queso "crema"\n5 huevos',
    );
  });

  test('YouTube: shortDescription', () {
    const html =
        '{"shortDescription":"Ingredientes:\\n- 200 g lentejas\\n- 1 chorizo"}';
    expect(
      extractPostText(html, 'www.youtube.com'),
      'Ingredientes:\n- 200 g lentejas\n- 1 chorizo',
    );
  });

  test('Instagram/web: og:description con entidades', () {
    const html =
        '<meta content="10 likes - ana: &quot;Bizcocho&quot; 3 huevos '
        '&amp; 200 g harina &#x1F370;" property="og:description">';
    expect(
      extractPostText(html, 'www.instagram.com'),
      '10 likes - ana: "Bizcocho" 3 huevos & 200 g harina 🍰',
    );
  });

  test('"desc" fuera de TikTok no cuenta y sin texto útil devuelve null', () {
    expect(
      extractPostText(
        '{"desc":"cosas de otra web muy largas aquí y más"}',
        'example.com',
      ),
      isNull,
    );
    expect(
      extractPostText(
        '<meta property="og:title" content="TikTok">',
        'www.tiktok.com',
      ),
      isNull,
    );
  });
}
