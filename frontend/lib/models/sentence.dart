class Sentence {
  final int id;
  final String originalText;
  final int intervalIndex;
  final DateTime? nextReviewAt;
  final bool isMastered;
  final String status;

  Sentence({
    required this.id,
    required this.originalText,
    required this.intervalIndex,
    required this.nextReviewAt,
    required this.isMastered,
    required this.status,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] as int,
      originalText: json['originalText'] as String,
      intervalIndex: json['intervalIndex'] as int? ?? 0,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.tryParse(json['nextReviewAt'] as String)
          : null,
      isMastered: json['isMastered'] as bool? ?? false,
      status: json['status'] as String? ?? 'SCHEDULED',
    );
  }
}
