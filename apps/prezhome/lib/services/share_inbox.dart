import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('prezhome/share');

/// Texto compartido a PrezHome desde otra app (Android, menú Compartir; ver
/// MainActivity.kt). [onShared] recibe lo que se compartió: al abrir la app
/// con él y cada vez que llegue con la app ya abierta.
/// shortcut: solo Android; en iOS hace falta una Share Extension (Xcode).
Future<void> listenSharedText(void Function(String text) onShared) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
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

/// Primer enlace http(s) del texto compartido (TikTok manda "Mira este
/// vídeo… https://vm.tiktok.com/…"), o null.
String? firstUrl(String text) =>
    RegExp(r'https?://\S+').firstMatch(text)?.group(0);
