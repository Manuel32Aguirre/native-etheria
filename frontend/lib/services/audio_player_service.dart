import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Plays TTS audio coming from the backend and gives short feedback sounds
/// for correct/incorrect answers (using system sounds so no bundled audio
/// assets are required).
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Completer<void>? _playbackCompletion;
  StreamSubscription<void>? _completionSubscription;
  int _playbackVersion = 0;

  Future<void> playBytes(Uint8List bytes) async {
    await _player.play(BytesSource(bytes));
  }

  Future<void> playBytesAndWait(Uint8List bytes) async {
    await stop();
    final playbackVersion = ++_playbackVersion;
    final completion = Completer<void>();
    _playbackCompletion = completion;
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      if (!completion.isCompleted) {
        completion.complete();
      }
    });

    try {
      await _player.play(BytesSource(bytes));
      if (playbackVersion != _playbackVersion) {
        await _player.stop();
        return;
      }
      await completion.future;
    } finally {
      if (playbackVersion == _playbackVersion) {
        _playbackCompletion = null;
        await _completionSubscription?.cancel();
        _completionSubscription = null;
      }
    }
  }

  Future<void> stop() async {
    _playbackVersion++;
    final completion = _playbackCompletion;
    _playbackCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    await _player.stop();
  }

  Future<void> playSuccess() async {
    HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playError() async {
    HapticFeedback.vibrate();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> dispose() async {
    await stop();
    _player.dispose();
  }
}
