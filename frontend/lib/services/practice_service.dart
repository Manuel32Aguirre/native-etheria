import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

class PracticeService {
  final ApiClient client;

  PracticeService(this.client);

  Future<String> getQuestion(int sentenceId) async {
    final result = await client.get('/practice/$sentenceId/question');
    return result['question'] as String;
  }

  /// Returns (isExactMatch, transcript).
  Future<AudioValidationResult> validateAudio(
    int sentenceId,
    List<int> audioBytes,
    String filename,
  ) async {
    final streamed = await client.postMultipart(
      '/practice/$sentenceId/validate-audio',
      fileBytes: audioBytes,
      fileFieldName: 'audio',
      filename: filename,
    );
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw ApiException(streamed.statusCode, body);
    }
    return AudioValidationResult.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  Future<Uint8List> textToSpeech(String text, {String? voice}) async {
    final body = <String, dynamic>{'text': text};
    if (voice != null) body['voice'] = voice;
    final bytes = await client.postForBytes('/practice/tts', body: body);
    return Uint8List.fromList(bytes);
  }
}

class AudioValidationResult {
  final bool isExactMatch;
  final String transcript;
  final String expectedText;

  AudioValidationResult({
    required this.isExactMatch,
    required this.transcript,
    required this.expectedText,
  });

  factory AudioValidationResult.fromJson(Map<String, dynamic> json) {
    return AudioValidationResult(
      isExactMatch: json['isExactMatch'] as bool? ?? false,
      transcript: json['transcript'] as String? ?? '',
      expectedText: json['expectedText'] as String? ?? '',
    );
  }
}
