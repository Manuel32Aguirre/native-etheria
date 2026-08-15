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
    _block = block;
    _sentenceIndex = 0;
    _sessionComplete = false;
    await _loadCurrentSentence();
  }

  Future<void> _loadCurrentSentence() async {
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
      _questionAudio = await practiceService.textToSpeech(
        _question,
        voice: settingsProvider.voice,
      );
      await _speakAndStartListening();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replayQuestionAudio() async {
    await _speakAndStartListening();
  }

  Future<void> _speakAndStartListening() async {
    final audio = _questionAudio;
    if (audio == null || _isRecording) return;

    _phase = PracticePhase.speaking;
    _feedback = FeedbackState.none;
    _lastTranscript = null;
    notifyListeners();

    try {
      await playerService.playBytesAndWait(audio);
      if (_sessionComplete || currentSentence == null) return;
      await startRecording();
    } catch (e) {
      _phase = PracticePhase.loading;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    _feedback = FeedbackState.none;
    _errorMessage = null;
    try {
      await recorderService.start();
      _isRecording = true;
      _phase = PracticePhase.listening;
      _voiceDetected = false;
      _silenceTimer?.cancel();
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = recorderService.amplitudeStream().listen(
        _onAmplitude,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _onAmplitude(Amplitude sample) {
    _amplitude = sample.current;
    final speaking = sample.current > -42;
    if (speaking) {
      _voiceDetected = true;
      _silenceTimer?.cancel();
      _silenceTimer = null;
    } else if (_voiceDetected && _silenceTimer == null) {
      _silenceTimer = Timer(const Duration(milliseconds: 900), () {
        _silenceTimer = null;
        if (_isRecording) stopRecordingAndValidate();
      });
    }
    notifyListeners();
  }

  Future<void> stopRecordingAndValidate() async {
    if (!_isRecording) return;
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
      if (bytes == null) {
        _errorMessage = 'No audio was recorded';
        return;
      }

      final result = await practiceService.validateAudio(
        currentSentence!.id,
        bytes,
        'answer.m4a',
      );
      _lastTranscript = result.transcript;

      if (result.isExactMatch) {
        _feedback = FeedbackState.success;
        _correctRepetitions++;
        await playerService.playSuccess();

        if (_correctRepetitions >= requiredRepetitions) {
          final sentence = currentSentence!;
          final review = await sentenceService.completeReview(sentence.id);
          final nextReviewAt = review['nextReviewAt'] as String?;
          if (nextReviewAt != null) {
            await notificationService.scheduleReview(
              id: sentence.id,
              at: DateTime.parse(nextReviewAt),
              sentence: sentence.originalText,
            );
          }
          _sentenceIndex++;
          await _loadCurrentSentence();
        } else {
          await _speakAndStartListening();
        }
      } else {
        _feedback = FeedbackState.error;
        await playerService.playError();
        await _speakAndStartListening();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _phase = PracticePhase.loading;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _silenceTimer?.cancel();
    super.dispose();
  }
}
