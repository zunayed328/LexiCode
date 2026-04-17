import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/suggestion_model.dart';
import '../models/exam_result_model.dart';
import '../services/gemini_learning_service.dart';
import '../services/progress_tracking_service.dart';

/// Manages user progress analytics, weakness analysis, and roadmap state.
class ProgressProvider extends ChangeNotifier {
  final GeminiLearningService _geminiService = GeminiLearningService();
  final ProgressTrackingService _progressService = ProgressTrackingService();

  // ─── State ────────────────────────────────────────────────────

  UserProgress? _userProgress;
  UserProgress get userProgress =>
      _userProgress ??
      _progressService.createDefaultProgress('default_user');

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WeaknessAnalysis? _weaknessAnalysis;
  WeaknessAnalysis? get weaknessAnalysis => _weaknessAnalysis;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  LearningRoadmap? _roadmap;
  LearningRoadmap? get roadmap => _roadmap;

  bool _isGeneratingRoadmap = false;
  bool get isGeneratingRoadmap => _isGeneratingRoadmap;

  List<ExamResult> _examHistory = [];
  List<ExamResult> get examHistory => _examHistory;

  String? _error;
  String? get error => _error;

  // ─── Initialization ───────────────────────────────────────────

  /// Loads saved progress from storage.
  Future<void> loadProgress({String userId = 'default_user'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final saved = await _progressService.loadProgress(userId);
      _userProgress =
          saved ?? _progressService.createDefaultProgress(userId);

      // Check & reset daily goals if new day
      _userProgress = _progressService.checkDailyGoals(userProgress);

      _error = null;
    } catch (e) {
      _error = 'Failed to load progress: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clears in-memory data on logout to prevent ghost data.
  void clearUserData() {
    _userProgress = null;
    _weaknessAnalysis = null;
    _roadmap = null;
    _examHistory = [];
    notifyListeners();
  }

  // ─── Progress Updates ─────────────────────────────────────────

  /// Updates progress after an exercise/session completion.
  Future<void> updateProgress({
    required int xpEarned,
    required String skill,
    required double score,
    int exercisesCompleted = 1,
    int vocabularyLearned = 0,
  }) async {
    _userProgress = _progressService.addXp(userProgress, xpEarned);
    _userProgress = _progressService.updateSkillScore(
        userProgress, skill, score);
    _userProgress = _progressService.updateStreak(userProgress);
    _userProgress = userProgress.copyWith(
      totalExercisesCompleted:
          userProgress.totalExercisesCompleted + exercisesCompleted,
      vocabularyMastered:
          userProgress.vocabularyMastered + vocabularyLearned,
    );

    await _progressService.saveProgress(userProgress);
    notifyListeners();
  }

  /// Adds XP directly for simple tasks.
  void addXp(int amount) {
    updateProgress(xpEarned: amount, skill: 'general', score: 100.0);
  }

  // ─── Weakness Analysis ────────────────────────────────────────

  /// Runs AI-powered weakness analysis on current progress data.
  Future<void> getWeaknessAnalysis() async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      _weaknessAnalysis =
          await _geminiService.analyzePerformance(userProgress);
    } catch (e) {
      _error = 'Analysis failed: $e';
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  // ─── Roadmap Generation ───────────────────────────────────────

  /// Generates a personalized learning roadmap.
  Future<void> generateRoadmap({
    required String goal,
    required String timeline,
  }) async {
    _isGeneratingRoadmap = true;
    _error = null;
    notifyListeners();

    try {
      _roadmap = await _geminiService.generateRoadmap(
        userProgress,
        goal,
        timeline,
      );
    } catch (e) {
      _error = 'Roadmap generation failed: $e';
    }

    _isGeneratingRoadmap = false;
    notifyListeners();
  }

  // ─── Exam History ─────────────────────────────────────────────

  /// Records an exam result.
  void addExamResult(ExamResult result) {
    _examHistory = [result, ..._examHistory];
    notifyListeners();
  }

  /// Gets the most recent exam result (if any).
  ExamResult? get latestExamResult =>
      _examHistory.isNotEmpty ? _examHistory.first : null;

  /// Gets improvement between the two most recent exams.
  double? get examImprovement {
    if (_examHistory.length < 2) return null;
    return _examHistory[0].overallBand - _examHistory[1].overallBand;
  }

  // ─── Computed Properties ──────────────────────────────────────

  /// Overall progress percentage (0–1) across all skills.
  double get overallProgress => userProgress.overallScore / 100;

  /// Streak info.
  LearningStreak get streak => userProgress.streak;

  /// Daily goal completion status.
  DailyGoal get dailyGoal => userProgress.dailyGoal;

  /// Current CEFR level label.
  String get cefrLabel => userProgress.cefrLevel.label;

  /// Total XP.
  int get totalXp => userProgress.totalXp;
}
