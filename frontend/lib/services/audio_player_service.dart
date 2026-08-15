import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Plays TTS audio coming from the backend and gives short feedback sounds
/// for correct/incorrect answers (using system sounds so no bundled audio
/// assets are required).
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playBytes(Uint8List bytes) async {
    await _player.play(BytesSource(bytes));
  }

  Future<void> playBytesAndWait(Uint8List bytes) async {
    final completion = Completer<void>();
    late final StreamSubscription<void> subscription;
    subscription = _player.onPlayerComplete.listen((_) {
      if (!completion.isCompleted) {
        completion.complete();
      }
      subscription.cancel();
    });

    try {
      await _player.play(BytesSource(bytes));
      await completion.future;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> playSuccess() async {
    HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playError() async {
    HapticFeedback.vibrate();
    await SystemSound.play(SystemSoundType.alert);
  }

  void dispose() {
    _player.dispose();
  }
}
