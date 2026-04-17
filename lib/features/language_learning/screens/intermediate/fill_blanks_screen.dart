import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_model.dart';
import '../../providers/practice_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/answer_feedback.dart';
import '../../widgets/progress_header.dart';
import '../../widgets/score_reveal.dart';

class FillBlanksScreen extends StatefulWidget {
  const FillBlanksScreen({super.key});

  @override
  State<FillBlanksScreen> createState() => _FillBlanksScreenState();
}

class _FillBlanksScreenState extends State<FillBlanksScreen> {
  bool _initialized = false;
  bool _showFeedback = false;

  late PracticeProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    final progress = context.read<ProgressProvider>().userProgress;
    _provider = context.read<PracticeProvider>();
    await _provider.startSession(
          SessionType.grammarPractice,
          progress.currentLevel,
          progress,
          focusTopic: 'Fill in the blanks context vocabulary',
          questionCount: 10,
        );
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  void _submitAnswer(String answer) {
    if (_showFeedback) return;
    setState(() {
      _showFeedback = true;
    });
    _provider.submitAnswer(answer);
  }

  void _nextQuestion() {
    setState(() => _showFeedback = false);
    _provider.nextExercise();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PracticeProvider>();

    if (!_initialized || provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF14B8A6)),
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fill in the Blanks')),
        body: Center(child: Text('Error: ${provider.error}')),
      );
    }

    if (provider.sessionComplete) {
      return _buildResultsScreen(isDark, provider);
    }

    final currentExercise = provider.currentExercise;
    if (currentExercise == null) return const Scaffold(body: SizedBox());

    final isCorrect = _showFeedback && provider.answers.isNotEmpty
        ? provider.answers.last.isCorrect
        : false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ProgressHeader(
              currentQuestion: provider.currentExerciseIndex + 1,
              totalQuestions: provider.totalExercises,
              sessionTitle: 'Fill in the Blanks',
              accentColor: const Color(0xFF14B8A6),
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: ExerciseCard(
                exercise: currentExercise,
                questionNumber: provider.currentExerciseIndex + 1,
                totalQuestions: provider.totalExercises,
                showFeedback: _showFeedback,
                result: _showFeedback && provider.answers.isNotEmpty
                    ? provider.answers.last
                    : null,
                onAnswer: _submitAnswer,
              ),
            ),
            if (_showFeedback && provider.answers.isNotEmpty)
              AnswerFeedback(
                isCorrect: isCorrect,
                feedback: currentExercise.explanation,
                xpEarned: isCorrect ? currentExercise.points : 0,
                streakCount: provider.streakCount,
                onContinue: _nextQuestion,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(bool isDark, PracticeProvider provider) {
    final score = provider.totalExercises > 0
        ? (provider.correctCount / provider.totalExercises * 100)
        : 0.0;
    
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
                label: 'Fill in the Blanks',
                subtitle: '${provider.correctCount}/${provider.totalExercises} correct',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    provider.resetSession();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Done', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
