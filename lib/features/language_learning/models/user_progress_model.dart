import 'package:flutter/material.dart';

// ─── Learning Level ───────────────────────────────────────────────

enum LearningLevel { beginner, intermediate, advanced }

extension LearningLevelX on LearningLevel {
  String get label {
    switch (this) {
      case LearningLevel.beginner:
        return 'Beginner';
      case LearningLevel.intermediate:
        return 'Intermediate';
      case LearningLevel.advanced:
        return 'Advanced';
    }
  }

  String get cefrRange {
    switch (this) {
      case LearningLevel.beginner:
        return 'A1–A2';
      case LearningLevel.intermediate:
        return 'B1–B2';
      case LearningLevel.advanced:
        return 'C1–C2';
    }
  }

  IconData get icon {
    switch (this) {
      case LearningLevel.beginner:
        return Icons.school_rounded;
      case LearningLevel.intermediate:
        return Icons.trending_up_rounded;
      case LearningLevel.advanced:
        return Icons.workspace_premium_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LearningLevel.beginner:
        return const Color(0xFF10B981);
      case LearningLevel.intermediate:
        return const Color(0xFF3B82F6);
      case LearningLevel.advanced:
        return const Color(0xFF8B5CF6);
    }
  }
}

// ─── CEFR Level ───────────────────────────────────────────────────

enum CEFRLevel { a1, a2, b1, b2, c1, c2 }

extension CEFRLevelX on CEFRLevel {
  String get label {
    switch (this) {
      case CEFRLevel.a1:
        return 'A1 – Beginner';
      case CEFRLevel.a2:
        return 'A2 – Elementary';
      case CEFRLevel.b1:
        return 'B1 – Intermediate';
      case CEFRLevel.b2:
        return 'B2 – Upper Intermediate';
      case CEFRLevel.c1:
        return 'C1 – Advanced';
      case CEFRLevel.c2:
        return 'C2 – Proficiency';
    }
  }

  String get shortLabel => name.toUpperCase();
}

// ─── Skill Score ──────────────────────────────────────────────────

class SkillScore {
  final String
  skill; // grammar, pronunciation, spelling, reading, writing, listening, speaking
  final double currentScore; // 0–100
  final List<ScoreEntry> history;

  const SkillScore({
    required this.skill,
    this.currentScore = 0,
    this.history = const [],
  });

  double get improvementTrend {
    if (history.length < 2) return 0;
    final recent = history.take(5).map((e) => e.score).toList();
    final older = history.skip(5).take(5).map((e) => e.score).toList();
    if (older.isEmpty) return 0;
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    return recentAvg - olderAvg;
  }

  SkillScore copyWith({
    String? skill,
    double? currentScore,
    List<ScoreEntry>? history,
  }) => SkillScore(
    skill: skill ?? this.skill,
    currentScore: currentScore ?? this.currentScore,
    history: history ?? this.history,
  );

  factory SkillScore.fromJson(Map<String, dynamic> json) => SkillScore(
    skill: json['skill'] ?? '',
    currentScore: (json['currentScore'] as num?)?.toDouble() ?? 0,
    history:
        (json['history'] as List<dynamic>?)
            ?.map((e) => ScoreEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'currentScore': currentScore,
    'history': history.map((e) => e.toJson()).toList(),
  };
}

class ScoreEntry {
  final double score;
  final DateTime date;

  const ScoreEntry({required this.score, required this.date});

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    score: (json['score'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'score': score,
    'date': date.toIso8601String(),
  };
}

// ─── Content History (Anti-Repetition) ────────────────────────────

class ContentHistory {
  final String userId;
  final String contentType; // grammar, pronunciation, spelling, reading, etc.
  final String topic;
  final List<String> exerciseIds;
  final DateTime lastSeen;
  final int timesCompleted;

  const ContentHistory({
    required this.userId,
    required this.contentType,
    required this.topic,
    this.exerciseIds = const [],
    required this.lastSeen,
    this.timesCompleted = 1,
  });

  factory ContentHistory.fromJson(Map<String, dynamic> json) => ContentHistory(
    userId: json['userId'] ?? '',
    contentType: json['contentType'] ?? '',
    topic: json['topic'] ?? '',
    exerciseIds: List<String>.from(json['exerciseIds'] ?? []),
    lastSeen: DateTime.tryParse(json['lastSeen'] ?? '') ?? DateTime.now(),
    timesCompleted: json['timesCompleted'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'contentType': contentType,
    'topic': topic,
    'exerciseIds': exerciseIds,
    'lastSeen': lastSeen.toIso8601String(),
    'timesCompleted': timesCompleted,
  };
}

// ─── Daily Goal ───────────────────────────────────────────────────

class DailyGoal {
  final int grammarLessonsTarget;
  final int grammarLessonsCompleted;
  final int pronunciationMinutesTarget;
  final int pronunciationMinutesCompleted;
  final int spellingWordsTarget;
  final int spellingWordsCompleted;
  final DateTime date;

  const DailyGoal({
    this.grammarLessonsTarget = 1,
    this.grammarLessonsCompleted = 0,
    this.pronunciationMinutesTarget = 10,
    this.pronunciationMinutesCompleted = 0,
    this.spellingWordsTarget = 15,
    this.spellingWordsCompleted = 0,
    required this.date,
  });

  bool get grammarGoalMet => grammarLessonsCompleted >= grammarLessonsTarget;
  bool get pronunciationGoalMet =>
      pronunciationMinutesCompleted >= pronunciationMinutesTarget;
  bool get spellingGoalMet => spellingWordsCompleted >= spellingWordsTarget;
  bool get allGoalsMet =>
      grammarGoalMet && pronunciationGoalMet && spellingGoalMet;

  double get overallProgress {
    final g = grammarLessonsTarget > 0
        ? (grammarLessonsCompleted / grammarLessonsTarget).clamp(0.0, 1.0)
        : 1.0;
    final p = pronunciationMinutesTarget > 0
        ? (pronunciationMinutesCompleted / pronunciationMinutesTarget).clamp(
            0.0,
            1.0,
          )
        : 1.0;
    final s = spellingWordsTarget > 0
        ? (spellingWordsCompleted / spellingWordsTarget).clamp(0.0, 1.0)
        : 1.0;
    return (g + p + s) / 3;
  }

  DailyGoal copyWith({
    int? grammarLessonsCompleted,
    int? pronunciationMinutesCompleted,
    int? spellingWordsCompleted,
  }) => DailyGoal(
    grammarLessonsTarget: grammarLessonsTarget,
    grammarLessonsCompleted:
        grammarLessonsCompleted ?? this.grammarLessonsCompleted,
    pronunciationMinutesTarget: pronunciationMinutesTarget,
    pronunciationMinutesCompleted:
        pronunciationMinutesCompleted ?? this.pronunciationMinutesCompleted,
    spellingWordsTarget: spellingWordsTarget,
    spellingWordsCompleted:
        spellingWordsCompleted ?? this.spellingWordsCompleted,
    date: date,
  );

  factory DailyGoal.fromJson(Map<String, dynamic> json) => DailyGoal(
    grammarLessonsTarget: json['grammarLessonsTarget'] ?? 1,
    grammarLessonsCompleted: json['grammarLessonsCompleted'] ?? 0,
    pronunciationMinutesTarget: json['pronunciationMinutesTarget'] ?? 10,
    pronunciationMinutesCompleted: json['pronunciationMinutesCompleted'] ?? 0,
    spellingWordsTarget: json['spellingWordsTarget'] ?? 15,
    spellingWordsCompleted: json['spellingWordsCompleted'] ?? 0,
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'grammarLessonsTarget': grammarLessonsTarget,
    'grammarLessonsCompleted': grammarLessonsCompleted,
    'pronunciationMinutesTarget': pronunciationMinutesTarget,
    'pronunciationMinutesCompleted': pronunciationMinutesCompleted,
    'spellingWordsTarget': spellingWordsTarget,
    'spellingWordsCompleted': spellingWordsCompleted,
    'date': date.toIso8601String(),
  };
}

// ─── Learning Streak ──────────────────────────────────────────────

class LearningStreak {
  final int currentStreak;
  final int longestStreak;
  final int freezeTokens;
  final DateTime? lastPracticeDate;

  const LearningStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezeTokens = 1,
    this.lastPracticeDate,
  });

  bool get isActiveToday {
    if (lastPracticeDate == null) return false;
    final now = DateTime.now();
    return lastPracticeDate!.year == now.year &&
        lastPracticeDate!.month == now.month &&
        lastPracticeDate!.day == now.day;
  }

  LearningStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    int? freezeTokens,
    DateTime? lastPracticeDate,
  }) => LearningStreak(
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    freezeTokens: freezeTokens ?? this.freezeTokens,
    lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
  );

  factory LearningStreak.fromJson(Map<String, dynamic> json) => LearningStreak(
    currentStreak: json['currentStreak'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
    freezeTokens: json['freezeTokens'] ?? 1,
    lastPracticeDate: json['lastPracticeDate'] != null
        ? DateTime.tryParse(json['lastPracticeDate'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'freezeTokens': freezeTokens,
    'lastPracticeDate': lastPracticeDate?.toIso8601String(),
  };
}

// ─── User Progress (Root Model) ───────────────────────────────────

class UserProgress {
  final String userId;
  final LearningLevel currentLevel;
  final CEFRLevel cefrLevel;
  final int totalXp;
  final int totalLessonsCompleted;
  final int totalExercisesCompleted;
  final int vocabularyMastered;
  final Map<String, SkillScore> skillScores;
  final List<ContentHistory> contentHistory;
  final DailyGoal dailyGoal;
  final LearningStreak streak;
  final List<String> badges;
  final String? nativeLanguage;
  final String? learningGoal;
  final DateTime? goalDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProgress({
    required this.userId,
    this.currentLevel = LearningLevel.beginner,
    this.cefrLevel = CEFRLevel.a1,
    this.totalXp = 0,
    this.totalLessonsCompleted = 0,
    this.totalExercisesCompleted = 0,
    this.vocabularyMastered = 0,
    this.skillScores = const {},
    this.contentHistory = const [],
    DailyGoal? dailyGoal,
    this.streak = const LearningStreak(),
    this.badges = const [],
    this.nativeLanguage,
    this.learningGoal,
    this.goalDeadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : dailyGoal = dailyGoal ?? DailyGoal(date: DateTime.now()),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  _UserSkills get skills => _UserSkills(skillScores);

  double get overallScore {
    if (skillScores.isEmpty) return 0;
    final sum = skillScores.values.fold<double>(
      0,
      (a, b) => a + b.currentScore,
    );
    return sum / skillScores.length;
  }

  int get levelNumber {
    switch (currentLevel) {
      case LearningLevel.beginner:
        return 1;
      case LearningLevel.intermediate:
        return 2;
      case LearningLevel.advanced:
        return 3;
    }
  }

  /// Recently seen topics for anti-repetition (last 30 days).
  List<String> get recentTopics {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return contentHistory
        .where((h) => h.lastSeen.isAfter(cutoff))
        .map((h) => h.topic)
        .toSet()
        .toList();
  }

  /// Recently seen content IDs for anti-repetition (last 90 days).
  List<String> get recentContentIds {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    return contentHistory
        .where((h) => h.lastSeen.isAfter(cutoff))
        .expand((h) => h.exerciseIds)
        .toSet()
        .toList();
  }

  UserProgress copyWith({
    LearningLevel? currentLevel,
    CEFRLevel? cefrLevel,
    int? totalXp,
    int? totalLessonsCompleted,
    int? totalExercisesCompleted,
    int? vocabularyMastered,
    Map<String, SkillScore>? skillScores,
    List<ContentHistory>? contentHistory,
    DailyGoal? dailyGoal,
    LearningStreak? streak,
    List<String>? badges,
    String? nativeLanguage,
    String? learningGoal,
    DateTime? goalDeadline,
    DateTime? updatedAt,
  }) => UserProgress(
    userId: userId,
    currentLevel: currentLevel ?? this.currentLevel,
    cefrLevel: cefrLevel ?? this.cefrLevel,
    totalXp: totalXp ?? this.totalXp,
    totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
    totalExercisesCompleted:
        totalExercisesCompleted ?? this.totalExercisesCompleted,
    vocabularyMastered: vocabularyMastered ?? this.vocabularyMastered,
    skillScores: skillScores ?? this.skillScores,
    contentHistory: contentHistory ?? this.contentHistory,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    streak: streak ?? this.streak,
    badges: badges ?? this.badges,
    nativeLanguage: nativeLanguage ?? this.nativeLanguage,
    learningGoal: learningGoal ?? this.learningGoal,
    goalDeadline: goalDeadline ?? this.goalDeadline,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final skillMap = <String, SkillScore>{};
    if (json['skillScores'] is Map) {
      for (final entry in (json['skillScores'] as Map).entries) {
        skillMap[entry.key.toString()] = SkillScore.fromJson(
          Map<String, dynamic>.from(entry.value),
        );
      }
    }

    return UserProgress(
      userId: json['userId'] ?? '',
      currentLevel: LearningLevel.values.firstWhere(
        (e) => e.name == json['currentLevel'],
        orElse: () => LearningLevel.beginner,
      ),
      cefrLevel: CEFRLevel.values.firstWhere(
        (e) => e.name == json['cefrLevel'],
        orElse: () => CEFRLevel.a1,
      ),
      totalXp: json['totalXp'] ?? 0,
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalExercisesCompleted: json['totalExercisesCompleted'] ?? 0,
      vocabularyMastered: json['vocabularyMastered'] ?? 0,
      skillScores: skillMap,
      contentHistory:
          (json['contentHistory'] as List<dynamic>?)
              ?.map(
                (e) => ContentHistory.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      dailyGoal: json['dailyGoal'] != null
          ? DailyGoal.fromJson(Map<String, dynamic>.from(json['dailyGoal']))
          : null,
      streak: json['streak'] != null
          ? LearningStreak.fromJson(Map<String, dynamic>.from(json['streak']))
          : const LearningStreak(),
      badges: List<String>.from(json['badges'] ?? []),
      nativeLanguage: json['nativeLanguage'],
      learningGoal: json['learningGoal'],
      goalDeadline: json['goalDeadline'] != null
          ? DateTime.tryParse(json['goalDeadline'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'currentLevel': currentLevel.name,
    'cefrLevel': cefrLevel.name,
    'totalXp': totalXp,
    'totalLessonsCompleted': totalLessonsCompleted,
    'totalExercisesCompleted': totalExercisesCompleted,
    'vocabularyMastered': vocabularyMastered,
    'skillScores': skillScores.map((k, v) => MapEntry(k, v.toJson())),
    'contentHistory': contentHistory.map((e) => e.toJson()).toList(),
    'dailyGoal': dailyGoal.toJson(),
    'streak': streak.toJson(),
    'badges': badges,
    'nativeLanguage': nativeLanguage,
    'learningGoal': learningGoal,
    'goalDeadline': goalDeadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class _UserSkills {
  final Map<String, SkillScore> _scores;
  _UserSkills(this._scores);

  SkillScore get grammar =>
      _scores['grammar'] ?? const SkillScore(skill: 'grammar');
  SkillScore get pronunciation =>
      _scores['pronunciation'] ?? const SkillScore(skill: 'pronunciation');
  SkillScore get spelling =>
      _scores['spelling'] ?? const SkillScore(skill: 'spelling');
  SkillScore get reading =>
      _scores['reading'] ?? const SkillScore(skill: 'reading');
  SkillScore get writing =>
      _scores['writing'] ?? const SkillScore(skill: 'writing');
  SkillScore get listening =>
      _scores['listening'] ?? const SkillScore(skill: 'listening');
  SkillScore get speaking =>
      _scores['speaking'] ?? const SkillScore(skill: 'speaking');
}
