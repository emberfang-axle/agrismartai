// OBJECTIVE 4: Scan model for history storage and web dashboard sync

class ScanRecord {
  final String id;
  final String imagePath;
  final String disease;
  final double confidence;
  final DateTime scannedAt;
  final List<String> fertilizerSteps;

  ScanRecord({
    required this.id,
    required this.imagePath,
    required this.disease,
    required this.confidence,
    required this.scannedAt,
    required this.fertilizerSteps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'disease': disease,
        'confidence': confidence,
        'scannedAt': scannedAt.toIso8601String(),
        'fertilizerSteps': fertilizerSteps,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        disease: json['disease'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        fertilizerSteps: (json['fertilizerSteps'] as List).cast<String>(),
      );
}

class ChatMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final DateTime at;

  ChatMessage({required this.role, required this.text, DateTime? at})
      : at = at ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'at': at.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        text: json['text'] as String,
        at: DateTime.parse(json['at'] as String),
      );
}

class FeedbackRecord {
  final int rating;
  final String comment;
  final DateTime submittedAt;

  FeedbackRecord({
    required this.rating,
    required this.comment,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
        'submittedAt': submittedAt.toIso8601String(),
      };
}
