import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/sentence.dart';
import '../models/sentence_block.dart';
import '../services/sentence_service.dart';

class SentenceProvider extends ChangeNotifier {
  final SentenceService sentenceService;

  List<Sentence> _currentBlock = [];
  List<Sentence> _history = [];
  int _pendingNowCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  SentenceProvider(this.sentenceService);

  List<Sentence> get currentBlock => _currentBlock;
  List<Sentence> get history => _history;
  int get pendingNowCount => _pendingNowCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> refreshBlock() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final SentenceBlock block = await sentenceService.getCurrentBlock();
      _currentBlock = block.currentBlock;
      _pendingNowCount = block.pendingNowCount;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> extractFromImageBytesBatch(List<List<int>> images) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var createdCount = 0;
      for (final bytes in images.take(5)) {
        createdCount += await sentenceService.extractFromImageBase64(
          base64Encode(bytes),
        );
      }
      await refreshBlock();
      await refreshHistory();
      return createdCount;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshHistory() async {
    try {
      _history = await sentenceService.getHistory();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteSentence(int sentenceId) async {
    _errorMessage = null;
    try {
      await sentenceService.deleteSentence(sentenceId);
      _history.removeWhere((sentence) => sentence.id == sentenceId);
      _currentBlock.removeWhere((sentence) => sentence.id == sentenceId);
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }
}
