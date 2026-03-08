import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service for on-device Speech-to-Text conversion.
/// This allows transcription to work in airplane mode without API keys.
class LocalSpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('LocalSpeech Error: $error'),
        onStatus: (status) => debugPrint('LocalSpeech Status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('LocalSpeech Initialization Error: $e');
      return false;
    }
  }

  /// Listen to live speech and return the transcribed text.
  Future<String?> transcribeLive({
    Duration duration = const Duration(seconds: 30),
    VoidCallback? onListeningStarted,
    VoidCallback? onListeningStopped,
    Function(String)? onPartialResult,
  }) async {
    final hasInit = await initialize();
    if (!hasInit) return null;

    final completer = Completer<String?>();
    String finalResultText = '';

    onListeningStarted?.call();

    await _speechToText.listen(
      onResult: (result) {
        finalResultText = result.recognizedWords;
        onPartialResult?.call(finalResultText);
        if (result.finalResult) {
          if (!completer.isCompleted) completer.complete(finalResultText);
        }
      },
      localeId: 'tr_TR',
      listenFor: duration,
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );

    // Safety timeout
    Timer(duration + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        _speechToText.stop();
        completer.complete(finalResultText.isEmpty ? null : finalResultText);
      }
    });

    final result = await completer.future;
    onListeningStopped?.call();
    return result;
  }

  void stop() {
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
