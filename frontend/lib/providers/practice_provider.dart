import 'package:flutter/foundation.dart';

import 'dart:async';

import 'package:record/record.dart';

import '../models/sentence.dart';
import 'app_settings_provider.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/practice_service.dart';
import '../services/sentence_service.dart';
import '../services/notification_service.dart';

enum FeedbackState { none, success, error }

enum PracticePhase { loading, speaking, listening, validating }

/// Drives the strict repetition loop for a single practice session
/// (a block of up to 5 sentences). The learner must answer a sentence
/// correctly [requiredRepetitions] times before moving to the next one.
class PracticeProvider extends ChangeNotifier {
  final PracticeService practiceService;
  final SentenceService sentenceService;
  final AudioRecorderService recorderService;
  final AudioPlayerService playerService;
  final AppSettingsProvider settingsProvider;
  final NotificationService notificationService;

  List<Sentence> _block = [];
  int _sentenceIndex = 0;
  int _correctRepetitions = 0;
  String _question = '';
  Uint8List? _questionAudio;
  bool _isLoading = false;
  bool _isRecording = false;
  FeedbackState _feedback = FeedbackState.none;
  String? _lastTranscript;
  String? _errorMessage;
  bool _sessionComplete = false;
  PracticePhase _phase = PracticePhase.loading;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _silenceTimer;
  bool _voiceDetected = false;
  double _amplitude = -60;
  int _sessionVersion = 0;
  bool _isDisposed = false;

  PracticeProvider({
    required this.practiceService,
    required this.sentenceService,
    required this.recorderService,
    required this.playerService,
    required this.settingsProvider,
    required this.notificationService,
  });

  Sentence? get currentSentence =>
      _sentenceIndex < _block.length ? _block[_sentenceIndex] : null;
  int get correctRepetitions => _correctRepetitions;
  String get question => _question;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  FeedbackState get feedback => _feedback;
  String? get lastTranscript => _lastTranscript;
  String? get errorMessage => _errorMessage;
  bool get sessionComplete => _sessionComplete;
  bool get isBlockFinished => _sentenceIndex >= _block.length;
  PracticePhase get phase => _phase;
  bool get isAnswerVisible => _phase == PracticePhase.speaking;
  int get requiredRepetitions => settingsProvider.requiredRepetitions;
  double get amplitude => _amplitude;

  Future<void> stopRecordingManually() => stopRecordingAndValidate();

  Future<void> startSession(List<Sentence> block) async {
    await stopSession();
    final sessionVersion = ++_sessionVersion;
    _block = block;
    _sentenceIndex = 0;
    _sessionComplete = false;
    await _loadCurrentSentence(sessionVersion);
  }

  bool _isCurrentSession(int sessionVersion) =>
      !_isDisposed && sessionVersion == _sessionVersion;

  Future<void> _loadCurrentSentence([int? requestedSessionVersion]) async {
    final sessionVersion = requestedSessionVersion ?? _sessionVersion;
    if (!_isCurrentSession(sessionVersion)) return;
    if (isBlockFinished) {
      _sessionComplete = true;
      notifyListeners();
      return;
    }
    _correctRepetitions = 0;
    _feedback = FeedbackState.none;
    _lastTranscript = null;
    _errorMessage = null;
    _questionAudio = null;
    _phase = PracticePhase.loading;
    _isLoading = true;
    notifyListeners();
    try {
      _question = await practiceService.getQuestion(currentSentence!.id);
      if (!_isCurrentSession(sessionVersion)) return;
      _questionAudio = await practiceService.getQuestionAudio(
        currentSentence!.id,
        settingsProvider.voice,
      );
      if (!_isCurrentSession(sessionVersion)) return;
      await _speakAndStartListening(sessionVersion);
    } catch (e) {
      if (_isCurrentSession(sessionVersion)) _errorMessage = e.toString();
    } finally {
      if (_isCurrentSession(sessionVersion)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> replayQuestionAudio() async {
    await _speakAndStartListening(_sessionVersion);
  }

  Future<void> _speakAndStartListening(int sessionVersion) async {
    final audio = _questionAudio;
    if (!_isCurrentSession(sessionVersion) || audio == null || _isRecording) {
      return;
    }

    _phase = PracticePhase.speaking;
    _feedback = FeedbackState.none;
    _lastTranscript = null;
    notifyListeners();

    try {
      await playerService.playBytesAndWait(audio);
      if (!_isCurrentSession(sessionVersion) ||
          _sessionComplete ||
          currentSentence == null) {
        return;
      }
      await startRecording(sessionVersion);
    } catch (e) {
      if (_isCurrentSession(sessionVersion)) {
        _phase = PracticePhase.loading;
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> startRecording([int? requestedSessionVersion]) async {
    final sessionVersion = requestedSessionVersion ?? _sessionVersion;
    if (!_isCurrentSession(sessionVersion)) return;
    _feedback = FeedbackState.none;
    _errorMessage = null;
    try {
      await recorderService.start();
      if (!_isCurrentSession(sessionVersion)) {
        await recorderService.cancel();
        return;
      }
      _isRecording = true;
      _phase = PracticePhase.listening;
      _voiceDetected = false;
      _silenceTimer?.cancel();
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = recorderService.amplitudeStream().listen(
        (sample) => _onAmplitude(sample, sessionVersion),
      );
      notifyListeners();
    } catch (e) {
      if (_isCurrentSession(sessionVersion)) {
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  void _onAmplitude(Amplitude sample, int sessionVersion) {
    if (!_isCurrentSession(sessionVersion)) return;
    _amplitude = sample.current;
    final isSpeaking = sample.current > -42;
    if (isSpeaking) {
      _voiceDetected = true;
      _silenceTimer?.cancel();
      _silenceTimer = null;
    } else if (_voiceDetected && _silenceTimer == null) {
      _silenceTimer = Timer(const Duration(milliseconds: 900), () {
        _silenceTimer = null;
        if (_isRecording) unawaited(stopRecordingAndValidate(sessionVersion));
      });
    }
    notifyListeners();
  }

  Future<void> stopRecordingAndValidate([int? requestedSessionVersion]) async {
    final sessionVersion = requestedSessionVersion ?? _sessionVersion;
    if (!_isCurrentSession(sessionVersion) || !_isRecording) return;
    _isRecording = false;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _phase = PracticePhase.validating;
    _isLoading = true;
    notifyListeners();

    try {
      final bytes = await recorderService.stop();
      if (!_isCurrentSession(sessionVersion)) return;
      if (bytes == null) {
        _errorMessage = 'No audio was recorded';
        return;
      }

      final result = await practiceService.validateAudio(
        currentSentence!.id,
        bytes,
        'answer.m4a',
      );
      if (!_isCurrentSession(sessionVersion)) return;
      _lastTranscript = result.transcript;

      if (result.isExactMatch) {
        _feedback = FeedbackState.success;
        _correctRepetitions++;
        await playerService.playSuccess();
        if (!_isCurrentSession(sessionVersion)) return;

        if (_correctRepetitions >= requiredRepetitions) {
          final sentence = currentSentence!;
          final review = await sentenceService.completeReview(sentence.id);
          if (!_isCurrentSession(sessionVersion)) return;
          final nextReviewAt = review['nextReviewAt'] as String?;
          if (nextReviewAt != null) {
            await notificationService.scheduleReview(
              id: sentence.id,
              at: DateTime.parse(nextReviewAt),
              sentence: sentence.originalText,
            );
            if (!_isCurrentSession(sessionVersion)) return;
          }
          _sentenceIndex++;
          await _loadCurrentSentence(sessionVersion);
        } else {
          await _speakAndStartListening(sessionVersion);
        }
      } else {
        _feedback = FeedbackState.error;
        await playerService.playError();
        if (!_isCurrentSession(sessionVersion)) return;
        await _speakAndStartListening(sessionVersion);
      }
    } catch (e) {
      if (_isCurrentSession(sessionVersion)) {
        _errorMessage = e.toString();
        _phase = PracticePhase.loading;
      }
    } finally {
      if (_isCurrentSession(sessionVersion)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopSession() async {
    _sessionVersion++;
    _isRecording = false;
    _isLoading = false;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    await Future.wait([playerService.stop(), recorderService.cancel()]);
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionVersion++;
    _amplitudeSubscription?.cancel();
    _silenceTimer?.cancel();
    playerService.stop();
    recorderService.cancel();
    super.dispose();
  }
}
