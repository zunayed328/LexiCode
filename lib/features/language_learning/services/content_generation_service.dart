import '../models/user_progress_model.dart';
import '../models/lesson_model.dart';
import '../models/exercise_model.dart';
import '../models/suggestion_model.dart';
import '../models/exam_result_model.dart';
import '../models/exercise_types_model.dart';
import 'gemini_learning_service.dart';
import 'progress_tracking_service.dart';

/// Orchestrates AI content generation with anti-repetition logic.
///
/// Sits between providers and [GeminiLearningService], handling
/// content history queries, AI calls, and post-generation persistence.
class ContentGenerationService {
  final GeminiLearningService _gemini = GeminiLearningService();
  final ProgressTrackingService _progressService = ProgressTrackingService();

  // ─── Lesson Generation ────────────────────────────────────────

  /// Generates a lesson, records it in content history, and returns it.
  Future<LearningLesson> getLesson(
    String topic,
    LearningLevel level,
    UserProgress progress,
  ) async {
    final lesson = await _gemini.generateBeginnerLesson(topic, progress);

    // We don't persist here — the provider will call progressService
    return lesson;
  }

  // ─── Exercise Generation ──────────────────────────────────────

  /// Generates an exercise session with anti-repetition.
  Future<ExerciseSession> getExercises(
    SessionType sessionType,
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
    int questionCount = 12,
  }) async {
    return await _gemini.generateExerciseSession(
      sessionType,
      level,
      progress,
      focusTopic: focusTopic,
      questionCount: questionCount,
    );
  }

  // ─── Specialized Content Generation ─────────────────────────────

  /// Generates a reading passage with comprehension questions.
  Future<ReadingPassage> getReadingPassage(
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
  }) async {
    return await _gemini.generateReadingPassage(
      level,
      progress,
      focusTopic: focusTopic,
    );
  }

  /// Generates a writing task.
  Future<WritingTask> getWritingTask(
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
  }) async {
    return await _gemini.generateWritingTask(
      level,
      progress,
      focusTopic: focusTopic,
    );
  }

  /// Generates speaking prompts.
  Future<List<SpeakingPrompt>> getSpeakingPrompts(
    LearningLevel level,
    UserProgress progress, {
    int count = 3,
  }) async {
    return await _gemini.generateSpeakingPrompts(level, progress, count: count);
  }

  // ─── Daily Practice ───────────────────────────────────────────

  /// Generates a daily practice session with day-of-week rotation.
  Future<ExerciseSession> getDailyPractice(
    DateTime date,
    UserProgress progress,
  ) async {
    return await _gemini.generateDailySession(date, progress);
  }

  // ─── Weekly Challenge ─────────────────────────────────────────

  /// Generates a comprehensive weekly challenge.
  Future<ExerciseSession> getWeeklyChallenge(
    int weekNumber,
    UserProgress progress,
  ) async {
    return await _gemini.generateExerciseSession(
      SessionType.weeklyChallenge,
      progress.currentLevel,
      progress,
      focusTopic: 'Weekly Challenge #$weekNumber',
      questionCount: 20,
    );
  }

  // ─── IELTS Section ────────────────────────────────────────────

  /// Generates an IELTS examination section.
  Future<ExerciseSession> getIELTSSection(
    IELTSSectionType sectionType,
    UserProgress progress,
  ) async {
    return await _gemini.generateIELTSSection(sectionType, progress);
  }

  // ─── Content Uniqueness ─────────────────────────────────────

  /// Validates that newly generated content doesn't overlap with recent IDs.
  ///
  /// Returns `true` if the content is unique (no overlap), `false` otherwise.
  bool validateContentUniqueness(
    List<String> newContentIds,
    List<String> recentIds,
  ) {
    if (newContentIds.isEmpty || recentIds.isEmpty) return true;
    final recentSet = recentIds.toSet();
    return newContentIds.every((id) => !recentSet.contains(id));
  }

  // ─── Content Tracking ─────────────────────────────────────────

  /// Records that a piece of content was consumed by the user.
  UserProgress logContent(
    UserProgress progress, {
    required String contentId,
    required String topic,
    required String contentType,
  }) {
    return _progressService.recordContentSeen(
      progress,
      contentId: contentId,
      topic: topic,
      contentType: contentType,
    );
  }

  // ─── Suggestions ──────────────────────────────────────────────

  /// Gets AI-powered daily suggestions.
  Future<DailySuggestion> getDailySuggestion(UserProgress progress) async {
    return await _gemini.generateDailySuggestion(progress);
  }

  /// Gets AI-generated motivational text.
  Future<String> getMotivation(UserProgress progress) async {
    return await _gemini.generateMotivation(progress);
  }
}
