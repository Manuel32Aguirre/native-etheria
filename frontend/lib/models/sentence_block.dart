import 'sentence.dart';

class SentenceBlock {
  final List<Sentence> currentBlock;
  final int pendingNowCount;

  SentenceBlock({required this.currentBlock, required this.pendingNowCount});

  factory SentenceBlock.fromJson(Map<String, dynamic> json) {
    return SentenceBlock(
      currentBlock: (json['currentBlock'] as List<dynamic>)
          .map((e) => Sentence.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingNowCount: json['pendingNowCount'] as int? ?? 0,
    );
  }
}
