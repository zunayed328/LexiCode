import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/user_progress_model.dart';
import '../services/content_generation_service.dart';
import '../services/progress_tracking_service.dart';

/// Manages the state for the English Learning module's core features.
///
/// This provider handles operations that don't belong strictly to
/// long-term progress (ProgressProvider) or active sessions (PracticeProvider).
class LearningProvider with ChangeNotifier {
  final ContentGenerationService _contentService = ContentGenerationService();
  final ProgressTrackingService _progressService = ProgressTrackingService();

  // ─── State ────────────────────────────────────────────────────

  LearningLevel _currentLevel = LearningLevel.beginner;
  LearningLevel get currentLevel => _currentLevel;

  LearningLesson? _currentLesson;
  LearningLesson? get currentLesson => _currentLesson;

  bool _isLoadingLesson = false;
  bool get isLoadingLesson => _isLoadingLesson;

  String? _lessonError;
  String? get lessonError => _lessonError;

  String _dailyMotivation = 'Welcome to your English learning journey! 🌟';
  String get dailyMotivation => _dailyMotivation;

  bool _isLoadingMotivation = false;
  bool get isLoadingMotivation => _isLoadingMotivation;

  UserProgress? _userProgress;
  UserProgress get userProgress =>
      _userProgress ??
      _progressService.createDefaultProgress('default_user');

  bool _initialized = false;
  bool get initialized => _initialized;

  // ─── Initialization ───────────────────────────────────────────

  /// Initializes the learning module — loads progress from storage.
  Future<void> initialize({String userId = 'default_user'}) async {
    if (_initialized) return;

    final saved = await _progressService.loadProgress(userId);
    _userProgress = saved ?? _progressService.createDefaultProgress(userId);
    _currentLevel = _userProgress!.currentLevel;
    _initialized = true;
    notifyListeners();

    // Load motivational message in background
    loadDailyMotivation();
  }

  // ─── Level Selection ──────────────────────────────────────────

  void selectLevel(LearningLevel level) {
    _currentLevel = level;
    notifyListeners();
  }

  // ─── Lesson Management ────────────────────────────────────────

  /// Loads a lesson for the given topic.
  Future<void> loadLesson(String topic) async {
    _isLoadingLesson = true;
    _lessonError = null;
    notifyListeners();

    try {
      _currentLesson = await _contentService.getLesson(
        topic,
        _currentLevel,
        userProgress,
      );

      // Record content in history
      _userProgress = _contentService.logContent(
        userProgress,
        contentId: _currentLesson!.id,
        topic: topic,
        contentType: 'lesson',
      );

      _isLoadingLesson = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLesson = false;
      _lessonError = 'Failed to load lesson: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Marks a lesson as completed and awards XP.
  Future<void> completeLesson(String lessonId, double score) async {
    _userProgress = _progressService.addXp(
      userProgress,
      _currentLesson?.xpReward ?? 20,
    );
    _userProgress = userProgress.copyWith(
      totalLessonsCompleted: userProgress.totalLessonsCompleted + 1,
    );

    // Update streak
    _userProgress = _progressService.updateStreak(userProgress);

    // Update daily goals
    _userProgress = _progressService.incrementDailyGoal(
      userProgress,
      grammarLessons: 1,
    );

    // Update skill score based on lesson performance
    _userProgress = _progressService.updateSkillScore(
      userProgress,
      'grammar',
      score,
    );

    // Persist
    await _progressService.saveProgress(userProgress);
    notifyListeners();
  }

  // ─── Motivation ───────────────────────────────────────────────

  Future<void> loadDailyMotivation() async {
    _isLoadingMotivation = true;

    try {
      _dailyMotivation =
          await _contentService.getMotivation(userProgress);
    } catch (_) {
      // Keep default message on failure
    }

    _isLoadingMotivation = false;
    notifyListeners();
  }

  // ─── Available Topics ─────────────────────────────────────────

  /// Returns the list of grammar topics available for the current level.
  List<LessonTopic> get availableTopics {
    return LessonTopic.values
        .where((t) => t.level == _currentLevel)
        .toList();
  }

  /// Clean up current lesson state.
  void clearLesson() {
    _currentLesson = null;
    _lessonError = null;
    notifyListeners();
  }

  /// Clears in-memory data on logout to prevent ghost data.
  void clearUserData() {
    _userProgress = null;
    _initialized = false;
    clearLesson();
  }
}
