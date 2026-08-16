import 'api_client.dart';

class PracticeSettings {
  final int requiredRepetitions;
  final String voice;

  const PracticeSettings({
    required this.requiredRepetitions,
    required this.voice,
  });

  factory PracticeSettings.fromJson(Map<String, dynamic> json) {
    return PracticeSettings(
      requiredRepetitions: json['requiredRepetitions'] as int? ?? 20,
      voice: json['voice'] as String? ?? 'alloy',
    );
  }
}

class SettingsService {
  final ApiClient client;

  SettingsService(this.client);

  Future<PracticeSettings> getPracticeSettings() async {
    final result = await client.get('/settings/practice');
    return PracticeSettings.fromJson(result as Map<String, dynamic>);
  }

  Future<PracticeSettings> updatePracticeSettings({
    required int requiredRepetitions,
    required String voice,
  }) async {
    final result = await client.post(
      '/settings/practice',
      body: {'requiredRepetitions': requiredRepetitions, 'voice': voice},
    );
    return PracticeSettings.fromJson(result as Map<String, dynamic>);
  }
}
