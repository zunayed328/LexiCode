import 'package:flutter/material.dart';
import 'user_progress_model.dart';

// ─── Exercise Type ────────────────────────────────────────────────

enum ExerciseType {
  mcq,
  fillBlank,
  trueFalse,
  errorCorrection,
  sentenceConstruction,
  listenAndSpell,
  minimalPairs,
  matching,
  storyChoice,
  writingPrompt,
  speakingPrompt,
  spelling,
}

extension ExerciseTypeX on ExerciseType {
  String get label {
    switch (this) {
      case ExerciseType.mcq:
        return 'Multiple Choice';
      case ExerciseType.fillBlank:
        return 'Fill in the Blank';
      case ExerciseType.trueFalse:
        return 'True or False';
      case ExerciseType.errorCorrection:
        return 'Error Correction';
      case ExerciseType.sentenceConstruction:
        return 'Sentence Construction';
      case ExerciseType.listenAndSpell:
        return 'Listen & Spell';
      case ExerciseType.minimalPairs:
        return 'Minimal Pairs';
      case ExerciseType.matching:
        return 'Matching';
      case ExerciseType.storyChoice:
        return 'Story Choice';
      case ExerciseType.writingPrompt:
        return 'Writing';
      case ExerciseType.speakingPrompt:
        return 'Speaking';
      case ExerciseType.spelling:
        return 'Spelling';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseType.mcq:
        return Icons.check_circle_outline_rounded;
      case ExerciseType.fillBlank:
        return Icons.text_fields_rounded;
      case ExerciseType.trueFalse:
        return Icons.thumbs_up_down_rounded;
      case ExerciseType.errorCorrection:
        return Icons.edit_rounded;
      case ExerciseType.sentenceConstruction:
        return Icons.construction_rounded;
      case ExerciseType.listenAndSpell:
        return Icons.hearing_rounded;
      case ExerciseType.minimalPairs:
        return Icons.compare_arrows_rounded;
      case ExerciseType.matching:
        return Icons.link_rounded;
      case ExerciseType.storyChoice:
        return Icons.auto_stories_rounded;
      case ExerciseType.writingPrompt:
        return Icons.create_rounded;
      case ExerciseType.speakingPrompt:
        return Icons.mic_rounded;
      case ExerciseType.spelling:
        return Icons.spellcheck_rounded;
    }
  }
}

// ─── Exercise Difficulty ──────────────────────────────────────────

enum ExerciseDifficulty { veryEasy, easy, medium, hard, challenging }

extension ExerciseDifficultyX on ExerciseDifficulty {
  String get label {
    switch (this) {
      case ExerciseDifficulty.veryEasy:
        return 'Very Easy';
      case ExerciseDifficulty.easy:
        return 'Easy';
      case ExerciseDifficulty.medium:
        return 'Medium';
      case ExerciseDifficulty.hard:
        return 'Hard';
      case ExerciseDifficulty.challenging:
        return 'Challenging';
    }
  }

  Color get color {
    switch (this) {
      case ExerciseDifficulty.veryEasy:
        return const Color(0xFF10B981);
      case ExerciseDifficulty.easy:
        return const Color(0xFF34D399);
      case ExerciseDifficulty.medium:
        return const Color(0xFFFBBF24);
      case ExerciseDifficulty.hard:
        return const Color(0xFFF59E0B);
      case ExerciseDifficulty.challenging:
        return const Color(0xFFEF4444);
    }
  }

  double get difficultyValue {
    switch (this) {
      case ExerciseDifficulty.veryEasy:
        return 1;
      case ExerciseDifficulty.easy:
        return 2;
      case ExerciseDifficulty.medium:
        return 3;
      case ExerciseDifficulty.hard:
        return 4;
      case ExerciseDifficulty.challenging:
        return 5;
    }
  }
}

// ─── Exercise ─────────────────────────────────────────────────────

class Exercise {
  final String id;
  final ExerciseType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final List<String>? alternateCorrectAnswers;
  final String explanation;
  final ExerciseDifficulty difficulty;
  final int points;
  final String? hint;
  final int? timeLimitSeconds;
  final String? codeSnippet;
  final String? audioText;
  final String? imageDescription;
  final String? imageUrl;
  final String? context;

  const Exercise({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    required this.correctAnswer,
    this.alternateCorrectAnswers,
    this.explanation = '',
    this.difficulty = ExerciseDifficulty.medium,
    this.points = 10,
    this.hint,
    this.timeLimitSeconds,
    this.codeSnippet,
    this.audioText,
    this.imageDescription,
    this.imageUrl,
    this.context,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] ?? '',
        type: ExerciseType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ExerciseType.mcq,
        ),
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctAnswer: json['correctAnswer'] ?? '',
        alternateCorrectAnswers: json['alternateCorrectAnswers'] != null
            ? List<String>.from(json['alternateCorrectAnswers'])
            : null,
        explanation: json['explanation'] ?? '',
        difficulty: ExerciseDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => ExerciseDifficulty.medium,
        ),
        points: json['points'] ?? 10,
        hint: json['hint'],
        timeLimitSeconds: json['timeLimitSeconds'],
        codeSnippet: json['codeSnippet'],
        audioText: json['audioText'],
        imageDescription: json['imageDescription'],
        imageUrl: json['imageUrl'],
        context: json['context'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'alternateCorrectAnswers': alternateCorrectAnswers,
        'explanation': explanation,
        'difficulty': difficulty.name,
        'points': points,
        'hint': hint,
        'timeLimitSeconds': timeLimitSeconds,
        'codeSnippet': codeSnippet,
        'audioText': audioText,
        'imageDescription': imageDescription,
        'imageUrl': imageUrl,
        'context': context,
      };
}

// ─── Exercise Result ──────────────────────────────────────────────

class ExerciseResult {
  final String exerciseId;
  final String userAnswer;
  final bool isCorrect;
  final int timeSpentSeconds;
  final int scoreEarned;
  final String? feedback;

  const ExerciseResult({
    required this.exerciseId,
    required this.userAnswer,
    required this.isCorrect,
    this.timeSpentSeconds = 0,
    this.scoreEarned = 0,
    this.feedback,
  });

  factory ExerciseResult.fromJson(Map<String, dynamic> json) =>
      ExerciseResult(
        exerciseId: json['exerciseId'] ?? '',
        userAnswer: json['userAnswer'] ?? '',
        isCorrect: json['isCorrect'] ?? false,
        timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
        scoreEarned: json['scoreEarned'] ?? 0,
        feedback: json['feedback'],
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'userAnswer': userAnswer,
        'isCorrect': isCorrect,
        'timeSpentSeconds': timeSpentSeconds,
        'scoreEarned': scoreEarned,
        'feedback': feedback,
      };
}

// ─── Session Type ─────────────────────────────────────────────────

enum SessionType {
  grammarPractice,
  pronunciationPractice,
  spellingPractice,
  readingPractice,
  writingPractice,
  listeningPractice,
  speakingPractice,
  dailyPractice,
  weeklyChallenge,
  ieltsExam,
  mixedSkills,
}

extension SessionTypeX on SessionType {
  String get label {
    switch (this) {
      case SessionType.grammarPractice:
        return 'Grammar Practice';
      case SessionType.pronunciationPractice:
        return 'Pronunciation';
      case SessionType.spellingPractice:
        return 'Spelling Challenge';
      case SessionType.readingPractice:
        return 'Reading Practice';
      case SessionType.writingPractice:
        return 'Writing Lab';
      case SessionType.listeningPractice:
        return 'Listening Practice';
      case SessionType.speakingPractice:
        return 'Speaking Practice';
      case SessionType.dailyPractice:
        return 'Daily Practice';
      case SessionType.weeklyChallenge:
        return 'Weekly Challenge';
      case SessionType.ieltsExam:
        return 'IELTS Exam';
      case SessionType.mixedSkills:
        return 'Mixed Skills';
    }
  }

  IconData get icon {
    switch (this) {
      case SessionType.grammarPractice:
        return Icons.menu_book_rounded;
      case SessionType.pronunciationPractice:
        return Icons.record_voice_over_rounded;
      case SessionType.spellingPractice:
        return Icons.spellcheck_rounded;
      case SessionType.readingPractice:
        return Icons.auto_stories_rounded;
      case SessionType.writingPractice:
        return Icons.create_rounded;
      case SessionType.listeningPractice:
        return Icons.headphones_rounded;
      case SessionType.speakingPractice:
        return Icons.mic_rounded;
      case SessionType.dailyPractice:
        return Icons.today_rounded;
      case SessionType.weeklyChallenge:
        return Icons.emoji_events_rounded;
      case SessionType.ieltsExam:
        return Icons.school_rounded;
      case SessionType.mixedSkills:
        return Icons.shuffle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SessionType.grammarPractice:
        return const Color(0xFF3B82F6);
      case SessionType.pronunciationPractice:
        return const Color(0xFFF97316);
      case SessionType.spellingPractice:
        return const Color(0xFF8B5CF6);
      case SessionType.readingPractice:
        return const Color(0xFF10B981);
      case SessionType.writingPractice:
        return const Color(0xFFEC4899);
      case SessionType.listeningPractice:
        return const Color(0xFF14B8A6);
      case SessionType.speakingPractice:
        return const Color(0xFFEF4444);
      case SessionType.dailyPractice:
        return const Color(0xFFF59E0B);
      case SessionType.weeklyChallenge:
        return const Color(0xFF6366F1);
      case SessionType.ieltsExam:
        return const Color(0xFF8B5CF6);
      case SessionType.mixedSkills:
        return const Color(0xFF64748B);
    }
  }
}

// ─── Exercise Session ─────────────────────────────────────────────

class ExerciseSession {
  final String id;
  final SessionType sessionType;
  final LearningLevel level;
  final List<Exercise> exercises;
  final List<ExerciseResult> results;
  final int totalScore;
  final int maxScore;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? topic;
  final String? warmupText;
  final String? cooldownReflection;

  ExerciseSession({
    required this.id,
    required this.sessionType,
    required this.level,
    this.exercises = const [],
    this.results = const [],
    this.totalScore = 0,
    int? maxScore,
    this.durationSeconds = 0,
    DateTime? startedAt,
    this.completedAt,
    this.topic,
    this.warmupText,
    this.cooldownReflection,
  })  : maxScore = maxScore ?? exercises.fold<int>(0, (s, e) => s + e.points),
        startedAt = startedAt ?? DateTime.now();

  bool get isComplete =>
      completedAt != null || results.length >= exercises.length;

  double get accuracy {
    if (results.isEmpty) return 0;
    return results.where((r) => r.isCorrect).length / results.length;
  }

  double get progress =>
      exercises.isEmpty ? 0 : results.length / exercises.length;

  int get correctCount => results.where((r) => r.isCorrect).length;
  int get incorrectCount => results.where((r) => !r.isCorrect).length;

  factory ExerciseSession.fromJson(Map<String, dynamic> json) =>
      ExerciseSession(
        id: json['id'] ?? '',
        sessionType: SessionType.values.firstWhere(
          (e) => e.name == json['sessionType'],
          orElse: () => SessionType.grammarPractice,
        ),
        level: LearningLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => LearningLevel.beginner,
        ),
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        results: (json['results'] as List<dynamic>?)
                ?.map((e) =>
                    ExerciseResult.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        totalScore: json['totalScore'] ?? 0,
        maxScore: json['maxScore'],
        durationSeconds: json['durationSeconds'] ?? 0,
        startedAt: DateTime.tryParse(json['startedAt'] ?? ''),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'])
            : null,
        topic: json['topic'],
        warmupText: json['warmupText'],
        cooldownReflection: json['cooldownReflection'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionType': sessionType.name,
        'level': level.name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'results': results.map((e) => e.toJson()).toList(),
        'totalScore': totalScore,
        'maxScore': maxScore,
        'durationSeconds': durationSeconds,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'topic': topic,
        'warmupText': warmupText,
        'cooldownReflection': cooldownReflection,
      };
}
