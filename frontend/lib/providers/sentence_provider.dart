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

  Future<bool> extractFromImageBytes(List<int> bytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await sentenceService.extractFromImageBase64(base64Encode(bytes));
      await refreshBlock();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
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
}
