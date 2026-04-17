import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/exercise_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/content_generation_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/timer_widget.dart';
import 'exam_result_screen.dart';

class IeltsReadingScreen extends StatefulWidget {
  final bool isFullExam;

  const IeltsReadingScreen({super.key, this.isFullExam = false});

  @override
  State<IeltsReadingScreen> createState() => _IeltsReadingScreenState();
}

class _IeltsReadingScreenState extends State<IeltsReadingScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  bool _isLoading = true;
  String? _error;
  ExerciseSession? _session;

  int _currentQuestionIndex = 0;
  final List<ExerciseResult> _results = [];
  final Color _accentColor = const Color(0xFF10B981);
  String _selectedAnswer = '';

  @override
  void initState() {
    super.initState();
    _loadSection();
  }

  Future<void> _loadSection() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final session = await _contentService.getIELTSSection(
        IELTSSectionType.reading,
        progress,
      );
      if (mounted) {
        setState(() {
          _session = session;
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

  void _onAnswer(String answer) {
    setState(() => _selectedAnswer = answer);
  }

  void _nextQuestion() {
    if (_session == null) return;

    final currentQ = _session!.exercises[_currentQuestionIndex];
    final isCorrect =
        _selectedAnswer.trim().toLowerCase() ==
        currentQ.correctAnswer.trim().toLowerCase();

    _results.add(
      ExerciseResult(
        exerciseId: currentQ.id,
        userAnswer: _selectedAnswer,
        isCorrect: isCorrect,
        scoreEarned: isCorrect ? currentQ.points : 0,
        feedback: currentQ.explanation,
      ),
    );

    _selectedAnswer = '';

    if (_currentQuestionIndex < _session!.exercises.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _finishSection();
    }
  }

  void _finishSection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ExamResultScreen()),
    );
  }

  void _showExitDialog() {
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
        appBar: AppBar(title: const Text('IELTS Reading')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_session == null || _session!.exercises.isEmpty)
      return const Scaffold();

    final currentQ = _session!.exercises[_currentQuestionIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_session!.warmupText != null &&
                        _currentQuestionIndex == 0) ...[
                      Text(
                        _session!.warmupText!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ExerciseCard(
                      exercise: currentQ,
                      questionNumber: _currentQuestionIndex + 1,
                      totalQuestions: _session!.exercises.length,
                      showFeedback: false,
                      onAnswer: _onAnswer,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close_rounded),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.menu_book_rounded, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reading',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Q${_currentQuestionIndex + 1}/${_session!.exercises.length}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _accentColor,
            ),
          ),
          const SizedBox(width: 12),
          TimerWidget(
            totalSeconds: 60 * 60,
            size: 50,
            color: _accentColor,
            onTimeUp: _finishSection,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _selectedAnswer.isEmpty ? null : _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            _currentQuestionIndex < _session!.exercises.length - 1
                ? 'Next Question'
                : 'Submit Section',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
