import 'package:flutter/material.dart';

// ─── Weakness ─────────────────────────────────────────────────────

enum WeaknessUrgency { high, medium, low }

class Weakness {
  final String skill;
  final String area;
  final String description;
  final String evidence;
  final double impactOnScore;
  final WeaknessUrgency urgency;

  const Weakness({
    required this.skill,
    required this.area,
    required this.description,
    this.evidence = '',
    this.impactOnScore = 0,
    this.urgency = WeaknessUrgency.medium,
  });

  Color get urgencyColor {
    switch (urgency) {
      case WeaknessUrgency.high:
        return const Color(0xFFEF4444);
      case WeaknessUrgency.medium:
        return const Color(0xFFF59E0B);
      case WeaknessUrgency.low:
        return const Color(0xFF3B82F6);
    }
  }

  factory Weakness.fromJson(Map<String, dynamic> json) => Weakness(
    skill: json['skill'] ?? '',
    area: json['area'] ?? '',
    description: json['description'] ?? '',
    evidence: json['evidence'] ?? '',
    impactOnScore: (json['impactOnScore'] as num?)?.toDouble() ?? 0,
    urgency: WeaknessUrgency.values.firstWhere(
      (e) => e.name == json['urgency'],
      orElse: () => WeaknessUrgency.medium,
    ),
  );

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'area': area,
    'description': description,
    'evidence': evidence,
    'impactOnScore': impactOnScore,
    'urgency': urgency.name,
  };
}

// ─── Weakness Analysis ────────────────────────────────────────────

class WeaknessAnalysis {
  final List<Weakness> criticalWeaknesses;
  final List<Weakness> moderateWeaknesses;
  final List<String> hiddenPatterns;
  final List<String> strengthsToLeverage;
  final Map<String, double> skillBalance;
  final DateTime analyzedAt;

  WeaknessAnalysis({
    this.criticalWeaknesses = const [],
    this.moderateWeaknesses = const [],
    this.hiddenPatterns = const [],
    this.strengthsToLeverage = const [],
    this.skillBalance = const {},
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory WeaknessAnalysis.fromJson(Map<String, dynamic> json) =>
      WeaknessAnalysis(
        criticalWeaknesses:
            (json['criticalWeaknesses'] as List<dynamic>?)
                ?.map((e) => Weakness.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        moderateWeaknesses:
            (json['moderateWeaknesses'] as List<dynamic>?)
                ?.map((e) => Weakness.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        hiddenPatterns: List<String>.from(json['hiddenPatterns'] ?? []),
        strengthsToLeverage: List<String>.from(
          json['strengthsToLeverage'] ?? [],
        ),
        skillBalance:
            (json['skillBalance'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
        analyzedAt: DateTime.tryParse(json['analyzedAt'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'criticalWeaknesses': criticalWeaknesses.map((e) => e.toJson()).toList(),
    'moderateWeaknesses': moderateWeaknesses.map((e) => e.toJson()).toList(),
    'hiddenPatterns': hiddenPatterns,
    'strengthsToLeverage': strengthsToLeverage,
    'skillBalance': skillBalance,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

// ─── Roadmap Phase ────────────────────────────────────────────────

class RoadmapPhase {
  final String name;
  final int durationWeeks;
  final List<String> objectives;
  final List<String> focusSkills;
  final Map<String, String> dailyActivities; // day → activity
  final String expectedImprovement;
  final bool isCompleted;
  final double progress;

  const RoadmapPhase({
    required this.name,
    required this.durationWeeks,
    this.objectives = const [],
    this.focusSkills = const [],
    this.dailyActivities = const {},
    this.expectedImprovement = '',
    this.isCompleted = false,
    this.progress = 0,
  });

  factory RoadmapPhase.fromJson(Map<String, dynamic> json) => RoadmapPhase(
    name: json['name'] ?? '',
    durationWeeks: json['durationWeeks'] ?? 4,
    objectives: List<String>.from(json['objectives'] ?? []),
    focusSkills: List<String>.from(json['focusSkills'] ?? []),
    dailyActivities: Map<String, String>.from(json['dailyActivities'] ?? {}),
    expectedImprovement: json['expectedImprovement'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'durationWeeks': durationWeeks,
    'objectives': objectives,
    'focusSkills': focusSkills,
    'dailyActivities': dailyActivities,
    'expectedImprovement': expectedImprovement,
    'isCompleted': isCompleted,
    'progress': progress,
  };
}

// ─── Learning Roadmap ─────────────────────────────────────────────

class LearningRoadmap {
  final String id;
  final String goal;
  final String overallStrategy;
  final List<RoadmapPhase> phases;
  final Map<String, String> weeklySchedule; // day → activities
  final List<String> milestones;
  final List<String> successMetrics;
  final DateTime createdAt;
  final DateTime? targetDate;

  LearningRoadmap({
    required this.id,
    required this.goal,
    this.overallStrategy = '',
    this.phases = const [],
    this.weeklySchedule = const {},
    this.milestones = const [],
    this.successMetrics = const [],
    DateTime? createdAt,
    this.targetDate,
  }) : createdAt = createdAt ?? DateTime.now();

  double get overallProgress {
    if (phases.isEmpty) return 0;
    return phases.fold<double>(0, (s, p) => s + p.progress) / phases.length;
  }

  factory LearningRoadmap.fromJson(Map<String, dynamic> json) =>
      LearningRoadmap(
        id: json['id'] ?? '',
        goal: json['goal'] ?? '',
        overallStrategy: json['overallStrategy'] ?? '',
        phases:
            (json['phases'] as List<dynamic>?)
                ?.map(
                  (e) => RoadmapPhase.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList() ??
            [],
        weeklySchedule: Map<String, String>.from(json['weeklySchedule'] ?? {}),
        milestones: List<String>.from(json['milestones'] ?? []),
        successMetrics: List<String>.from(json['successMetrics'] ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        targetDate: json['targetDate'] != null
            ? DateTime.tryParse(json['targetDate'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'goal': goal,
    'overallStrategy': overallStrategy,
    'phases': phases.map((e) => e.toJson()).toList(),
    'weeklySchedule': weeklySchedule,
    'milestones': milestones,
    'successMetrics': successMetrics,
    'createdAt': createdAt.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
  };
}

// ─── Daily Suggestion ─────────────────────────────────────────────

class SuggestedActivity {
  final String type;
  final String topic;
  final int durationMinutes;
  final String reason;
  final String difficulty;

  const SuggestedActivity({
    required this.type,
    required this.topic,
    required this.durationMinutes,
    this.reason = '',
    this.difficulty = 'Intermediate',
  });

  factory SuggestedActivity.fromJson(Map<String, dynamic> json) =>
      SuggestedActivity(
        type: json['type'] ?? '',
        topic: json['topic'] ?? '',
        durationMinutes: json['durationMinutes'] ?? 15,
        reason: json['reason'] ?? '',
        difficulty: json['difficulty'] ?? 'Intermediate',
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'topic': topic,
    'durationMinutes': durationMinutes,
    'reason': reason,
    'difficulty': difficulty,
  };
}

class DailySuggestion {
  final SuggestedActivity mainActivity;
  final SuggestedActivity? secondaryActivity;
  final SuggestedActivity? bonusActivity;
  final String motivationalMessage;
  final String expectedOutcome;
  final DateTime date;

  DailySuggestion({
    required this.mainActivity,
    this.secondaryActivity,
    this.bonusActivity,
    this.motivationalMessage = '',
    this.expectedOutcome = '',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  int get totalMinutes {
    var total = mainActivity.durationMinutes;
    if (secondaryActivity != null) total += secondaryActivity!.durationMinutes;
    if (bonusActivity != null) total += bonusActivity!.durationMinutes;
    return total;
  }

  factory DailySuggestion.fromJson(Map<String, dynamic> json) =>
      DailySuggestion(
        mainActivity: SuggestedActivity.fromJson(
          Map<String, dynamic>.from(json['mainActivity'] ?? {}),
        ),
        secondaryActivity: json['secondaryActivity'] != null
            ? SuggestedActivity.fromJson(
                Map<String, dynamic>.from(json['secondaryActivity']),
              )
            : null,
        bonusActivity: json['bonusActivity'] != null
            ? SuggestedActivity.fromJson(
                Map<String, dynamic>.from(json['bonusActivity']),
              )
            : null,
        motivationalMessage: json['motivationalMessage'] ?? '',
        expectedOutcome: json['expectedOutcome'] ?? '',
        date: DateTime.tryParse(json['date'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'mainActivity': mainActivity.toJson(),
    'secondaryActivity': secondaryActivity?.toJson(),
    'bonusActivity': bonusActivity?.toJson(),
    'motivationalMessage': motivationalMessage,
    'expectedOutcome': expectedOutcome,
    'date': date.toIso8601String(),
  };
}

// ─── Weekly Challenge Result ──────────────────────────────────────

class WeeklyChallengeResult {
  final String id;
  final int weekNumber;
  final Map<String, double> sectionScores;
  final int totalScore;
  final int maxScore;
  final int? rank;
  final int xpEarned;
  final double improvementVsLastWeek;
  final DateTime completedAt;

  WeeklyChallengeResult({
    required this.id,
    required this.weekNumber,
    this.sectionScores = const {},
    this.totalScore = 0,
    this.maxScore = 100,
    this.rank,
    this.xpEarned = 0,
    this.improvementVsLastWeek = 0,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  double get percentage => maxScore > 0 ? totalScore / maxScore * 100 : 0;

  factory WeeklyChallengeResult.fromJson(Map<String, dynamic> json) =>
      WeeklyChallengeResult(
        id: json['id'] ?? '',
        weekNumber: json['weekNumber'] ?? 0,
        sectionScores:
            (json['sectionScores'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
        totalScore: json['totalScore'] ?? 0,
        maxScore: json['maxScore'] ?? 100,
        rank: json['rank'],
        xpEarned: json['xpEarned'] ?? 0,
        improvementVsLastWeek:
            (json['improvementVsLastWeek'] as num?)?.toDouble() ?? 0,
        completedAt: DateTime.tryParse(json['completedAt'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekNumber': weekNumber,
    'sectionScores': sectionScores,
    'totalScore': totalScore,
    'maxScore': maxScore,
    'rank': rank,
    'xpEarned': xpEarned,
    'improvementVsLastWeek': improvementVsLastWeek,
    'completedAt': completedAt.toIso8601String(),
  };
}
