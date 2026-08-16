import 'package:speech_to_text/speech_to_text.dart';

/// Owns native speech recognition for both the live caption and final answer.
class LiveTranscriptionService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  Future<bool> _ensureInitialized() async {
    if (_available) return true;
    _available = await _speech.initialize(onError: (_) {}, onStatus: (_) {});
    return _available;
  }

  Future<void> start({
    required void Function(String text) onResult,
    required void Function(String text) onFinalResult,
  }) async {
    if (!await _ensureInitialized()) {
      throw Exception('Speech recognition is not available on this device');
    }
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) onFinalResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'en_US',
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}
