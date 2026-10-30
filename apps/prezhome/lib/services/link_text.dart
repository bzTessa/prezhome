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
/// Best-effort: null si no hay red, CORS (web) o la página no trae nada útil.
Future<String?> fetchLinkText(String url, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final get = c.get(Uri.parse(url), headers: _headers);
    final res = await get.timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    // El host final (tras redirecciones de enlaces cortos) decide qué leer.
    final host = res.request?.url.host ?? Uri.parse(url).host;
    return extractPostText(
      utf8.decode(res.bodyBytes, allowMalformed: true),
      host,
    );
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

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
