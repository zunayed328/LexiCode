import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress_model.dart';

/// Handles persistence of user learning progress.
///
/// Uses SharedPreferences for local caching and can sync to Firestore
/// when Firebase is properly configured.
class ProgressTrackingService {
  static const _progressKey = 'user_learning_progress';

  // ─── Save & Load Progress ─────────────────────────────────────

  /// Saves user progress to local storage.
  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(progress.toJson());
    await prefs.setString(_progressKey, json);
  }

  /// Loads user progress from local storage.
  Future<UserProgress?> loadProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_progressKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserProgress.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Returns a default progress object for new users.
  UserProgress createDefaultProgress(String userId) {
    return UserProgress(
      userId: userId,
      currentLevel: LearningLevel.beginner,
      cefrLevel: CEFRLevel.a1,
      skillScores: {
        'grammar': const SkillScore(skill: 'grammar'),
        'pronunciation': const SkillScore(skill: 'pronunciation'),
        'spelling': const SkillScore(skill: 'spelling'),
        'reading': const SkillScore(skill: 'reading'),
        'writing': const SkillScore(skill: 'writing'),
        'listening': const SkillScore(skill: 'listening'),
        'speaking': const SkillScore(skill: 'speaking'),
      },
    );
  }

  // ─── Skill Score Updates ──────────────────────────────────────

  /// Updates a single skill score and records the entry in history.
  UserProgress updateSkillScore(
    UserProgress progress,
    String skill,
    double newScore,
  ) {
    final updatedSkills = Map<String, SkillScore>.from(progress.skillScores);

    final existing = updatedSkills[skill] ?? SkillScore(skill: skill);
    final newHistory = [
      ScoreEntry(score: newScore, date: DateTime.now()),
      ...existing.history,
    ].take(50).toList(); // Keep last 50 entries

    updatedSkills[skill] = existing.copyWith(
      currentScore: newScore,
      history: newHistory,
    );

    return progress.copyWith(
      skillScores: updatedSkills,
      updatedAt: DateTime.now(),
    );
  }

  // ─── Content History (Anti-Repetition) ────────────────────────

  /// Records that a piece of content was seen by the user.
  UserProgress recordContentSeen(
    UserProgress progress, {
    required String contentId,
    required String topic,
    required String contentType,
  }) {
    final newEntry = ContentHistory(
      userId: progress.userId,
      contentType: contentType,
      topic: topic,
      exerciseIds: [contentId],
      lastSeen: DateTime.now(),
    );

    final updatedHistory = [newEntry, ...progress.contentHistory];

    // Keep history manageable — last 500 entries
    final trimmed = updatedHistory.take(500).toList();

    return progress.copyWith(contentHistory: trimmed);
  }

  /// Builds exclusion data for AI prompts to avoid repetition.
  Map<String, dynamic> getExclusionData(UserProgress progress) {
    return {
      'excludeTopics': progress.recentTopics,
      'excludeContentIds': progress.recentContentIds,
    };
  }

  // ─── Streak Management ────────────────────────────────────────

  /// Updates the streak based on today's practice.
  UserProgress updateStreak(UserProgress progress) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final streak = progress.streak;

    // Already practiced today
    if (streak.isActiveToday) return progress;

    final lastPractice = streak.lastPracticeDate;
    int newStreak = streak.currentStreak;

    if (lastPractice != null) {
      final lastDay = DateTime(
        lastPractice.year,
        lastPractice.month,
        lastPractice.day,
      );
      final diff = today.difference(lastDay).inDays;

      if (diff == 1) {
        // Consecutive day — extend streak
        newStreak += 1;
      } else if (diff == 2 && streak.freezeTokens > 0) {
        // Missed one day but have a freeze token
        newStreak += 1;
        return progress.copyWith(
          streak: streak.copyWith(
            currentStreak: newStreak,
            longestStreak: newStreak > streak.longestStreak
                ? newStreak
                : streak.longestStreak,
            freezeTokens: streak.freezeTokens - 1,
            lastPracticeDate: now,
          ),
        );
      } else if (diff > 1) {
        // Streak broken
        newStreak = 1;
      }
    } else {
      // First ever practice
      newStreak = 1;
    }

    return progress.copyWith(
      streak: streak.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > streak.longestStreak
            ? newStreak
            : streak.longestStreak,
        lastPracticeDate: now,
      ),
    );
  }

  // ─── Daily Goals ──────────────────────────────────────────────

  /// Checks if daily goal needs reset (new day).
  UserProgress checkDailyGoals(UserProgress progress) {
    final now = DateTime.now();
    final goalDate = progress.dailyGoal.date;

    if (goalDate.year != now.year ||
        goalDate.month != now.month ||
        goalDate.day != now.day) {
      // New day — reset daily goals
      return progress.copyWith(dailyGoal: DailyGoal(date: now));
    }
    return progress;
  }

  /// Increments a specific daily goal counter.
  UserProgress incrementDailyGoal(
    UserProgress progress, {
    int grammarLessons = 0,
    int pronunciationMinutes = 0,
    int spellingWords = 0,
  }) {
    final goal = progress.dailyGoal;
    return progress.copyWith(
      dailyGoal: goal.copyWith(
        grammarLessonsCompleted: goal.grammarLessonsCompleted + grammarLessons,
        pronunciationMinutesCompleted:
            goal.pronunciationMinutesCompleted + pronunciationMinutes,
        spellingWordsCompleted: goal.spellingWordsCompleted + spellingWords,
      ),
    );
  }

  // ─── XP & Level ──────────────────────────────────────────────

  /// Adds XP and potentially levels up the user.
  UserProgress addXp(UserProgress progress, int xp) {
    final newXp = progress.totalXp + xp;

    // Auto-level based on XP thresholds
    LearningLevel newLevel = progress.currentLevel;
    CEFRLevel newCefr = progress.cefrLevel;

    if (newXp >= 5000 && progress.currentLevel == LearningLevel.beginner) {
      newLevel = LearningLevel.intermediate;
      newCefr = CEFRLevel.b1;
    } else if (newXp >= 15000 &&
        progress.currentLevel == LearningLevel.intermediate) {
      newLevel = LearningLevel.advanced;
      newCefr = CEFRLevel.c1;
    }

    return progress.copyWith(
      totalXp: newXp,
      currentLevel: newLevel,
      cefrLevel: newCefr,
    );
  }
}
