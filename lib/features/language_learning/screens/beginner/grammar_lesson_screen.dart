import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/learning_provider.dart';
import '../../widgets/tts_controls.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/answer_feedback.dart';
import '../../widgets/progress_header.dart';
import '../../widgets/score_reveal.dart';
import '../../models/exercise_model.dart';

/// AI-powered grammar lesson screen.
///
/// Loads a lesson for the given topic, displays explanation, examples,
/// grammar points, then runs practice exercises.
class GrammarLessonScreen extends StatefulWidget {
  final String topic;

  const GrammarLessonScreen({super.key, required this.topic});

  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  bool _inPracticeMode = false;
  bool _showFeedback = false;
  bool _sessionComplete = false;
  int _currentQuestionIdx = 0;
  final List<_AnswerRecord> _answers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().loadLesson(widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<LearningProvider>();

    return Scaffold(
      body: SafeArea(
        child: provider.isLoadingLesson
            ? _buildLoading(isDark)
            : provider.lessonError != null
            ? _buildError(isDark, provider.lessonError!)
            : provider.currentLesson == null
            ? _buildLoading(isDark)
            : _sessionComplete
            ? _buildResults(isDark)
            : _inPracticeMode
            ? _buildPractice(isDark, provider)
            : _buildLesson(isDark, provider),
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
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
            'AI is creating your lesson...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generating unique content for "${widget.topic}"',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<LearningProvider>().loadLesson(widget.topic),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Lesson Content ───────────────────────────────────────────

  Widget _buildLesson(bool isDark, LearningProvider provider) {
    final lesson = provider.currentLesson!;

    return Column(
      children: [
        // App bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  provider.clearLesson();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  lesson.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.xpColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${lesson.xpReward} XP',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.xpColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lesson.topic,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation
                Text(
                  'Explanation',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  lesson.explanation,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.7,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // TTS for explanation
                TtsControls(text: lesson.explanation),
                const SizedBox(height: 24),

                // Grammar Points
                if (lesson.grammarPoints.isNotEmpty) ...[
                  Text(
                    'Key Grammar Points',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lesson.grammarPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point.rule,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (point.examples.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '✏️ ${point.examples.first}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Examples with TTS
                if (lesson.examples.isNotEmpty) ...[
                  Text(
                    'Examples',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lesson.examples.asMap().entries.map((entry) {
                    final ex = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.sentence,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (ex.translationHint != null)
                                    Text(
                                      ex.translationHint!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            TtsControls(text: ex.sentence, compact: true),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Common Mistakes
                if (lesson.commonMistakes.isNotEmpty) ...[
                  Text(
                    '⚠️ Common Mistakes',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...lesson.commonMistakes.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('❌ ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              m,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.4,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tips
                if (lesson.tips.isNotEmpty) ...[
                  Text(
                    '💡 Tips',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...lesson.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.4,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Start Practice Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: lesson.exercises.isEmpty
                        ? null
                        : () => setState(() => _inPracticeMode = true),
                    icon: Icon(
                      lesson.exercises.isEmpty
                          ? Icons.hourglass_empty_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      lesson.exercises.isEmpty
                          ? 'No practice questions available'
                          : 'Start Practice (${lesson.exercises.length} questions)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      disabledBackgroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Practice Mode ────────────────────────────────────────────

  Widget _buildPractice(bool isDark, LearningProvider provider) {
    final lesson = provider.currentLesson!;
    final exercises = lesson.exercises;

    if (_currentQuestionIdx >= exercises.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _sessionComplete = true);
      });
      return const SizedBox();
    }

    final currentEx = exercises[_currentQuestionIdx];

    return Column(
      children: [
        ProgressHeader(
          currentQuestion: _currentQuestionIdx + 1,
          totalQuestions: exercises.length,
          sessionTitle: 'Grammar Practice',
          accentColor: AppColors.accentGreen,
          onClose: () => _showExitDialog(context),
        ),
        Expanded(
          child: ExerciseCard(
            exercise: currentEx,
            questionNumber: _currentQuestionIdx + 1,
            totalQuestions: exercises.length,
            showFeedback: _showFeedback,
            result: _showFeedback && _answers.isNotEmpty
                ? ExerciseResult(
                    exerciseId: currentEx.id,
                    userAnswer: _answers.last.userAnswer,
                    isCorrect: _answers.last.isCorrect,
                    scoreEarned: _answers.last.isCorrect ? currentEx.points : 0,
                    feedback: _answers.last.isCorrect
                        ? currentEx.explanation
                        : 'Correct: ${currentEx.correctAnswer}. ${currentEx.explanation}',
                  )
                : null,
            onAnswer: (answer) => _submitAnswer(answer, currentEx),
          ),
        ),
        if (_showFeedback)
          AnswerFeedback(
            isCorrect: _answers.last.isCorrect,
            feedback: _answers.last.isCorrect
                ? currentEx.explanation
                : 'The correct answer is: ${currentEx.correctAnswer}. ${currentEx.explanation}',
            xpEarned: _answers.last.isCorrect ? currentEx.points : 0,
            streakCount: _currentStreak,
            onContinue: () {
              setState(() {
                _showFeedback = false;
                _currentQuestionIdx++;
              });
            },
          ),
      ],
    );
  }

  int get _currentStreak {
    int streak = 0;
    for (int i = _answers.length - 1; i >= 0; i--) {
      if (_answers[i].isCorrect) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _submitAnswer(String answer, Exercise exercise) {
    final isCorrect =
        answer.trim().toLowerCase() ==
            exercise.correctAnswer.trim().toLowerCase() ||
        (exercise.alternateCorrectAnswers?.any(
              (a) => a.trim().toLowerCase() == answer.trim().toLowerCase(),
            ) ??
            false);

    setState(() {
      _answers.add(
        _AnswerRecord(
          userAnswer: answer,
          isCorrect: isCorrect,
          exerciseId: exercise.id,
        ),
      );
      _showFeedback = true;
    });
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Practice?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LearningProvider>().clearLesson();
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ─── Results ──────────────────────────────────────────────────

  Widget _buildResults(bool isDark) {
    final correct = _answers.where((a) => a.isCorrect).length;
    final total = _answers.length;
    final score = total > 0 ? (correct / total * 100) : 0.0;
    final provider = context.read<LearningProvider>();

    // Complete lesson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.completeLesson(provider.currentLesson?.id ?? '', score);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          ScoreReveal(
            score: score,
            maxScore: 100,
            label: 'Lesson Complete!',
            subtitle: '$correct/$total correct answers',
          ),
          const SizedBox(height: 32),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultStat('Correct', '$correct', AppColors.success),
              _buildResultStat('Wrong', '${total - correct}', AppColors.error),
              _buildResultStat(
                'XP Earned',
                '+${_answers.where((a) => a.isCorrect).length * 10}',
                AppColors.xpColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                provider.clearLesson();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
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
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
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
}

class _AnswerRecord {
  final String userAnswer;
  final bool isCorrect;
  final String exerciseId;
  const _AnswerRecord({
    required this.userAnswer,
    required this.isCorrect,
    required this.exerciseId,
  });
}
