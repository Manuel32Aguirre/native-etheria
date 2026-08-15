import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Wraps the `record` package to capture the learner's spoken answer.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Stream<Amplitude> amplitudeStream({
    Duration interval = const Duration(milliseconds: 100),
  }) {
    return _recorder.onAmplitudeChanged(interval);
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start() async {
    if (!await hasPermission()) {
      throw Exception('Microphone permission denied');
    }
    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/answer_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _currentPath!,
    );
  }

  /// Stops recording and returns the recorded file bytes, or null if nothing was recorded.
  Future<List<int>?> stop() async {
    final path = await _recorder.stop();
    final finalPath = path ?? _currentPath;
    if (finalPath == null) return null;
    final file = File(finalPath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> cancel() async {
    await _recorder.cancel();
  }

  Future<bool> isRecording() => _recorder.isRecording();

  void dispose() {
    _recorder.dispose();
  }
}
