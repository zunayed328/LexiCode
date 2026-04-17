import 'package:flutter/material.dart';

// ─── IELTS Section Type ───────────────────────────────────────────

enum IELTSSectionType { listening, reading, writing, speaking }

extension IELTSSectionTypeX on IELTSSectionType {
  String get label {
    switch (this) {
      case IELTSSectionType.listening:
        return 'Listening';
      case IELTSSectionType.reading:
        return 'Reading';
      case IELTSSectionType.writing:
        return 'Writing';
      case IELTSSectionType.speaking:
        return 'Speaking';
    }
  }

  IconData get icon {
    switch (this) {
      case IELTSSectionType.listening:
        return Icons.headphones_rounded;
      case IELTSSectionType.reading:
        return Icons.auto_stories_rounded;
      case IELTSSectionType.writing:
        return Icons.edit_note_rounded;
      case IELTSSectionType.speaking:
        return Icons.mic_rounded;
    }
  }

  int get durationMinutes {
    switch (this) {
      case IELTSSectionType.listening:
        return 30;
      case IELTSSectionType.reading:
        return 60;
      case IELTSSectionType.writing:
        return 60;
      case IELTSSectionType.speaking:
        return 14;
    }
  }
}

// ─── Band Score Helper ────────────────────────────────────────────

class BandScoreDescriptor {
  static Color colorForBand(double band) {
    if (band >= 8.0) return const Color(0xFF10B981);
    if (band >= 7.0) return const Color(0xFF34D399);
    if (band >= 6.0) return const Color(0xFFFBBF24);
    if (band >= 5.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static String labelForBand(double band) {
    if (band >= 8.5) return 'Expert';
    if (band >= 7.5) return 'Very Good';
    if (band >= 6.5) return 'Competent';
    if (band >= 5.5) return 'Modest';
    if (band >= 4.5) return 'Limited';
    return 'Basic';
  }

  static String cefrForBand(double band) {
    if (band >= 8.0) return 'C2';
    if (band >= 7.0) return 'C1';
    if (band >= 5.5) return 'B2';
    if (band >= 4.5) return 'B1';
    if (band >= 3.5) return 'A2';
    return 'A1';
  }
}

// ─── Writing Evaluation ───────────────────────────────────────────

class WritingEvaluation {
  final double taskAchievement;
  final double coherenceCohesion;
  final double lexicalResource;
  final double grammaticalRange;
  final double overallBand;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<GrammarError> grammarErrors;
  final String? correctedVersion;
  final List<String> suggestions;
  final String? detailedFeedback;

  const WritingEvaluation({
    required this.taskAchievement,
    required this.coherenceCohesion,
    required this.lexicalResource,
    required this.grammaticalRange,
    required this.overallBand,
    this.strengths = const [],
    this.weaknesses = const [],
    this.grammarErrors = const [],
    this.correctedVersion,
    this.suggestions = const [],
    this.detailedFeedback,
  });

  factory WritingEvaluation.fromJson(Map<String, dynamic> json) =>
      WritingEvaluation(
        taskAchievement:
            (json['taskAchievement'] as num?)?.toDouble() ?? 0,
        coherenceCohesion:
            (json['coherenceCohesion'] as num?)?.toDouble() ?? 0,
        lexicalResource:
            (json['lexicalResource'] as num?)?.toDouble() ?? 0,
        grammaticalRange:
            (json['grammaticalRange'] as num?)?.toDouble() ?? 0,
        overallBand: (json['overallBand'] as num?)?.toDouble() ?? 0,
        strengths: List<String>.from(json['strengths'] ?? []),
        weaknesses: List<String>.from(json['weaknesses'] ?? []),
        grammarErrors: (json['grammarErrors'] as List<dynamic>?)
                ?.map((e) =>
                    GrammarError.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        correctedVersion: json['correctedVersion'],
        suggestions: List<String>.from(json['suggestions'] ?? []),
        detailedFeedback: json['detailedFeedback'],
      );

  Map<String, dynamic> toJson() => {
        'taskAchievement': taskAchievement,
        'coherenceCohesion': coherenceCohesion,
        'lexicalResource': lexicalResource,
        'grammaticalRange': grammaticalRange,
        'overallBand': overallBand,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'grammarErrors': grammarErrors.map((e) => e.toJson()).toList(),
        'correctedVersion': correctedVersion,
        'suggestions': suggestions,
        'detailedFeedback': detailedFeedback,
      };
}

class GrammarError {
  final String original;
  final String correction;
  final String explanation;
  final int? position;

  const GrammarError({
    required this.original,
    required this.correction,
    required this.explanation,
    this.position,
  });

  factory GrammarError.fromJson(Map<String, dynamic> json) =>
      GrammarError(
        original: json['original'] ?? '',
        correction: json['correction'] ?? '',
        explanation: json['explanation'] ?? '',
        position: json['position'],
      );

  Map<String, dynamic> toJson() => {
        'original': original,
        'correction': correction,
        'explanation': explanation,
        'position': position,
      };
}

// ─── Speaking Evaluation ──────────────────────────────────────────

class SpeakingEvaluation {
  final double fluencyCoherence;
  final double lexicalResource;
  final double grammaticalRange;
  final double pronunciation;
  final double overallBand;
  final String? transcription;
  final List<String> feedback;
  final List<String> pronunciationIssues;
  final String? sampleAnswer;

  const SpeakingEvaluation({
    required this.fluencyCoherence,
    required this.lexicalResource,
    required this.grammaticalRange,
    required this.pronunciation,
    required this.overallBand,
    this.transcription,
    this.feedback = const [],
    this.pronunciationIssues = const [],
    this.sampleAnswer,
  });

  factory SpeakingEvaluation.fromJson(Map<String, dynamic> json) =>
      SpeakingEvaluation(
        fluencyCoherence:
            (json['fluencyCoherence'] as num?)?.toDouble() ?? 0,
        lexicalResource:
            (json['lexicalResource'] as num?)?.toDouble() ?? 0,
        grammaticalRange:
            (json['grammaticalRange'] as num?)?.toDouble() ?? 0,
        pronunciation:
            (json['pronunciation'] as num?)?.toDouble() ?? 0,
        overallBand: (json['overallBand'] as num?)?.toDouble() ?? 0,
        transcription: json['transcription'],
        feedback: List<String>.from(json['feedback'] ?? []),
        pronunciationIssues:
            List<String>.from(json['pronunciationIssues'] ?? []),
        sampleAnswer: json['sampleAnswer'],
      );

  Map<String, dynamic> toJson() => {
        'fluencyCoherence': fluencyCoherence,
        'lexicalResource': lexicalResource,
        'grammaticalRange': grammaticalRange,
        'pronunciation': pronunciation,
        'overallBand': overallBand,
        'transcription': transcription,
        'feedback': feedback,
        'pronunciationIssues': pronunciationIssues,
        'sampleAnswer': sampleAnswer,
      };
}

// ─── Skill Result ─────────────────────────────────────────────────

class SkillResult {
  final IELTSSectionType section;
  final double bandScore;
  final int correctAnswers;
  final int totalQuestions;
  final List<double> sectionScores; // Per sub-section
  final Map<String, double> questionTypeAccuracy;
  final int timeSpentSeconds;
  final String? feedback;
  final WritingEvaluation? writingEvaluation;
  final SpeakingEvaluation? speakingEvaluation;

  const SkillResult({
    required this.section,
    required this.bandScore,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.sectionScores = const [],
    this.questionTypeAccuracy = const {},
    this.timeSpentSeconds = 0,
    this.feedback,
    this.writingEvaluation,
    this.speakingEvaluation,
  });

  double get accuracy =>
      totalQuestions > 0 ? correctAnswers / totalQuestions : 0;

  factory SkillResult.fromJson(Map<String, dynamic> json) => SkillResult(
        section: IELTSSectionType.values.firstWhere(
          (e) => e.name == json['section'],
          orElse: () => IELTSSectionType.listening,
        ),
        bandScore: (json['bandScore'] as num?)?.toDouble() ?? 0,
        correctAnswers: json['correctAnswers'] ?? 0,
        totalQuestions: json['totalQuestions'] ?? 0,
        sectionScores: (json['sectionScores'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
        questionTypeAccuracy:
            (json['questionTypeAccuracy'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                ) ??
                {},
        timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
        feedback: json['feedback'],
        writingEvaluation: json['writingEvaluation'] != null
            ? WritingEvaluation.fromJson(
                Map<String, dynamic>.from(json['writingEvaluation']))
            : null,
        speakingEvaluation: json['speakingEvaluation'] != null
            ? SpeakingEvaluation.fromJson(
                Map<String, dynamic>.from(json['speakingEvaluation']))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'section': section.name,
        'bandScore': bandScore,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'sectionScores': sectionScores,
        'questionTypeAccuracy': questionTypeAccuracy,
        'timeSpentSeconds': timeSpentSeconds,
        'feedback': feedback,
        'writingEvaluation': writingEvaluation?.toJson(),
        'speakingEvaluation': speakingEvaluation?.toJson(),
      };
}

// ─── Exam Result ──────────────────────────────────────────────────

class ExamResult {
  final String id;
  final double overallBand;
  final String cefrLevel;
  final Map<IELTSSectionType, SkillResult> skillResults;
  final DateTime examDate;
  final int totalDurationSeconds;
  final String? aiReport; // Markdown-formatted personalized report
  final List<String> strengths;
  final List<String> areasForImprovement;
  final List<String> recommendations;

  ExamResult({
    required this.id,
    required this.overallBand,
    String? cefrLevel,
    required this.skillResults,
    DateTime? examDate,
    this.totalDurationSeconds = 0,
    this.aiReport,
    this.strengths = const [],
    this.areasForImprovement = const [],
    this.recommendations = const [],
  })  : cefrLevel = cefrLevel ?? BandScoreDescriptor.cefrForBand(overallBand),
        examDate = examDate ?? DateTime.now();

  Color get scoreColor => BandScoreDescriptor.colorForBand(overallBand);
  String get scoreLabel => BandScoreDescriptor.labelForBand(overallBand);

  double get listeningBand =>
      skillResults[IELTSSectionType.listening]?.bandScore ?? 0;
  double get readingBand =>
      skillResults[IELTSSectionType.reading]?.bandScore ?? 0;
  double get writingBand =>
      skillResults[IELTSSectionType.writing]?.bandScore ?? 0;
  double get speakingBand =>
      skillResults[IELTSSectionType.speaking]?.bandScore ?? 0;

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final skillMap = <IELTSSectionType, SkillResult>{};
    if (json['skillResults'] is Map) {
      for (final entry in (json['skillResults'] as Map).entries) {
        final section = IELTSSectionType.values.firstWhere(
          (e) => e.name == entry.key.toString(),
          orElse: () => IELTSSectionType.listening,
        );
        skillMap[section] =
            SkillResult.fromJson(Map<String, dynamic>.from(entry.value));
      }
    }

    return ExamResult(
      id: json['id'] ?? '',
      overallBand: (json['overallBand'] as num?)?.toDouble() ?? 0,
      cefrLevel: json['cefrLevel'],
      skillResults: skillMap,
      examDate: DateTime.tryParse(json['examDate'] ?? ''),
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      aiReport: json['aiReport'],
      strengths: List<String>.from(json['strengths'] ?? []),
      areasForImprovement:
          List<String>.from(json['areasForImprovement'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'overallBand': overallBand,
        'cefrLevel': cefrLevel,
        'skillResults': skillResults
            .map((k, v) => MapEntry(k.name, v.toJson())),
        'examDate': examDate.toIso8601String(),
        'totalDurationSeconds': totalDurationSeconds,
        'aiReport': aiReport,
        'strengths': strengths,
        'areasForImprovement': areasForImprovement,
        'recommendations': recommendations,
      };
}
