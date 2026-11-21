import 'dart:convert';

import 'package:http/http.dart' as http;

const _headers = {
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
  'Accept-Language': 'es,en',
};

/// Resultado público extraído desde el móvil al abrir el enlace de una receta:
/// texto útil, imagen de portada del vídeo/web y URL final tras redirecciones.
class LinkPreview {
  const LinkPreview({this.text, this.imageUrl, this.resolvedUrl});

  final String? text;
  final String? imageUrl;
  final String? resolvedUrl;
}

/// Lee desde el MÓVIL el texto público de un post (TikTok, YouTube, Instagram
/// o una web). Conservado por compatibilidad: delega en [fetchLinkPreview].
Future<String?> fetchLinkText(String url, {http.Client? client}) async =>
    (await fetchLinkPreview(url, client: client)).text;

/// Extrae desde el MÓVIL texto público, portada y URL final de un enlace de
/// receta (TikTok, YouTube, Instagram con `/share/...`, webs con JSON-LD o OG).
/// Best-effort: no lanza; los campos ausentes quedan en null.
Future<LinkPreview> fetchLinkPreview(String url, {http.Client? client}) async {
  final c = client ?? http.Client();
  Future<http.Response> get(String u) => c
      .get(Uri.parse(u), headers: _headers)
      .timeout(const Duration(seconds: 8));
  try {
    String? embedCover;
    // Instagram pide iniciar sesión en la página del post, pero no en la
    // versión para incrustar en webs, que trae la descripción entera y foto.
    final embed = instagramEmbedUrl(url);
    if (embed != null) {
      final res = await get(embed);
      if (res.statusCode == 200) {
        final embedHtml = utf8.decode(res.bodyBytes, allowMalformed: true);
        embedCover = extractPostImage(embedHtml, 'www.instagram.com', url: url);
        final caption = instagramCaption(embedHtml);
        if (caption != null) {
          return LinkPreview(
            text: caption,
            imageUrl: embedCover,
            resolvedUrl: url,
          );
        }
      }
    }

    final res = await get(url);
    if (res.statusCode != 200) {
      return embedCover != null
          ? LinkPreview(imageUrl: embedCover, resolvedUrl: url)
          : const LinkPreview();
    }
    final resolved = res.request?.url.toString() ?? url;
    final host = res.request?.url.host ?? Uri.parse(url).host;
    final html = utf8.decode(res.bodyBytes, allowMalformed: true);
    final pageCover = extractPostImage(html, host, url: resolved) ?? embedCover;

    // Enlaces compartidos (`instagram.com/share/reel/...`) redirigen a `/reel/CODE/`:
    // con la URL resuelta ya podemos pedir el embed completo.
    if (embed == null) {
      final redirectedEmbed = instagramEmbedUrl(resolved);
      if (redirectedEmbed != null) {
        final embRes = await get(redirectedEmbed);
        if (embRes.statusCode == 200) {
          final embedHtml = utf8.decode(embRes.bodyBytes, allowMalformed: true);
          final caption = instagramCaption(embedHtml);
          final cover =
              extractPostImage(embedHtml, 'www.instagram.com', url: resolved) ??
              pageCover;
          if (caption != null) {
            return LinkPreview(
              text: caption,
              imageUrl: cover,
              resolvedUrl: resolved,
            );
          }
        }
      }
    }

    final text = extractPostText(html, host);
    final subs = tiktokSubtitlesUrl(html, host);
    if (subs == null) {
      return LinkPreview(
        text: text,
        imageUrl: pageCover,
        resolvedUrl: resolved,
      );
    }
    final said = await get(subs).then(
      (r) => r.statusCode == 200 ? vttText(utf8.decode(r.bodyBytes)) : '',
      onError: (_) => '',
    );
    if (said.isEmpty) {
      return LinkPreview(
        text: text,
        imageUrl: pageCover,
        resolvedUrl: resolved,
      );
    }
    return LinkPreview(
      text: '${text ?? ''}\n\nLo que se dice en el vídeo: $said'.trim(),
      imageUrl: pageCover,
      resolvedUrl: resolved,
    );
  } catch (_) {
    return const LinkPreview();
  } finally {
    if (client == null) c.close();
  }
}

/// `instagram.com/p/CÓDIGO` (o reel, reels, tv, `instagr.am`) → su página para
/// incrustar. No casa `/share/...` hasta resolver su redirección.
String? instagramEmbedUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null ||
      !RegExp(
        r'(^|\.)(?:instagram\.com|instagr\.am)$',
        caseSensitive: false,
      ).hasMatch(u.host)) {
    return null;
  }
  if (RegExp(
    r'^/(?:share|explore|stories|accounts)/',
    caseSensitive: false,
  ).hasMatch(u.path)) {
    return null;
  }
  final m = RegExp(
    r'^/(?:[\w.]+/)?(?:p|reels?|tv)/([\w-]+)',
  ).firstMatch(u.path);
  return m == null
      ? null
      : 'https://www.instagram.com/p/${m.group(1)}/embed/captioned/';
}

/// Descripción del post en la página para incrustar de Instagram.
String? instagramCaption(String html) {
  final start = html.indexOf('class="Caption"');
  if (start < 0) return null;
  var end = html.indexOf('class="CaptionComments"', start);
  end = end < 0 ? html.indexOf('</div>', start) : html.lastIndexOf('<', end);
  if (end < 0) return null;
  var body = html.substring(html.indexOf('>', start) + 1, end);
  // Fuera el nombre de la cuenta, saltos de línea a \n y sin etiquetas.
  body = body
      .replaceFirst(RegExp(r'<a[^>]*CaptionUsername[^>]*>.*?</a>'), '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '');
  final text = _decode(body).trim();
  return text.length >= 40 ? text : null;
}

/// Subtítulos automáticos del vídeo de TikTok (WebVTT), o null.
String? tiktokSubtitlesUrl(String html, String host) {
  if (!RegExp(r'(^|\.)tiktok\.com$', caseSensitive: false).hasMatch(host)) {
    return null;
  }
  final i = html.indexOf('"subtitleInfos"');
  if (i < 0) return null;
  final m = RegExp(r'"Url":("(?:[^"\\]|\\.)*")').firstMatch(html.substring(i));
  if (m == null) return null;
  final u = jsonDecode(m.group(1)!) as String;
  return u.startsWith('https://') ? u : null;
}

/// Solo el texto de un WebVTT (sin cabecera ni tiempos).
String vttText(String vtt) => vtt
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty && l != 'WEBVTT' && !l.contains('-->'))
    .join(' ');

/// Saca la descripción del post del HTML: completa incrustada (YouTube
/// `shortDescription`, TikTok `desc`), JSON-LD `schema.org/Recipe` de blogs, o
/// los metadatos Open Graph (`og:description`/`description`).
String? extractPostText(String html, String host) {
  final title = _meta(html, 'og:title');
  var full = _jsonString(html, 'shortDescription');
  if (full == null &&
      RegExp(r'(^|\.)tiktok\.com$', caseSensitive: false).hasMatch(host)) {
    full = _jsonString(html, 'desc');
  }
  final jsonLd = full == null ? extractJsonLdRecipe(html) : null;
  if (jsonLd != null) return jsonLd;
  full ??= _meta(html, 'og:description') ?? _meta(html, 'description');
  final text = [title, full].whereType<String>().join('. ').trim();
  // Con menos que esto no hay receta: mejor que el servidor lo intente él.
  return text.length >= 40 ? text : null;
}

/// Id del vídeo de YouTube (watch, youtu.be, shorts, embed, live) o null.
String? youtubeVideoId(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return null;
  final host = u.host.toLowerCase().replaceFirst(
    RegExp(r'^(www|m|music)\.'),
    '',
  );
  String? id;
  if (host == 'youtu.be') {
    final segs = u.pathSegments;
    if (segs.isNotEmpty) id = segs.first;
  } else if (host == 'youtube.com') {
    id =
        u.queryParameters['v'] ??
        RegExp(r'^/(?:shorts|embed|live)/([^/]+)').firstMatch(u.path)?.group(1);
  }
  return id != null && RegExp(r'^[\w-]{11}$').hasMatch(id) ? id : null;
}

/// Extrae una receta estructurada en JSON-LD (`schema.org/Recipe`) del HTML,
/// o null si la página no incluye ingredientes ni pasos válidos.
String? extractJsonLdRecipe(String html) {
  final recipe = _findJsonLdRecipe(html);
  if (recipe == null) return null;

  String cleanText(Object? v) =>
      _decode(v?.toString() ?? '').replaceAll(RegExp(r'<[^>]*>'), ' ').trim();

  final ingredients = _jsonLdIngredients(recipe['recipeIngredient'], cleanText);
  final steps = _jsonLdSteps(recipe['recipeInstructions'], cleanText);
  if (ingredients.isEmpty && steps.isEmpty) return null;

  final lines = <String>[];
  final name = cleanText(recipe['name']);
  if (name.isNotEmpty) lines.add(name);
  final desc = cleanText(recipe['description']);
  if (desc.isNotEmpty) lines.add(desc);

  final meta = <String>[];
  final yieldVal = _jsonLdFirstText(recipe['recipeYield'], cleanText);
  if (yieldVal != null) meta.add('Raciones: $yieldVal');
  final prep = _formatIsoDuration(cleanText(recipe['prepTime']));
  if (prep != null) meta.add('Prep: $prep');
  final cook = _formatIsoDuration(cleanText(recipe['cookTime']));
  if (cook != null) meta.add('Cocción: $cook');
  final total = _formatIsoDuration(cleanText(recipe['totalTime']));
  if (total != null && prep == null && cook == null) meta.add('Total: $total');
  if (meta.isNotEmpty) lines.add(meta.join(' · '));

  if (ingredients.isNotEmpty) {
    lines.add('');
    lines.add('Ingredientes:');
    for (final ing in ingredients) {
      lines.add('- $ing');
    }
  }
  if (steps.isNotEmpty) {
    lines.add('');
    lines.add('Pasos:');
    for (var i = 0; i < steps.length; i++) {
      lines.add('${i + 1}. ${steps[i]}');
    }
  }
  return lines.join('\n').trim();
}

/// Extrae la imagen de un bloque JSON-LD `schema.org/Recipe` si es URL pública.
String? extractJsonLdImage(String html) {
  final recipe = _findJsonLdRecipe(html);
  if (recipe == null) return null;
  return _firstHttpImage(recipe['image']);
}

/// Portada pública de un vídeo o web de receta (`JSON-LD` → embed Instagram →
/// Open Graph/Twitter → miniatura de YouTube).
String? extractPostImage(String html, String host, {String? url}) {
  final jsonLd = extractJsonLdImage(html);
  if (jsonLd != null) return jsonLd;

  if (RegExp(
    r'(^|\.)(?:instagram\.com|instagr\.am)$',
    caseSensitive: false,
  ).hasMatch(host)) {
    for (final re in [
      RegExp(
        r'''<img[^>]+class=["'][^"']*EmbeddedMediaImage[^"']*["'][^>]*src=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<img[^>]+src=["']([^"']+)["'][^>]*class=["'][^"']*EmbeddedMediaImage[^"']*["']''',
        caseSensitive: false,
      ),
    ]) {
      final m = re.firstMatch(html);
      final src = m != null ? _validHttpUrl(_decode(m.group(1)!.trim())) : null;
      if (src != null) return src;
    }
  }

  for (final key in ['og:image', 'og:image:secure_url', 'twitter:image']) {
    final m = _meta(html, key);
    final v = m != null ? _validHttpUrl(m) : null;
    if (v != null) return v;
  }

  if (url != null) {
    final id = youtubeVideoId(url);
    if (id != null) return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  }
  return null;
}

Map<String, dynamic>? _findJsonLdRecipe(String html) {
  final scriptRe = RegExp(
    r'''<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)</script>''',
    caseSensitive: false,
  );
  for (final m in scriptRe.allMatches(html)) {
    final raw = m.group(1)?.trim();
    if (raw == null || raw.isEmpty) continue;
    try {
      final decoded = jsonDecode(raw);
      final found = _walkJsonLd(decoded);
      if (found != null) return found;
    } catch (_) {
      // Bloques JSON-LD malformados en blogs se ignoran sin romper el resto.
    }
  }
  return null;
}

Map<String, dynamic>? _walkJsonLd(Object? node) {
  if (node is List) {
    for (final item in node) {
      final found = _walkJsonLd(item);
      if (found != null) return found;
    }
    return null;
  }
  if (node is! Map) return null;
  final map = Map<String, dynamic>.from(node);
  if (_isRecipeType(map['@type'])) return map;
  if (map['@graph'] != null) {
    final found = _walkJsonLd(map['@graph']);
    if (found != null) return found;
  }
  if (map['mainEntity'] != null) {
    final found = _walkJsonLd(map['mainEntity']);
    if (found != null) return found;
  }
  return null;
}

bool _isRecipeType(Object? raw) {
  bool matchesOne(Object? v) {
    final s = v?.toString().trim().toLowerCase() ?? '';
    return s == 'recipe' || s.endsWith('/recipe') || s.endsWith(':recipe');
  }

  if (raw is List) return raw.any(matchesOne);
  return matchesOne(raw);
}

List<String> _jsonLdIngredients(Object? raw, String Function(Object?) clean) {
  if (raw is! List) {
    final one = clean(raw);
    return one.isEmpty ? const [] : [one];
  }
  return [
    for (final e in raw)
      if (e is Map) clean(e['text'] ?? e['name']) else clean(e),
  ].where((s) => s.isNotEmpty).toList();
}

List<String> _jsonLdSteps(Object? raw, String Function(Object?) clean) {
  final out = <String>[];
  void collect(Object? item) {
    if (item == null) return;
    if (item is List) {
      for (final sub in item) {
        collect(sub);
      }
      return;
    }
    if (item is Map) {
      final inner = item['itemListElement'];
      if (inner != null) {
        final sectionName = clean(item['name']);
        if (sectionName.isNotEmpty) out.add(sectionName);
        collect(inner);
        return;
      }
      final t = clean(item['text'] ?? item['name']);
      if (t.isNotEmpty) out.add(t);
      return;
    }
    final text = clean(item);
    if (text.isNotEmpty) {
      for (final line in text.split(RegExp(r'\r?\n+'))) {
        final s = line.trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
  }

  collect(raw);
  return out;
}

String? _jsonLdFirstText(Object? raw, String Function(Object?) clean) {
  if (raw is List) {
    for (final e in raw) {
      final s = clean(e);
      if (s.isNotEmpty) return s;
    }
    return null;
  }
  final s = clean(raw);
  return s.isEmpty ? null : s;
}

String? _formatIsoDuration(String raw) {
  if (raw.isEmpty) return null;
  final m = RegExp(
    r'^P(?:\d+D)?(?:T(?:(\d+)H)?(?:(\d+)M)?)?$',
    caseSensitive: false,
  ).firstMatch(raw);
  if (m == null) return raw;
  final h = int.tryParse(m.group(1) ?? '');
  final mins = int.tryParse(m.group(2) ?? '');
  final total = (h ?? 0) * 60 + (mins ?? 0);
  if (total <= 0) return null;
  return '$total min';
}

String? _firstHttpImage(Object? raw) {
  if (raw is String) return _validHttpUrl(_decode(raw.trim()));
  if (raw is List) {
    for (final item in raw) {
      final found = _firstHttpImage(item);
      if (found != null) return found;
    }
    return null;
  }
  if (raw is Map) {
    return _firstHttpImage(raw['url'] ?? raw['contentUrl']);
  }
  return null;
}

String? _validHttpUrl(String raw) {
  final u = Uri.tryParse(raw);
  if (u == null) return null;
  if ((u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty) {
    return raw;
  }
  return null;
}

String? _jsonString(String html, String key) {
  final m = RegExp('"$key":("(?:[^"\\\\]|\\\\.)*")').firstMatch(html);
  if (m == null) return null;
  try {
    final s = (jsonDecode(m.group(1)!) as String).trim();
    return s.isEmpty ? null : s;
  } catch (_) {
    return null;
  }
}

String? _meta(String html, String key) {
  for (final re in [
    RegExp(
      '<meta[^>]+(?:property|name)=["\']$key["\'][^>]*content="([^"]*)"',
      caseSensitive: false,
    ),
    RegExp(
      '<meta[^>]+content="([^"]*)"[^>]*(?:property|name)=["\']$key["\']',
      caseSensitive: false,
    ),
  ]) {
    final m = re.firstMatch(html);
    if (m != null && m.group(1)!.trim().isNotEmpty) {
      return _decode(m.group(1)!.trim());
    }
  }
  return null;
}

const _entities = {'&quot;': '"', '&lt;': '<', '&gt;': '>', '&nbsp;': ' '};

String _decode(String s) {
  s = s.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final hex = m.group(1)!.isNotEmpty;
    return String.fromCharCode(int.parse(m.group(2)!, radix: hex ? 16 : 10));
  });
  _entities.forEach((k, v) => s = s.replaceAll(k, v));
  return s.replaceAll('&amp;', '&');
}
