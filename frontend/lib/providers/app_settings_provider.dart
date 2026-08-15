import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _repetitionsKey = 'required_repetitions';
  static const _voiceKey = 'tts_voice';

  int _requiredRepetitions = 20;
  String _voice = 'alloy';

  int get requiredRepetitions => _requiredRepetitions;
  String get voice => _voice;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _requiredRepetitions = preferences.getInt(_repetitionsKey) ?? 20;
    _voice = preferences.getString(_voiceKey) ?? 'alloy';
    notifyListeners();
  }

  Future<void> setRequiredRepetitions(int value) async {
    _requiredRepetitions = value.clamp(1, 100);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_repetitionsKey, _requiredRepetitions);
    notifyListeners();
  }

  Future<void> setVoice(String value) async {
    _voice = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_voiceKey, value);
    notifyListeners();
  }
}
