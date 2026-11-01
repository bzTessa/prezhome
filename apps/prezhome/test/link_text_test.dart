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

  test('Instagram: enlace para incrustar y descripción del post', () {
    expect(
      instagramEmbedUrl('https://www.instagram.com/reel/DAbc_12-x/?igsh=xyz'),
      'https://www.instagram.com/p/DAbc_12-x/embed/captioned/',
    );
    expect(
      instagramEmbedUrl('https://instagram.com/cocina.ana/p/C0iU0Zg/'),
      'https://www.instagram.com/p/C0iU0Zg/embed/captioned/',
    );
    expect(instagramEmbedUrl('https://www.instagram.com/cocina.ana/'), isNull);
    const html =
        '<div class="Caption"><a class="CaptionUsername" href="/ana">ana</a>'
        '<br /><br />Bizcocho &amp; yogur<br />3 huevos<br />200 g harina '
        '<a href="/explore/tags/receta/">#receta</a>'
        '<div class="CaptionComments"><div>muy rico</div></div></div>';
    expect(
      instagramCaption(html),
      'Bizcocho & yogur\n3 huevos\n200 g harina #receta',
    );
    expect(instagramCaption('<div class="EmbedOther">x</div>'), isNull);
  });

  test('TikTok: subtítulos automáticos del vídeo', () {
    const html =
        '{"desc":"Tarta","video":{"subtitleInfos":[{"LanguageCodeName":"spa-ES",'
        r'"Url":"https:\/\/v16m.tiktokcdn.com\/sub?a=1&b=2","Format":"webvtt"}]}}';
    expect(
      tiktokSubtitlesUrl(html, 'www.tiktok.com'),
      'https://v16m.tiktokcdn.com/sub?a=1&b=2',
    );
    expect(tiktokSubtitlesUrl(html, 'example.com'), isNull);
    expect(
      vttText(
        'WEBVTT\n\n\n00:00:00.183 --> 00:00:00.960\nAl loro porque\n\n'
        '00:00:05.023 --> 00:00:07.280\npon 900 g de queso crema\n',
      ),
      'Al loro porque pon 900 g de queso crema',
    );
  });
}
