import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/lesson_model.dart';
import '../../shared/models/code_review_model.dart';
import '../../shared/models/activity_entry.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/gamification_service.dart';
import '../constants/app_colors.dart';
import '../../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final FirestoreService _firestoreService = FirestoreService();
  final GamificationService _gamificationService = GamificationService();

  /// XP awarded per AI Mentor conversation.
  static const int xpPerMentorChat = 10;

  // Theme
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // User — starts with empty defaults, populated by loadUserFromAuth()
  UserModel _user = UserModel(id: '', name: 'Developer', email: '');
  UserModel get user => _user;
  bool _userLoadedFromFirestore = false;

  // Navigation
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Code Review
  bool _isReviewing = false;
  bool get isReviewing => _isReviewing;
  CodeReviewResult? _lastReviewResult;
  CodeReviewResult? get lastReviewResult => _lastReviewResult;
  String _selectedLanguage = 'Dart';
  String get selectedLanguage => _selectedLanguage;
  final List<CodeReviewResult> _reviewHistory = [];
  List<CodeReviewResult> get reviewHistory => _reviewHistory;

  // Language Learning
  final int _currentLessonIndex = 0;
  int get currentLessonIndex => _currentLessonIndex;
  int _todayXp = 0;
  int get todayXp => _todayXp;

  // Usage Timer
  final Stopwatch _usageTimer = Stopwatch()..start();

  /// Total time spent including the current session.
  int get totalTimeSpentMinutes =>
      _user.totalTimeSpentMinutes + _usageTimer.elapsed.inMinutes;

  /// Formatted total time (e.g. "42h 15m").
  String get formattedTotalTime {
    final total = totalTimeSpentMinutes;
    final hours = total ~/ 60;
    final mins = total % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  // Daily goal
  double get dailyProgress => _gamificationService.getDailyProgress(_todayXp);

  // Lessons data
  List<LessonUnitModel> get lessonUnits => _buildLessonUnits();

  // Achievements
  List<Achievement> get achievements => GamificationService.allAchievements;
  List<Achievement> get unlockedAchievements =>
      _gamificationService.getUnlockedAchievements(_user);

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  /// Updates the local user's display name.
  void updateUserName(String name) {
    _user = _user.copyWith(name: name);
    notifyListeners();
  }

  /// Updates the local user's avatar URL/path.
  void updateUserAvatar(String avatarUrl) {
    _user = _user.copyWith(avatarUrl: avatarUrl);
    notifyListeners();
  }

  /// Loads user data from auth/Firestore into the local UserModel.
  ///
  /// Call this after successful authentication. Reads the merged
  /// auth + Firestore data map and builds a live [UserModel].
  /// The dashboard will reactively update via [notifyListeners].
  ///
  /// Only loads once per session to prevent the auth listener from
  /// overwriting locally-earned XP with stale Firestore data.
  void loadUserFromAuth(Map<String, dynamic>? authUserData) {
    if (authUserData == null) return;
    if (_userLoadedFromFirestore)
      return; // Already loaded — local model is source of truth

    final uid = authUserData['uid'] as String? ?? '';
    final name = authUserData['name'] as String? ?? 'Developer';
    final email = authUserData['email'] as String? ?? '';

    _user = UserModel(
      id: uid,
      name: name,
      email: email,
      avatarUrl: authUserData['photoURL'] as String? ?? '',
      xp: (authUserData['xp'] as num?)?.toInt() ?? 0,
      level: (authUserData['level'] as num?)?.toInt() ?? 1,
      streak: (authUserData['streak'] as num?)?.toInt() ?? 0,
      lessonsCompleted:
          (authUserData['lessonsCompleted'] as num?)?.toInt() ?? 0,
      codeReviewsCompleted:
          (authUserData['codeReviewsCompleted'] as num?)?.toInt() ?? 0,
      proficiencyLevel: authUserData['proficiencyLevel'] as String? ?? 'A1',
      badges: List<String>.from(authUserData['badges'] ?? []),
    );

    _userLoadedFromFirestore = true;
    notifyListeners();
  }

  Future<CodeReviewResult> reviewCode(String code) async {
    _isReviewing = true;
    notifyListeners();

    try {
      final result = await _aiService.analyzeCode(code, _selectedLanguage);
      _lastReviewResult = result;
      _reviewHistory.insert(0, result);
      _user = _gamificationService.addXp(
        _user,
        GamificationService.xpPerCodeReview,
      );
      _user = _user.copyWith(
        codeReviewsCompleted: _user.codeReviewsCompleted + 1,
      );
      _todayXp += GamificationService.xpPerCodeReview;

      // Log activity
      _logActivity(
        type: ActivityType.codeReview,
        title: '$_selectedLanguage Code Review',
        detail: 'Score: ${result.overallScore}/100',
        xp: GamificationService.xpPerCodeReview,
      );

      _isReviewing = false;
      notifyListeners();

      // Sync progress to backend (non-blocking, safe if Firebase not configured)
      try {
        ApiService.saveProgress(codeReviewCompleted: true, updateStreak: true);
      } catch (_) {}

      return result;
    } catch (e) {
      _isReviewing = false;
      notifyListeners();
      rethrow;
    }
  }

  void completeLesson(String lessonId) {
    _user = _gamificationService.addXp(_user, GamificationService.xpPerLesson);
    _user = _user.copyWith(lessonsCompleted: _user.lessonsCompleted + 1);
    _todayXp += GamificationService.xpPerLesson;

    // Log activity
    _logActivity(
      type: ActivityType.lesson,
      title: 'Lesson Completed',
      detail: '+${GamificationService.xpPerLesson} XP',
      xp: GamificationService.xpPerLesson,
    );

    notifyListeners();

    // Sync progress to backend (non-blocking, safe if Firebase not configured)
    try {
      ApiService.saveProgress(
        lessonId: lessonId,
        result: {'xpEarned': GamificationService.xpPerLesson, 'score': 100},
        updateStreak: true,
      );
    } catch (_) {}
  }

  void addXpForPractice() {
    _user = _gamificationService.addXp(
      _user,
      GamificationService.xpPerPractice,
    );
    _todayXp += GamificationService.xpPerPractice;

    // Log activity
    _logActivity(
      type: ActivityType.practice,
      title: 'Practice Session',
      detail: '+${GamificationService.xpPerPractice} XP',
      xp: GamificationService.xpPerPractice,
    );

    notifyListeners();
  }

  Future<String> chatWithMentor(String message) async {
    return await _aiService.chatWithMentor(message, 'general');
  }

  /// Awards XP after a mentor chat session and persists to Firestore.
  void addMentorChatXp() {
    // 1. Update locally for instant UI response
    _user = _gamificationService.addXp(_user, xpPerMentorChat);
    _todayXp += xpPerMentorChat;

    // Log activity
    _logActivity(
      type: ActivityType.mentorChat,
      title: 'AI Mentor Chat',
      detail: '+$xpPerMentorChat XP',
      xp: xpPerMentorChat,
    );

    notifyListeners();

    // 2. Persist to Firestore and sync back confirmed values
    _firestoreService.updateXp(_user.id, xpPerMentorChat).then((result) {
      if (result != null) {
        final confirmedXp = (result['xp'] as num?)?.toInt() ?? _user.xp;
        final confirmedLevel =
            (result['level'] as num?)?.toInt() ?? _user.level;
        if (confirmedXp != _user.xp || confirmedLevel != _user.level) {
          _user = _user.copyWith(xp: confirmedXp, level: confirmedLevel);
          notifyListeners();
        }
      }
    });
    _firestoreService.updateStreak(_user.id);
  }

  // ─── Activity Logging ──────────────────────────────────────────

  /// Logs a user activity and caps the log at 50 entries.
  void _logActivity({
    required ActivityType type,
    required String title,
    String? detail,
    int xp = 0,
  }) {
    final entry = ActivityEntry(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: type,
      title: title,
      detail: detail,
      xpEarned: xp,
    );

    final updatedLog = [entry, ..._user.activityLog];
    // Cap at 50 entries to prevent unbounded growth
    _user = _user.copyWith(
      activityLog: updatedLog.length > 50
          ? updatedLog.sublist(0, 50)
          : updatedLog,
    );
  }

  /// Returns 7 data points for the weekly activity chart.
  List<double> get weeklyActivityData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _user.activityLog
          .where((a) {
            return a.timestamp.year == day.year &&
                a.timestamp.month == day.month &&
                a.timestamp.day == day.day;
          })
          .length
          .toDouble();
    });
  }

  // ─── Usage Timer Lifecycle ─────────────────────────────────────

  /// Pauses the usage timer (call on app inactive/paused).
  void pauseTimer() => _usageTimer.stop();

  /// Resumes the usage timer (call on app resumed).
  void resumeTimer() => _usageTimer.start();

  /// Persists the accumulated timer value into the user model.
  void saveTimeSpent() {
    final sessionMinutes = _usageTimer.elapsed.inMinutes;
    if (sessionMinutes > 0) {
      _user = _user.copyWith(
        totalTimeSpentMinutes: _user.totalTimeSpentMinutes + sessionMinutes,
      );
      _usageTimer.reset();
      _usageTimer.start();
    }
  }

  List<LessonUnitModel> _buildLessonUnits() {
    return [
      LessonUnitModel(
        id: 'unit_1',
        title: 'Tech Basics',
        description: 'Essential programming vocabulary',
        icon: Icons.rocket_launch_rounded,
        color: AppColors.accentGreen,
        unitNumber: 1,
        lessons: [
          LessonModel(
            id: 'l1_1',
            title: 'Variables & Types',
            description: 'Learn English terms for data types and variables',
            category: LessonCategory.techVocabulary,
            difficulty: LessonDifficulty.beginner,
            icon: Icons.data_object_rounded,
            color: AppColors.accentGreen,
            xpReward: 15,
            totalQuestions: 5,
            completedQuestions: 5,
            isCompleted: true,
            questions: _buildVocabularyQuestions(),
          ),
          LessonModel(
            id: 'l1_2',
            title: 'Functions & Methods',
            description: 'Describe what functions do in English',
            category: LessonCategory.techVocabulary,
            difficulty: LessonDifficulty.beginner,
            icon: Icons.functions_rounded,
            color: AppColors.accentGreen,
            xpReward: 15,
            totalQuestions: 5,
            completedQuestions: 5,
            isCompleted: true,
            questions: _buildVocabularyQuestions(),
          ),
          LessonModel(
            id: 'l1_3',
            title: 'Error Messages',
            description: 'Understand common error descriptions',
            category: LessonCategory.techVocabulary,
            difficulty: LessonDifficulty.beginner,
            icon: Icons.error_outline_rounded,
            color: AppColors.accentGreen,
            xpReward: 15,
            totalQuestions: 5,
            completedQuestions: 3,
            questions: _buildVocabularyQuestions(),
          ),
        ],
      ),
      LessonUnitModel(
        id: 'unit_2',
        title: 'Code Comments',
        description: 'Write clear code documentation',
        icon: Icons.comment_rounded,
        color: AppColors.info,
        unitNumber: 2,
        lessons: [
          LessonModel(
            id: 'l2_1',
            title: 'Inline Comments',
            description: 'Write helpful inline comments',
            category: LessonCategory.codeComments,
            difficulty: LessonDifficulty.elementary,
            icon: Icons.short_text_rounded,
            color: AppColors.info,
            xpReward: 20,
            totalQuestions: 5,
            questions: _buildCommentQuestions(),
          ),
          LessonModel(
            id: 'l2_2',
            title: 'Doc Comments',
            description: 'Master documentation comment style',
            category: LessonCategory.codeComments,
            difficulty: LessonDifficulty.elementary,
            icon: Icons.article_rounded,
            color: AppColors.info,
            xpReward: 20,
            totalQuestions: 5,
            isLocked: true,
            questions: _buildCommentQuestions(),
          ),
        ],
      ),
      LessonUnitModel(
        id: 'unit_3',
        title: 'PR Descriptions',
        description: 'Craft professional pull requests',
        icon: Icons.merge_type_rounded,
        color: AppColors.primary,
        unitNumber: 3,
        lessons: [
          LessonModel(
            id: 'l3_1',
            title: 'PR Title Writing',
            description: 'Create clear, descriptive PR titles',
            category: LessonCategory.prWriting,
            difficulty: LessonDifficulty.intermediate,
            icon: Icons.title_rounded,
            color: AppColors.primary,
            xpReward: 25,
            totalQuestions: 5,
            isLocked: true,
            questions: _buildPRQuestions(),
          ),
          LessonModel(
            id: 'l3_2',
            title: 'Describing Changes',
            description: 'Explain what your code changes do',
            category: LessonCategory.prWriting,
            difficulty: LessonDifficulty.intermediate,
            icon: Icons.description_rounded,
            color: AppColors.primary,
            xpReward: 25,
            totalQuestions: 5,
            isLocked: true,
            questions: _buildPRQuestions(),
          ),
        ],
      ),
      LessonUnitModel(
        id: 'unit_4',
        title: 'Email Writing',
        description: 'Professional tech communication',
        icon: Icons.email_rounded,
        color: AppColors.secondary,
        unitNumber: 4,
        lessons: [
          LessonModel(
            id: 'l4_1',
            title: 'Bug Reports',
            description: 'Write clear bug report emails',
            category: LessonCategory.emailWriting,
            difficulty: LessonDifficulty.intermediate,
            icon: Icons.bug_report_rounded,
            color: AppColors.secondary,
            xpReward: 25,
            totalQuestions: 5,
            isLocked: true,
            questions: _buildEmailQuestions(),
          ),
        ],
      ),
      LessonUnitModel(
        id: 'unit_5',
        title: 'Standup & Meetings',
        description: 'Speak confidently in team meetings',
        icon: Icons.groups_rounded,
        color: AppColors.accentOrange,
        unitNumber: 5,
        lessons: [
          LessonModel(
            id: 'l5_1',
            title: 'Daily Standup',
            description: 'Practice daily standup phrases',
            category: LessonCategory.meetingConversation,
            difficulty: LessonDifficulty.upperIntermediate,
            icon: Icons.record_voice_over_rounded,
            color: AppColors.accentOrange,
            xpReward: 30,
            totalQuestions: 5,
            isLocked: true,
            questions: _buildMeetingQuestions(),
          ),
        ],
      ),
    ];
  }

  List<QuestionModel> _buildVocabularyQuestions() {
    return [
      QuestionModel(
        id: 'q1',
        question: 'What does "deprecated" mean in programming?',
        type: QuestionType.multipleChoice,
        options: [
          'No longer recommended for use',
          'Very popular and widely used',
          'Recently created',
          'Runs very fast',
        ],
        correctAnswer: 'No longer recommended for use',
        explanation:
            '"Deprecated" means a feature is outdated and developers are discouraged from using it. It may be removed in future versions.',
      ),
      QuestionModel(
        id: 'q2',
        question:
            'Fill in the blank: We need to _____ this function to improve performance.',
        type: QuestionType.fillBlank,
        options: ['optimize', 'delete', 'ignore', 'copy'],
        correctAnswer: 'optimize',
        explanation:
            '"Optimize" means to make something work as efficiently as possible.',
      ),
      QuestionModel(
        id: 'q3',
        question:
            'Which word means "to restructure code without changing its behavior"?',
        type: QuestionType.multipleChoice,
        options: ['Refactor', 'Debug', 'Deploy', 'Compile'],
        correctAnswer: 'Refactor',
        explanation:
            '"Refactor" means reorganizing code to improve its internal structure while keeping the same external behavior.',
      ),
      QuestionModel(
        id: 'q4',
        question: 'What is a "bug" in programming?',
        type: QuestionType.multipleChoice,
        options: [
          'An error or flaw in the code',
          'A type of programming language',
          'A fast algorithm',
          'A testing framework',
        ],
        correctAnswer: 'An error or flaw in the code',
        explanation:
            'A "bug" is an error, flaw, or fault in a computer program that causes it to produce incorrect or unexpected results.',
      ),
      QuestionModel(
        id: 'q5',
        question:
            'Fill in: The API returns a _____ when the request is successful.',
        type: QuestionType.fillBlank,
        options: ['response', 'error', 'crash', 'warning'],
        correctAnswer: 'response',
        explanation:
            'An API "response" is the data sent back by the server after processing a request.',
      ),
    ];
  }

  List<QuestionModel> _buildCommentQuestions() {
    return [
      QuestionModel(
        id: 'cq1',
        question:
            'Which is the best inline comment for this code?\n\nif (retryCount > 3) { return; }',
        type: QuestionType.multipleChoice,
        options: [
          '// Exit early if max retries exceeded',
          '// Check number',
          '// if statement',
          '// Return here',
        ],
        correctAnswer: '// Exit early if max retries exceeded',
        explanation:
            'Good comments explain WHY, not just WHAT. "Exit early if max retries exceeded" explains the purpose.',
        codeSnippet: 'if (retryCount > 3) {\n  return;\n}',
      ),
      QuestionModel(
        id: 'cq2',
        question:
            'Complete the doc comment: /// _____ the user\'s shopping cart total.',
        type: QuestionType.fillBlank,
        options: ['Calculates', 'Does', 'Makes', 'Runs'],
        correctAnswer: 'Calculates',
        explanation:
            'Doc comments should start with a verb in third person: "Calculates", "Returns", "Validates", etc.',
      ),
      QuestionModel(
        id: 'cq3',
        question: 'Which comment style is recommended for Dart documentation?',
        type: QuestionType.multipleChoice,
        options: [
          '/// Triple slash comments',
          '/* Block comments */',
          '// Double slash comments',
          '# Hash comments',
        ],
        correctAnswer: '/// Triple slash comments',
        explanation:
            'In Dart, /// (triple slash) is used for documentation comments that can be processed by dartdoc.',
      ),
      QuestionModel(
        id: 'cq4',
        question:
            'What is wrong with this comment?\n\n// Increment i by 1\ni++;',
        type: QuestionType.multipleChoice,
        options: [
          'It states the obvious — explains WHAT not WHY',
          'Wrong punctuation',
          'Too short',
          'Nothing is wrong',
        ],
        correctAnswer: 'It states the obvious — explains WHAT not WHY',
        explanation:
            'Comments should explain WHY something is done, not repeat WHAT the code obviously does.',
        codeSnippet: '// Increment i by 1\ni++;',
      ),
      QuestionModel(
        id: 'cq5',
        question: 'Fill in: /// Throws a [___Exception] if the input is null.',
        type: QuestionType.fillBlank,
        options: ['ArgumentError', 'Null', 'TypeError', 'FormatException'],
        correctAnswer: 'ArgumentError',
        explanation:
            'ArgumentError is typically thrown when a function receives an invalid argument, like null when non-null is expected.',
      ),
    ];
  }

  List<QuestionModel> _buildPRQuestions() {
    return [
      QuestionModel(
        id: 'pq1',
        question: 'Which PR title best follows conventions?',
        type: QuestionType.multipleChoice,
        options: [
          'feat: add user authentication with OAuth2',
          'I added login stuff',
          'Update files',
          'Changes',
        ],
        correctAnswer: 'feat: add user authentication with OAuth2',
        explanation:
            'Using conventional commit prefixes (feat:, fix:, docs:) makes PR titles clear and searchable.',
      ),
      QuestionModel(
        id: 'pq2',
        question:
            'Fill in the PR description: This PR _____ the login endpoint to support OAuth2.',
        type: QuestionType.fillBlank,
        options: ['refactors', 'destroys', 'removes', 'ignores'],
        correctAnswer: 'refactors',
        explanation:
            '"Refactors" means restructuring existing code. PR descriptions should use precise technical verbs.',
      ),
      QuestionModel(
        id: 'pq3',
        question: 'What section should every PR description include?',
        type: QuestionType.multipleChoice,
        options: [
          'What changed, why, and how to test',
          'Only the ticket number',
          'A joke to make reviewers smile',
          'Personal opinions about the code',
        ],
        correctAnswer: 'What changed, why, and how to test',
        explanation:
            'Good PRs explain what was changed, the motivation, and verification steps.',
      ),
      QuestionModel(
        id: 'pq4',
        question: 'Which phrase is most professional for a PR?',
        type: QuestionType.multipleChoice,
        options: [
          'This addresses the performance regression in the API layer',
          'I fixed the slow thing',
          'Made it faster',
          'IDK but it works now',
        ],
        correctAnswer:
            'This addresses the performance regression in the API layer',
        explanation:
            'Professional PRs use specific, technical language and explain the scope of changes.',
      ),
      QuestionModel(
        id: 'pq5',
        question:
            'Fill in: Breaking change: _____ the deprecated v1 endpoints.',
        type: QuestionType.fillBlank,
        options: ['Removes', 'Adds', 'Copies', 'Moves'],
        correctAnswer: 'Removes',
        explanation:
            'When documenting breaking changes, clearly state what was removed or changed.',
      ),
    ];
  }

  List<QuestionModel> _buildEmailQuestions() {
    return [
      QuestionModel(
        id: 'eq1',
        question: 'Which subject line is best for a bug report email?',
        type: QuestionType.multipleChoice,
        options: [
          '[Bug] Login fails with 500 error on mobile (v2.3.1)',
          'Help! Something is broken',
          'Bug',
          'Please fix this ASAP!!!',
        ],
        correctAnswer: '[Bug] Login fails with 500 error on mobile (v2.3.1)',
        explanation:
            'Good bug report subjects include: category tag, specific description, and version number.',
      ),
      QuestionModel(
        id: 'eq2',
        question:
            'Fill in: I was able to _____ the issue on both Android and iOS devices.',
        type: QuestionType.fillBlank,
        options: ['reproduce', 'create', 'make', 'build'],
        correctAnswer: 'reproduce',
        explanation:
            '"Reproduce" means to recreate the conditions that cause the bug to appear.',
      ),
      QuestionModel(
        id: 'eq3',
        question:
            'What should you include in the "Steps to Reproduce" section?',
        type: QuestionType.multipleChoice,
        options: [
          'Numbered, specific steps to trigger the bug',
          'A vague description of the problem',
          'Your opinion about the cause',
          'Code snippets from the entire codebase',
        ],
        correctAnswer: 'Numbered, specific steps to trigger the bug',
        explanation:
            'Clear, numbered steps help developers quickly understand and reproduce the issue.',
      ),
      QuestionModel(
        id: 'eq4',
        question:
            'Which phrase is most appropriate in a professional bug report?',
        type: QuestionType.multipleChoice,
        options: [
          'Expected behavior vs Actual behavior',
          'This should work but it doesn\'t',
          'Somebody broke the code',
          'Not my fault but...',
        ],
        correctAnswer: 'Expected behavior vs Actual behavior',
        explanation:
            'Using "Expected vs Actual" format clearly communicates the discrepancy.',
      ),
      QuestionModel(
        id: 'eq5',
        question: 'Fill in: Attached are the _____ from the crash report.',
        type: QuestionType.fillBlank,
        options: ['logs', 'pictures', 'feelings', 'opinions'],
        correctAnswer: 'logs',
        explanation:
            '"Logs" are recorded system events that help diagnose technical issues.',
      ),
    ];
  }

  List<QuestionModel> _buildMeetingQuestions() {
    return [
      QuestionModel(
        id: 'mq1',
        question: 'Which standup update is most professional?',
        type: QuestionType.multipleChoice,
        options: [
          'Yesterday I completed the API integration. Today I\'ll work on unit tests. No blockers.',
          'I did some stuff and will do more stuff.',
          'Nothing to report.',
          'I was busy all day.',
        ],
        correctAnswer:
            'Yesterday I completed the API integration. Today I\'ll work on unit tests. No blockers.',
        explanation:
            'Standups follow the format: What I did, What I\'ll do, Any blockers.',
      ),
      QuestionModel(
        id: 'mq2',
        question:
            'Fill in: I\'m currently _____ by a dependency conflict in the build pipeline.',
        type: QuestionType.fillBlank,
        options: ['blocked', 'stopped', 'hurt', 'broken'],
        correctAnswer: 'blocked',
        explanation:
            '"Blocked" is the standard term for being unable to progress due to an external issue.',
      ),
      QuestionModel(
        id: 'mq3',
        question: 'How should you ask for help in a standup?',
        type: QuestionType.multipleChoice,
        options: [
          'I could use some help reviewing the authentication module. Could someone pair with me after standup?',
          'Someone help me I don\'t know what I\'m doing',
          'This code is impossible',
          'I need help but I\'ll figure it out maybe',
        ],
        correctAnswer:
            'I could use some help reviewing the authentication module. Could someone pair with me after standup?',
        explanation:
            'Be specific about what you need help with and suggest a follow-up time.',
      ),
      QuestionModel(
        id: 'mq4',
        question: 'What does "pair programming" mean?',
        type: QuestionType.multipleChoice,
        options: [
          'Two developers working together on the same code',
          'Writing code for two projects at once',
          'Using two monitors',
          'Coding in two programming languages',
        ],
        correctAnswer: 'Two developers working together on the same code',
        explanation:
            '"Pair programming" is a practice where two developers collaborate: one writes code (driver) and one reviews in real-time (navigator).',
      ),
      QuestionModel(
        id: 'mq5',
        question:
            'Fill in: I need to _____ with the backend team about the API contract.',
        type: QuestionType.fillBlank,
        options: ['sync up', 'fight', 'argue', 'compete'],
        correctAnswer: 'sync up',
        explanation:
            '"Sync up" means to meet and align on shared work or information.',
      ),
    ];
  }
}
