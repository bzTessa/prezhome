import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prezhome/services/link_text.dart';

class _StubHttpClient extends http.BaseClient {
  _StubHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest req) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

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

  test(
    'Instagram /share/ redirige a embed con texto y portada decodificada',
    () async {
      final requested = <String>[];
      final client = _StubHttpClient((req) async {
        requested.add(req.url.toString());
        if (req.url.path == '/share/reel/xyz') {
          return http.StreamedResponse(
            Stream.value(utf8.encode('<html><body>redirected</body></html>')),
            200,
            request: http.Request(
              'GET',
              Uri.parse('https://www.instagram.com/reel/C9Abc/'),
            ),
          );
        }
        if (req.url.path == '/p/C9Abc/embed/captioned/') {
          const html =
              '<img class="EmbeddedMediaImage" src="https://scontent.example.com/cover.jpg?a=1&amp;b=2" />'
              '<div class="Caption"><a class="CaptionUsername" href="/chef">chef</a>'
              '<br />Pasta rápida<br />200 g espaguetis<br />100 g tomate frito y albahaca fresca</div>';
          return http.StreamedResponse(
            Stream.value(utf8.encode(html)),
            200,
            request: req,
          );
        }
        return http.StreamedResponse(const Stream.empty(), 404, request: req);
      });

      expect(
        instagramEmbedUrl('https://instagr.am/reel/DAbc_12-x/?igsh=xyz'),
        'https://www.instagram.com/p/DAbc_12-x/embed/captioned/',
      );
      expect(
        instagramEmbedUrl('https://www.instagram.com/share/reel/xyz'),
        isNull,
      );

      final preview = await fetchLinkPreview(
        'https://www.instagram.com/share/reel/xyz',
        client: client,
      );
      expect(requested, [
        'https://www.instagram.com/share/reel/xyz',
        'https://www.instagram.com/p/C9Abc/embed/captioned/',
      ]);
      expect(preview.resolvedUrl, 'https://www.instagram.com/reel/C9Abc/');
      expect(
        preview.imageUrl,
        'https://scontent.example.com/cover.jpg?a=1&b=2',
      );
      expect(preview.text, contains('Pasta rápida'));
      expect(preview.text, contains('200 g espaguetis'));
    },
  );

  test('JSON-LD schema.org/Recipe con @graph y HowToSection', () {
    const html = '''
      <html><head>
        <meta property="og:image" content="https://cdn.example.com/og.jpg" />
        <script type="application/ld+json">{
          "@context": "https://schema.org",
          "@graph": [{
            "@type": ["Recipe"],
            "name": "Lentejas caseras",
            "recipeYield": "4 raciones",
            "prepTime": "PT15M",
            "image": {"url": "https://cdn.example.com/lentejas.jpg"},
            "recipeIngredient": ["300 g lentejas", "1 zanahoria"],
            "recipeInstructions": [{
              "@type": "HowToSection",
              "name": "Cocción",
              "itemListElement": [{"@type": "HowToStep", "text": "Cocer 35 minutos."}]
            }]
          }]
        }</script>
      </head></html>
    ''';
    final text = extractPostText(html, 'recetas.example.com');
    expect(text, contains('Lentejas caseras'));
    expect(text, contains('- 300 g lentejas'));
    expect(text, contains('2. Cocer 35 minutos.'));
    expect(
      extractPostImage(html, 'recetas.example.com'),
      'https://cdn.example.com/lentejas.jpg',
    );
  });

  test('extractPostImage cae a og:image y miniatura de YouTube', () {
    const ogHtml =
        '<meta property="og:image" content="https://cdn.example.com/cover.png?w=800&amp;q=80">';
    expect(
      extractPostImage(ogHtml, 'recetas.example.com'),
      'https://cdn.example.com/cover.png?w=800&q=80',
    );
    expect(
      extractPostImage(
        '<html></html>',
        'www.youtube.com',
        url: 'https://www.youtube.com/shorts/dQw4w9WgXcQ',
      ),
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );
  });
}
