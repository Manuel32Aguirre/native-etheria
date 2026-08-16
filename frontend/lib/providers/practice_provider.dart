import 'package:flutter/foundation.dart';

import 'dart:async';

import '../models/sentence.dart';
import 'app_settings_provider.dart';
import '../services/audio_player_service.dart';
import '../services/live_transcription_service.dart';
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
  final AudioPlayerService playerService;
  final AppSettingsProvider settingsProvider;
  final NotificationService notificationService;
  final LiveTranscriptionService liveTranscriptionService;

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
  int _sessionVersion = 0;
  bool _isDisposed = false;
  String _liveCaption = '';

  PracticeProvider({
    required this.practiceService,
    required this.sentenceService,
    required this.playerService,
    required this.settingsProvider,
    required this.notificationService,
    required this.liveTranscriptionService,
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

  /// On-device live caption shown while recording (never sent to OpenAI).
  String get liveCaption => _liveCaption;

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
      _questionAudio = await practiceService.textToSpeech(
        _question,
        voice: settingsProvider.voice,
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
      await startListening(sessionVersion);
    } catch (e) {
      if (_isCurrentSession(sessionVersion)) {
        _phase = PracticePhase.loading;
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> startListening([int? requestedSessionVersion]) async {
    final sessionVersion = requestedSessionVersion ?? _sessionVersion;
    if (!_isCurrentSession(sessionVersion)) return;
    _feedback = FeedbackState.none;
    _errorMessage = null;
    try {
      _isRecording = true;
      _phase = PracticePhase.listening;
      _liveCaption = '';
      await liveTranscriptionService.start(
        onResult: (text) {
          if (!_isCurrentSession(sessionVersion) || !_isRecording) return;
          _liveCaption = text;
          notifyListeners();
        },
        onFinalResult: (text) {
          if (!_isCurrentSession(sessionVersion) || !_isRecording) return;
          _liveCaption = text;
          unawaited(stopRecordingAndValidate(sessionVersion));
        },
      );
      notifyListeners();
    } catch (e) {
      if (_isCurrentSession(sessionVersion)) {
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> stopRecordingAndValidate([int? requestedSessionVersion]) async {
    final sessionVersion = requestedSessionVersion ?? _sessionVersion;
    if (!_isCurrentSession(sessionVersion) || !_isRecording) return;
    _isRecording = false;
    await liveTranscriptionService.stop();
    final transcript = _liveCaption.trim();
    _phase = PracticePhase.validating;
    _isLoading = true;
    notifyListeners();

    try {
      if (transcript.isEmpty) {
        _errorMessage = 'No speech was recognized';
        return;
      }

      final result = await practiceService.validateTranscript(
        currentSentence!.id,
        transcript,
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
    _liveCaption = '';
    await Future.wait([
      playerService.stop(),
      liveTranscriptionService.cancel(),
    ]);
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionVersion++;
    playerService.stop();
    liveTranscriptionService.dispose();
    super.dispose();
  }
}
