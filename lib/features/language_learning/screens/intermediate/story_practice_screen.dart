import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/exercise_model.dart';
import '../../models/exercise_types_model.dart';
import '../../services/content_generation_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/score_reveal.dart';

class StoryPracticeScreen extends StatefulWidget {
  const StoryPracticeScreen({super.key});

  @override
  State<StoryPracticeScreen> createState() => _StoryPracticeScreenState();
}

class _StoryPracticeScreenState extends State<StoryPracticeScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  bool _isLoading = true;
  String? _error;
  ReadingPassage? _passage;

  bool _showQuestions = false;
  int _currentQuestionIndex = 0;
  bool _showFeedback = false;
  final List<bool> _answersCorrect = [];
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPassage();
  }

  Future<void> _loadPassage() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final passage = await _contentService.getReadingPassage(
        progress.currentLevel,
        progress,
        focusTopic:
            'A captivating fiction story (mystery, fantasy, or adventure)',
      );
      if (mounted) {
        setState(() {
          _passage = passage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _submitAnswer(String answer) {
    if (_showFeedback) return;

    final currentQ = _passage!.comprehensionQuestions[_currentQuestionIndex];
    final isCorrect =
        answer.trim().toLowerCase() ==
        currentQ.correctAnswer.trim().toLowerCase();

    setState(() {
      _showFeedback = true;
      _answersCorrect.add(isCorrect);
      if (isCorrect) _correctCount++;
    });
  }

  void _nextQuestion() {
    setState(() {
      _showFeedback = false;
      _currentQuestionIndex++;
    });
  }

  void _showPassageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_passage!.title),
        content: SingleChildScrollView(
          child: Text(_passage!.content, style: GoogleFonts.inter(height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story Practice')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_passage == null) return const Scaffold();

    if (_showQuestions) {
      if (_currentQuestionIndex >= _passage!.comprehensionQuestions.length) {
        return _buildResultsScreen();
      }
      return _buildQuestionsScreen();
    }

    return _buildPassageScreen();
  }

  Widget _buildPassageScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Story Time',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _passage!.title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
              ),
              if (_passage!.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  _passage!.subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    _passage!.content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_passage!.vocabularyWords.isNotEmpty) ...[
                Text(
                  'Key Vocabulary',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._passage!.vocabularyWords.map(
                  (v) => ListTile(
                    title: Text(
                      v.word,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    subtitle: Text(v.definition),
                    dense: true,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showQuestions = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Start Questions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsScreen() {
    final currentQ = _passage!.comprehensionQuestions[_currentQuestionIndex];
    final isCorrect = _showFeedback ? _answersCorrect.last : false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${_currentQuestionIndex + 1} of ${_passage!.comprehensionQuestions.length}',
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: _showPassageDialog,
            tooltip: 'Read Story',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ExerciseCard(
                exercise: currentQ,
                questionNumber: _currentQuestionIndex + 1,
                totalQuestions: _passage!.comprehensionQuestions.length,
                showFeedback: _showFeedback,
                result: _showFeedback
                    ? ExerciseResult(
                        exerciseId: currentQ.id,
                        userAnswer: '',
                        isCorrect: isCorrect,
                        scoreEarned: isCorrect ? currentQ.points : 0,
                        feedback: currentQ.explanation,
                      )
                    : null,
                onAnswer: _submitAnswer,
              ),
            ),
            if (_showFeedback)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  border: Border(
                    top: BorderSide(
                      color: isCorrect ? AppColors.success : AppColors.error,
                      width: 2,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCorrect
                                ? AppColors.success
                                : AppColors.error,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isCorrect ? 'Correct!' : 'Incorrect',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentQ.explanation,
                        style: GoogleFonts.inter(fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCorrect
                              ? AppColors.success
                              : AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final score = _correctCount / _passage!.comprehensionQuestions.length * 100;

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
                label: 'Story Comprehension',
                subtitle:
                    '$_correctCount/${_passage!.comprehensionQuestions.length} correct',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Finish Practicing',
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
}
