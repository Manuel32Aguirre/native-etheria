import 'dart:convert';

import '../models/sentence.dart';
import '../models/sentence_block.dart';
import 'api_client.dart';

class SentenceService {
  final ApiClient client;

  SentenceService(this.client);

  Future<SentenceBlock> getCurrentBlock() async {
    final result = await client.get('/sentences/block');
    return SentenceBlock.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Sentence>> getHistory() async {
    final result = await client.get('/sentences/history') as List<dynamic>;
    return result
        .map((item) => Sentence.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> extractFromImageBase64(String base64Image) async {
    await client.post(
      '/sentences/extract-image',
      body: {'imageBase64': base64Image},
    );
  }

  Future<Map<String, dynamic>> completeReview(int sentenceId) async {
    final result = await client.post('/sentences/$sentenceId/complete');
    return result as Map<String, dynamic>;
  }
}

/// Helper kept alongside the service for callers that already have raw bytes.
String encodeImageBytes(List<int> bytes) => base64Encode(bytes);
