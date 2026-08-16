import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/settings_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _repetitionsKey = 'required_repetitions';
  static const _voiceKey = 'tts_voice';

  int _requiredRepetitions = 20;
  String _voice = 'alloy';

  final SettingsService settingsService;

  AppSettingsProvider(this.settingsService);

  int get requiredRepetitions => _requiredRepetitions;
  String get voice => _voice;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _requiredRepetitions = preferences.getInt(_repetitionsKey) ?? 20;
    _voice = preferences.getString(_voiceKey) ?? 'alloy';
    notifyListeners();
  }

  Future<void> loadFromServer() async {
    try {
      final settings = await settingsService.getPracticeSettings();
      _requiredRepetitions = settings.requiredRepetitions;
      _voice = settings.voice;
      await _saveLocally();
      notifyListeners();
    } catch (_) {
      // The local copy remains usable while the account settings are unavailable.
    }
  }

  Future<void> setRequiredRepetitions(int value) async {
    _requiredRepetitions = value.clamp(1, 100);
    await _saveLocally();
    notifyListeners();
    await _saveToServer();
  }

  Future<void> setVoice(String value) async {
    _voice = value;
    await _saveLocally();
    notifyListeners();
    await _saveToServer();
  }

  Future<void> _saveLocally() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_repetitionsKey, _requiredRepetitions);
    await preferences.setString(_voiceKey, _voice);
  }

  Future<void> _saveToServer() async {
    try {
      await settingsService.updatePracticeSettings(
        requiredRepetitions: _requiredRepetitions,
        voice: _voice,
      );
    } catch (_) {
      // Retain the local setting and sync again after the next successful login.
    }
  }
}
