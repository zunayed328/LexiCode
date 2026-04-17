/// Model class for pronunciation analysis results.
class PronunciationResult {
  final int accuracy;
  final String spokenText;
  final String targetPhrase;
  final String feedback;
  final List<String> problemAreas;
  final int overallScore;
  final bool isFallback;

  PronunciationResult({
    required this.accuracy,
    this.spokenText = '',
    required this.targetPhrase,
    required this.feedback,
    this.problemAreas = const [],
    required this.overallScore,
    this.isFallback = false,
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      accuracy: json['accuracy'] ?? 0,
      spokenText: json['spokenText'] ?? '',
      targetPhrase: json['targetPhrase'] ?? '',
      feedback: json['feedback'] ?? '',
      problemAreas: List<String>.from(json['problemAreas'] ?? []),
      overallScore: json['overallScore'] ?? 0,
      isFallback: json['fallback'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'accuracy': accuracy,
    'spokenText': spokenText,
    'targetPhrase': targetPhrase,
    'feedback': feedback,
    'problemAreas': problemAreas,
    'overallScore': overallScore,
  };
}
