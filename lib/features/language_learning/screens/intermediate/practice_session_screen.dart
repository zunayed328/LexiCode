import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/exercise_model.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/answer_feedback.dart';
import '../../widgets/progress_header.dart';
import '../../widgets/score_reveal.dart';

/// Unified exercise session screen for all practice types.
///
/// Loads exercises, renders them one-by-one, tracks answers, and shows results.
class PracticeSessionScreen extends StatefulWidget {
  final SessionType sessionType;
  final String title;
  final int? questionCount;
  final List<Exercise>? exercises;

  const PracticeSessionScreen({
    super.key,
    required this.sessionType,
    required this.title,
    this.questionCount,
    this.exercises,
  });

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  bool _isLoading = true;
  bool _showFeedback = false;
  bool _sessionComplete = false;
  int _currentIndex = 0;
  int _correctStreak = 0;
  final List<_SessionAnswer> _answers = [];
  late List<Exercise> _exercises;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    if (widget.exercises != null && widget.exercises!.isNotEmpty) {
      setState(() {
        _exercises = widget.exercises!;
        _isLoading = false;
      });
      return;
    }

    // Generate sample exercises if none provided
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _exercises = _generateExercises();
        _isLoading = false;
      });
    });
  }

  List<Exercise> _generateExercises() {
    switch (widget.sessionType) {
      case SessionType.grammarPractice:
        return _grammarExercises();
      case SessionType.spellingPractice:
        return _spellingExercises();
      case SessionType.readingPractice:
        return _readingExercises();
      default:
        return _grammarExercises();
    }
  }

  List<Exercise> _grammarExercises() {
    return [
      Exercise(
        id: 'g1',
        type: ExerciseType.mcq,
        question: 'Which sentence uses the correct form of the verb?',
        options: [
          'She don\'t like coffee.',
          'She doesn\'t like coffee.',
          'She not like coffee.',
          'She isn\'t like coffee.',
        ],
        correctAnswer: 'She doesn\'t like coffee.',
        explanation:
            'With third person singular (she/he/it), we use "doesn\'t" for negation.',
        hint: 'Think about the subject-verb agreement in present tense.',
        points: 10,
        difficulty: ExerciseDifficulty.medium,
      ),
      Exercise(
        id: 'g2',
        type: ExerciseType.fillBlank,
        question: 'If I _____ (know) the answer, I would have told you.',
        correctAnswer: 'had known',
        explanation:
            'This is a third conditional (past unreal). The "if" clause uses past perfect.',
        hint: 'This is about an unreal past situation.',
        points: 15,
        difficulty: ExerciseDifficulty.hard,
      ),
      Exercise(
        id: 'g3',
        type: ExerciseType.errorCorrection,
        question: 'Find and correct the error in this sentence:',
        context:
            'The team have been working on the project since three months.',
        correctAnswer:
            'The team has been working on the project for three months.',
        explanation:
            '"Team" as a collective noun takes "has" in American English. "Since" is for a specific point in time; "for" is for a duration.',
        points: 20,
        difficulty: ExerciseDifficulty.hard,
      ),
      Exercise(
        id: 'g4',
        type: ExerciseType.mcq,
        question:
            'Choose the correct relative pronoun: "The book _____ I borrowed from the library was fascinating."',
        options: ['who', 'which', 'whom', 'whose'],
        correctAnswer: 'which',
        explanation: '"Which" is used for things. "Who" is for people.',
        points: 10,
        difficulty: ExerciseDifficulty.medium,
      ),
      Exercise(
        id: 'g5',
        type: ExerciseType.trueFalse,
        question:
            'True or False: "Neither the students nor the teacher were ready" is grammatically correct.',
        options: ['True', 'False'],
        correctAnswer: 'False',
        explanation:
            'When "neither...nor" is used, the verb agrees with the nearest subject. "Teacher" is singular, so it should be "was ready".',
        points: 10,
        difficulty: ExerciseDifficulty.medium,
      ),
      Exercise(
        id: 'g6',
        type: ExerciseType.fillBlank,
        question:
            'By the time we arrive, they _____ (finish) the presentation.',
        correctAnswer: 'will have finished',
        explanation:
            'Future perfect tense is used for an action that will be completed before another future event.',
        hint:
            'Think about what tense describes completion before a future event.',
        points: 15,
        difficulty: ExerciseDifficulty.hard,
      ),
      Exercise(
        id: 'g7',
        type: ExerciseType.mcq,
        question: 'Which sentence uses the passive voice correctly?',
        options: [
          'The report was written by the intern.',
          'The report written by the intern.',
          'The report is write by the intern.',
          'The report wrote by the intern.',
        ],
        correctAnswer: 'The report was written by the intern.',
        explanation:
            'Passive voice: Subject + be (was) + past participle (written) + by + agent.',
        points: 10,
        difficulty: ExerciseDifficulty.easy,
      ),
      Exercise(
        id: 'g8',
        type: ExerciseType.mcq,
        question:
            'Select the correct modal verb: "You _____ wear a seatbelt. It\'s the law."',
        options: ['should', 'must', 'might', 'could'],
        correctAnswer: 'must',
        explanation:
            '"Must" indicates obligation or requirement. "Should" is advice. "Might" and "could" indicate possibility.',
        points: 10,
        difficulty: ExerciseDifficulty.easy,
      ),
    ];
  }

  List<Exercise> _spellingExercises() {
    return [
      Exercise(
        id: 's1',
        type: ExerciseType.spelling,
        question: 'Spell the word that means "to make something better"',
        correctAnswer: 'improve',
        hint: 'Starts with "im-"',
        points: 10,
        difficulty: ExerciseDifficulty.easy,
      ),
      Exercise(
        id: 's2',
        type: ExerciseType.spelling,
        question: 'Spell the word that means "happening immediately"',
        correctAnswer: 'immediately',
        hint: 'Ends with "-ately"',
        points: 15,
        difficulty: ExerciseDifficulty.medium,
      ),
      Exercise(
        id: 's3',
        type: ExerciseType.spelling,
        question: 'Spell the word for "a formal request for something"',
        correctAnswer: 'application',
        hint: 'Related to "apply"',
        points: 10,
        difficulty: ExerciseDifficulty.medium,
      ),
    ];
  }

  List<Exercise> _readingExercises() {
    return [
      Exercise(
        id: 'r1',
        type: ExerciseType.mcq,
        question:
            'Based on the passage, what was the main cause of the problem?',
        context:
            'The Great Barrier Reef, the world\'s largest coral reef system, has experienced significant bleaching events due to rising ocean temperatures. Scientists warn that without immediate action to reduce carbon emissions, the reef could suffer irreversible damage within decades.',
        options: [
          'Rising ocean temperatures',
          'Overfishing',
          'Pollution from factories',
          'Tourism',
        ],
        correctAnswer: 'Rising ocean temperatures',
        explanation:
            'The passage explicitly states "bleaching events due to rising ocean temperatures."',
        points: 10,
        difficulty: ExerciseDifficulty.medium,
      ),
      Exercise(
        id: 'r2',
        type: ExerciseType.mcq,
        question:
            'What does "irreversible" mean in the context of the passage?',
        context:
            'The Great Barrier Reef, the world\'s largest coral reef system, has experienced significant bleaching events due to rising ocean temperatures. Scientists warn that without immediate action to reduce carbon emissions, the reef could suffer irreversible damage within decades.',
        options: [
          'Cannot be undone',
          'Very expensive',
          'Easy to fix',
          'Not important',
        ],
        correctAnswer: 'Cannot be undone',
        explanation:
            '"Irreversible" means something that cannot be reversed or changed back to its original state.',
        points: 10,
        difficulty: ExerciseDifficulty.easy,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) return _buildLoadingScreen(isDark);
    if (_sessionComplete) return _buildResultsScreen(isDark);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ProgressHeader(
              currentQuestion: _currentIndex + 1,
              totalQuestions: _exercises.length,
              sessionTitle: widget.title,
              accentColor: _getAccentColor(),
              onClose: () => _showExitDialog(context),
            ),
            Expanded(
              child: ExerciseCard(
                exercise: _exercises[_currentIndex],
                questionNumber: _currentIndex + 1,
                totalQuestions: _exercises.length,
                showFeedback: _showFeedback,
                result: _showFeedback && _answers.isNotEmpty
                    ? ExerciseResult(
                        exerciseId: _exercises[_currentIndex].id,
                        userAnswer: _answers.last.userAnswer,
                        isCorrect: _answers.last.isCorrect,
                        scoreEarned: _answers.last.isCorrect
                            ? _exercises[_currentIndex].points
                            : 0,
                        feedback: _exercises[_currentIndex].explanation,
                      )
                    : null,
                onAnswer: (answer) =>
                    _submitAnswer(answer, _exercises[_currentIndex]),
              ),
            ),
            if (_showFeedback)
              AnswerFeedback(
                isCorrect: _answers.last.isCorrect,
                feedback: _exercises[_currentIndex].explanation,
                xpEarned: _answers.last.isCorrect
                    ? _exercises[_currentIndex].points
                    : 0,
                streakCount: _correctStreak,
                onContinue: _nextQuestion,
              ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.sessionType) {
      case SessionType.grammarPractice:
        return const Color(0xFF3B82F6);
      case SessionType.pronunciationPractice:
        return const Color(0xFFF59E0B);
      case SessionType.spellingPractice:
        return const Color(0xFF8B5CF6);
      case SessionType.readingPractice:
        return const Color(0xFF10B981);
      case SessionType.writingPractice:
        return const Color(0xFFEC4899);
      default:
        return AppColors.primary;
    }
  }

  void _submitAnswer(String answer, Exercise exercise) {
    final isCorrect =
        answer.trim().toLowerCase() ==
        exercise.correctAnswer.trim().toLowerCase();

    setState(() {
      _answers.add(
        _SessionAnswer(
          userAnswer: answer,
          isCorrect: isCorrect,
          exerciseId: exercise.id,
          pointsEarned: isCorrect ? exercise.points : 0,
        ),
      );
      _showFeedback = true;
      if (isCorrect) {
        _correctStreak++;
      } else {
        _correctStreak = 0;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _showFeedback = false;
      });
    } else {
      setState(() => _sessionComplete = true);
    }
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getAccentColor(),
                    _getAccentColor().withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preparing your session...',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(_getAccentColor()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(bool isDark) {
    final correct = _answers.where((a) => a.isCorrect).length;
    final total = _answers.length;
    final score = total > 0 ? (correct / total * 100) : 0.0;
    final totalXp = _answers.fold<int>(0, (sum, a) => sum + a.pointsEarned);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              ScoreReveal(
                score: score,
                maxScore: 100,
                label: widget.title,
                subtitle: '$correct/$total correct',
              ),
              const SizedBox(height: 24),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('Correct', '$correct', AppColors.success),
                  _buildStat('Wrong', '${total - correct}', AppColors.error),
                  _buildStat('XP', '+$totalXp', AppColors.xpColor),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getAccentColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back to Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Practice?'),
        content: const Text('Your session progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SessionAnswer {
  final String userAnswer, exerciseId;
  final bool isCorrect;
  final int pointsEarned;

  const _SessionAnswer({
    required this.userAnswer,
    required this.isCorrect,
    required this.exerciseId,
    required this.pointsEarned,
  });
}
