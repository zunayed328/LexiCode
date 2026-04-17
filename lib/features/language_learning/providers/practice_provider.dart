import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/exercise_model.dart';
import '../models/suggestion_model.dart';
import '../services/content_generation_service.dart';
import '../services/speech_service.dart';

/// Manages active practice session state.
///
/// Handles exercise flow, answer submission, scoring, TTS/STT controls,
/// and daily suggestions.
class PracticeProvider extends ChangeNotifier {
  final ContentGenerationService _contentService = ContentGenerationService();
  final SpeechService _speechService = SpeechService();

  // ─── Session State ────────────────────────────────────────────

  ExerciseSession? _currentSession;
  ExerciseSession? get currentSession => _currentSession;

  int _currentExerciseIndex = 0;
  int get currentExerciseIndex => _currentExerciseIndex;

  final List<ExerciseResult> _answers = [];
  List<ExerciseResult> get answers => List.unmodifiable(_answers);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  int _streakCount = 0; // Consecutive correct answers
  int get streakCount => _streakCount;

  // ─── Daily Suggestion ─────────────────────────────────────────

  DailySuggestion? _dailySuggestion;
  DailySuggestion? get dailySuggestion => _dailySuggestion;

  bool _isLoadingSuggestion = false;
  bool get isLoadingSuggestion => _isLoadingSuggestion;

  // ─── Computed Properties ──────────────────────────────────────

  Exercise? get currentExercise {
    if (_currentSession == null) return null;
    if (_currentExerciseIndex >= _currentSession!.exercises.length) {
      return null;
    }
    return _currentSession!.exercises[_currentExerciseIndex];
  }

  bool get sessionComplete {
    if (_currentSession == null) return false;
    return _answers.length >= _currentSession!.exercises.length;
  }

  int get sessionScore =>
      _answers.fold<int>(0, (sum, r) => sum + r.scoreEarned);

  int get correctCount => _answers.where((r) => r.isCorrect).length;

  double get accuracy {
    if (_answers.isEmpty) return 0;
    return correctCount / _answers.length;
  }

  double get progress {
    if (_currentSession == null || _currentSession!.exercises.isEmpty) {
      return 0;
    }
    return _answers.length / _currentSession!.exercises.length;
  }

  int get totalExercises => _currentSession?.exercises.length ?? 0;

  // ─── Session Lifecycle ────────────────────────────────────────

  /// Starts a new practice session.
  Future<void> startSession(
    SessionType type,
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
    int questionCount = 12,
  }) async {
    _isLoading = true;
    _error = null;
    _answers.clear();
    _currentExerciseIndex = 0;
    _streakCount = 0;
    notifyListeners();

    try {
      if (type == SessionType.dailyPractice) {
        _currentSession = await _contentService.getDailyPractice(
          DateTime.now(),
          progress,
        );
      } else {
        _currentSession = await _contentService.getExercises(
          type,
          level,
          progress,
          focusTopic: focusTopic,
          questionCount: questionCount,
        );
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to start session: $e';
      _currentSession = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submits an answer for the current exercise.
  void submitAnswer(String answer) {
    if (currentExercise == null || _isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    final exercise = currentExercise!;
    final isCorrect = _checkAnswer(answer, exercise);

    final result = ExerciseResult(
      exerciseId: exercise.id,
      userAnswer: answer,
      isCorrect: isCorrect,
      scoreEarned: isCorrect ? exercise.points : 0,
      feedback: isCorrect
          ? 'Correct! ${exercise.explanation}'
          : 'The correct answer is: ${exercise.correctAnswer}. ${exercise.explanation}',
    );

    _answers.add(result);

    // Update streak
    if (isCorrect) {
      _streakCount++;
    } else {
      _streakCount = 0;
    }

    _isSubmitting = false;
    notifyListeners();
  }

  /// Moves to the next exercise in the session.
  void nextExercise() {
    if (_currentSession == null) return;
    if (_currentExerciseIndex < _currentSession!.exercises.length - 1) {
      _currentExerciseIndex++;
      notifyListeners();
    }
  }

  /// Finishes the session and returns the final score.
  int finishSession() {
    final score = sessionScore;
    notifyListeners();
    return score;
  }

  /// Resets the session state.
  void resetSession() {
    _currentSession = null;
    _currentExerciseIndex = 0;
    _answers.clear();
    _streakCount = 0;
    _error = null;
    notifyListeners();
  }

  // ─── Answer Checking ─────────────────────────────────────────

  bool _checkAnswer(String userAnswer, Exercise exercise) {
    final normalized = userAnswer.trim().toLowerCase();
    final correct = exercise.correctAnswer.trim().toLowerCase();

    if (normalized == correct) return true;

    // Check alternate answers
    if (exercise.alternateCorrectAnswers != null) {
      for (final alt in exercise.alternateCorrectAnswers!) {
        if (normalized == alt.trim().toLowerCase()) return true;
      }
    }

    return false;
  }

  // ─── TTS Controls ────────────────────────────────────────────

  /// Speaks the given text using TTS.
  Future<void> speakText(String text, {double? speed}) async {
    await _speechService.speak(text, speed: speed);
  }

  /// Stops TTS playback.
  Future<void> stopSpeaking() async {
    await _speechService.stopSpeaking();
  }

  /// Sets TTS speed.
  Future<void> setSpeechSpeed(double speed) async {
    await _speechService.setSpeed(speed);
  }

  // ─── STT Controls ────────────────────────────────────────────

  bool _isSttListening = false;
  bool get isSttListening => _isSttListening;

  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  /// Starts speech-to-text listening.
  Future<void> startListening() async {
    _recognizedText = '';
    await _speechService.startListening(
      onResult: (text) {
        _recognizedText = text;
        notifyListeners();
      },
      onListeningStateChanged: (listening) {
        _isSttListening = listening;
        notifyListeners();
      },
    );
  }

  /// Stops speech-to-text listening.
  Future<void> stopListening() async {
    await _speechService.stopListening();
    _isSttListening = false;
    notifyListeners();
  }

  // ─── Daily Suggestion ─────────────────────────────────────────

  /// Loads AI-generated daily suggestion.
  Future<void> loadDailySuggestion(UserProgress progress) async {
    _isLoadingSuggestion = true;
    notifyListeners();

    try {
      _dailySuggestion = await _contentService.getDailySuggestion(progress);
    } catch (_) {
      // Silently fail — suggestion is optional
    }

    _isLoadingSuggestion = false;
    notifyListeners();
  }

  // ─── Cleanup ──────────────────────────────────────────────────

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
