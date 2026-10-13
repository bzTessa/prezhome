import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/cook_voice.dart';

/// Manos libres del modo cocina: lee en voz alta y escucha órdenes
/// ("siguiente", "repite", "temporizador"...). Mientras habla no escucha, para
/// no oírse a sí misma; al terminar vuelve a escuchar sola.
class HandsFree {
  HandsFree({required this.onCommand});

  final void Function(CookCommand command) onCommand;

  final _tts = FlutterTts();
  final _stt = SpeechToText();
  bool _active = false;
  bool _speaking = false;
  String? _locale;

  bool get active => _active;

  /// Pide permiso de micrófono y prepara la voz. false si no se puede.
  Future<bool> start() async {
    try {
      final ok = await _stt.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') _relisten();
        },
        onError: (_) => _relisten(),
      );
      if (!ok) return false;
      final ids = (await _stt.locales()).map((l) => l.localeId).toList();
      _locale = ids.firstWhere(
        (id) => id.toLowerCase().replaceAll('-', '_') == 'es_es',
        orElse: () =>
            ids.firstWhere((id) => id.startsWith('es'), orElse: () => 'es_ES'),
      );
      await _tts.setLanguage('es-ES');
      await _tts.awaitSpeakCompletion(true);
      // iOS: hablar y escuchar comparten la sesión de audio.
      await _tts.setSharedInstance(true);
      await _tts
          .setIosAudioCategory(IosTextToSpeechAudioCategory.playAndRecord, [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ], IosTextToSpeechAudioMode.voicePrompt);
    } catch (_) {
      return false;
    }
    _active = true;
    _listen();
    return true;
  }

  Future<void> stop() async {
    _active = false;
    try {
      await _stt.cancel();
      await _tts.stop();
    } catch (_) {}
  }

  /// Lee [text] y después vuelve a escuchar.
  Future<void> say(String text) async {
    if (!_active) return;
    _speaking = true;
    try {
      await _stt.cancel();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
    _speaking = false;
    _listen();
  }

  void _relisten() {
    // Pequeña pausa: el reconocedor tarda en soltar el micrófono.
    Future<void>.delayed(const Duration(milliseconds: 400), _listen);
  }

  void _listen() {
    if (!_active || _speaking || _stt.isListening) return;
    _stt
        .listen(
          onResult: (r) {
            final command = parseCookCommand(r.recognizedWords);
            if (command == null) return;
            _stt.cancel();
            onCommand(command);
          },
          listenOptions: SpeechListenOptions(
            localeId: _locale,
            listenFor: const Duration(minutes: 1),
            pauseFor: const Duration(seconds: 6),
            partialResults: true,
            cancelOnError: false,
            listenMode: ListenMode.dictation,
          ),
        )
        .catchError((_) => _relisten());
  }
}
