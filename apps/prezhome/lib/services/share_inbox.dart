import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('prezhome/share');

/// Texto compartido a PrezHome desde otra app (menú Compartir). Android:
/// MainActivity.kt; iOS: la extensión ios/ShareExtension abre la app con
/// com.prezhome.app://share?text=... [onShared] recibe lo que se compartió:
/// al abrir la app con él y cada vez que llegue con la app ya abierta.
Future<void> listenSharedText(void Function(String text) onShared) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // El stream trae también el enlace con el que se abrió la app.
    AppLinks().uriLinkStream.listen((uri) {
      final text = sharedTextFromLink(uri);
      if (text != null) onShared(text);
    });
    return;
  }
  if (defaultTargetPlatform != TargetPlatform.android) return;
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'shared' && call.arguments is String) {
      onShared(call.arguments as String);
    }
  });
  try {
    final first = await _channel.invokeMethod<String>('initial');
    if (first != null && first.trim().isNotEmpty) onShared(first);
  } on PlatformException catch (_) {}
}

/// Texto de un enlace com.prezhome.app://share?text=..., o null si es otro
/// enlace (p. ej. la vuelta del login).
String? sharedTextFromLink(Uri uri) {
  if (uri.scheme != 'com.prezhome.app' || uri.host != 'share') return null;
  final text = uri.queryParameters['text']?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// Primer enlace http(s) del texto compartido (TikTok manda "Mira este
/// vídeo… https://vm.tiktok.com/…"), o null.
String? firstUrl(String text) =>
    RegExp(r'https?://\S+').firstMatch(text)?.group(0);
