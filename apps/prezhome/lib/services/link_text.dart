import 'dart:convert';

import 'package:http/http.dart' as http;

const _headers = {
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
  'Accept-Language': 'es,en',
};

/// Lee desde el MÓVIL el texto público de un post (TikTok, YouTube, Instagram
/// o una web). Instagram, TikTok y YouTube bloquean a los servidores, pero a
/// un móvil normal le sirven la página con la descripción. El texto se manda
/// luego a import-recipe-link como si se hubiera pegado.
/// En TikTok se añade además lo que se DICE en el vídeo (subtítulos
/// automáticos), por si los ingredientes no están escritos.
/// Best-effort: null si no hay red, CORS (web) o la página no trae nada útil.
Future<String?> fetchLinkText(String url, {http.Client? client}) async {
  final c = client ?? http.Client();
  Future<http.Response> get(String u) => c
      .get(Uri.parse(u), headers: _headers)
      .timeout(const Duration(seconds: 8));
  try {
    // Instagram pide iniciar sesión en la página del post, pero no en la
    // versión para incrustar en webs, que trae la descripción entera.
    final embed = instagramEmbedUrl(url);
    if (embed != null) {
      final res = await get(embed);
      final caption = res.statusCode == 200
          ? instagramCaption(utf8.decode(res.bodyBytes, allowMalformed: true))
          : null;
      if (caption != null) return caption;
    }
    final res = await get(url);
    if (res.statusCode != 200) return null;
    final html = utf8.decode(res.bodyBytes, allowMalformed: true);
    // El host final (tras redirecciones de enlaces cortos) decide qué leer.
    final host = res.request?.url.host ?? Uri.parse(url).host;
    final text = extractPostText(html, host);
    final subs = tiktokSubtitlesUrl(html, host);
    if (subs == null) return text;
    final said = await get(subs).then(
      (r) => r.statusCode == 200 ? vttText(utf8.decode(r.bodyBytes)) : '',
      onError: (_) => '',
    );
    if (said.isEmpty) return text;
    return '${text ?? ''}\n\nLo que se dice en el vídeo: $said'.trim();
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// `instagram.com/p/CÓDIGO` (o reel, reels, tv) → su página para incrustar.
String? instagramEmbedUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null || !RegExp(r'(^|\.)instagram\.com$').hasMatch(u.host)) {
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
  if (!RegExp(r'(^|\.)tiktok\.com$').hasMatch(host)) return null;
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

/// Saca la descripción del post del HTML: la completa incrustada (YouTube
/// `shortDescription`, TikTok `desc`) o, si no, los metadatos Open Graph
/// (en Instagram og:description lleva el texto del post).
String? extractPostText(String html, String host) {
  final title = _meta(html, 'og:title');
  String? full = _jsonString(html, 'shortDescription');
  if (full == null && RegExp(r'(^|\.)tiktok\.com$').hasMatch(host)) {
    full = _jsonString(html, 'desc');
  }
  full ??= _meta(html, 'og:description') ?? _meta(html, 'description');
  final text = [title, full].whereType<String>().join('. ').trim();
  // Con menos que esto no hay receta: mejor que el servidor lo intente él.
  return text.length >= 40 ? text : null;
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
