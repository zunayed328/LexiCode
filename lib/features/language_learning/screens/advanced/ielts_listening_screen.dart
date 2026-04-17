import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/exercise_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/content_generation_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/timer_widget.dart';
import 'exam_result_screen.dart';

class IeltsListeningScreen extends StatefulWidget {
  final bool isFullExam;
  
  const IeltsListeningScreen({super.key, this.isFullExam = false});

  @override
  State<IeltsListeningScreen> createState() => _IeltsListeningScreenState();
}

class _IeltsListeningScreenState extends State<IeltsListeningScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  bool _isLoading = true;
  String? _error;
  ExerciseSession? _session;
  
  int _currentQuestionIndex = 0;
  final List<ExerciseResult> _results = [];
  final Color _accentColor = const Color(0xFF3B82F6);

  // Answer state
  String? _selectedOption;
  final TextEditingController _answerController = TextEditingController();
  bool _showFeedback = false;
  
  @override
  void initState() {
    super.initState();
    _loadSection();
    _answerController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _answerController.removeListener(_onTextChanged);
    _answerController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }
  
  Future<void> _loadSection() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final session = await _contentService.getIELTSSection(
        IELTSSectionType.listening,
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

  /// Get the current user answer (from text field or selected MCQ option)
  String get _currentAnswer {
    if (_selectedOption != null) return _selectedOption!;
    return _answerController.text.trim();
  }

  bool get _hasAnswer => _currentAnswer.isNotEmpty;

  /// Check if the current question uses text input (fill-in-the-blank)
  bool _isTextInputQuestion(Exercise q) {
    return q.type == ExerciseType.fillBlank ||
        q.type == ExerciseType.spelling ||
        q.type == ExerciseType.errorCorrection ||
        q.type == ExerciseType.sentenceConstruction ||
        q.options.isEmpty; // If no options, fall back to text input
  }

  void _checkAnswer() {
    if (_session == null || !_hasAnswer) return;

    final currentQ = _session!.exercises[_currentQuestionIndex];
    final answer = _currentAnswer;

    final isCorrect = answer.trim().toLowerCase() ==
        currentQ.correctAnswer.trim().toLowerCase();

    _results.add(ExerciseResult(
      exerciseId: currentQ.id,
      userAnswer: answer,
      isCorrect: isCorrect,
      scoreEarned: isCorrect ? currentQ.points : 0,
      feedback: currentQ.explanation,
    ));

    setState(() => _showFeedback = true);
  }

  void _nextQuestion() {
    // If feedback is not shown yet, check the answer first
    if (!_showFeedback) {
      _checkAnswer();
      return;
    }

    // Reset state for next question
    _selectedOption = null;
    _answerController.clear();
    _showFeedback = false;
    
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('IELTS Listening')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_session == null || _session!.exercises.isEmpty) return const Scaffold();

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warmup text
                    if (_session!.warmupText != null && _currentQuestionIndex == 0) ...[
                      Text(_session!.warmupText!,
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 16),
                    ],

                    // Question badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Question ${_currentQuestionIndex + 1} of ${_session!.exercises.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question text with markdown bold rendering
                    _buildRichQuestion(currentQ.question, isDark),
                    const SizedBox(height: 8),

                    // Points
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16,
                            color: AppColors.xpColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text('${currentQ.points} XP',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.xpColor,
                            )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Context / audio transcript
                    if (currentQ.audioText != null && currentQ.audioText!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard.withValues(alpha: 0.5)
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.headphones_rounded,
                                    color: _accentColor, size: 16),
                                const SizedBox(width: 6),
                                Text('Audio Transcript',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _accentColor,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildRichQuestion(currentQ.audioText!, isDark,
                                fontSize: 14, italic: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Context passage
                    if (currentQ.context != null && currentQ.context!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard.withValues(alpha: 0.5)
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: _buildRichQuestion(currentQ.context!, isDark,
                            fontSize: 14, italic: true),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Answer area
                    _buildAnswerArea(currentQ, isDark),
                    const SizedBox(height: 16),

                    // Feedback
                    if (_showFeedback && _results.isNotEmpty)
                      _buildFeedbackCard(currentQ, isDark),
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

  /// Builds rich text that renders **bold** markdown inline
  Widget _buildRichQuestion(String text, bool isDark,
      {double fontSize = 20, bool italic = false}) {
    // Parse **bold** markers into TextSpans
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1.4,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ));
      }
      // Bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.4,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: isDark ? Colors.white : AppColors.lightText,
        ),
      ));
      lastEnd = match.end;
    }

    // Remaining text after the last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.4,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: isDark ? Colors.white : AppColors.lightText,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Builds the appropriate answer area based on question type
  Widget _buildAnswerArea(Exercise q, bool isDark) {
    if (_isTextInputQuestion(q)) {
      return _buildTextInput(isDark);
    }
    return _buildOptions(q, isDark);
  }

  /// Text input field for fill-in-the-blank questions
  Widget _buildTextInput(bool isDark) {
    return TextField(
      controller: _answerController,
      enabled: !_showFeedback,
      style: GoogleFonts.inter(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        prefixIcon: Icon(Icons.edit_rounded,
            color: isDark ? Colors.white38 : Colors.black38, size: 20),
        suffixIcon: _showFeedback && _results.isNotEmpty
            ? Icon(
                _results.last.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: _results.last.isCorrect
                    ? AppColors.success
                    : AppColors.error,
              )
            : null,
      ),
      onSubmitted: _showFeedback ? null : (_) => _checkAnswer(),
    );
  }

  /// MCQ options for multiple choice questions
  Widget _buildOptions(Exercise q, bool isDark) {
    return Column(
      children: q.options.map((option) {
        final isSelected = _selectedOption == option;
        final isCorrect = _showFeedback && option == q.correctAnswer;
        final isWrong = _showFeedback && isSelected && !isCorrect;

        Color bgColor;
        Color borderColor;
        if (_showFeedback && isCorrect) {
          bgColor = AppColors.success.withValues(alpha: 0.15);
          borderColor = AppColors.success;
        } else if (isWrong) {
          bgColor = AppColors.error.withValues(alpha: 0.15);
          borderColor = AppColors.error;
        } else if (isSelected) {
          bgColor = _accentColor.withValues(alpha: 0.1);
          borderColor = _accentColor;
        } else {
          bgColor = isDark
              ? AppColors.darkCard.withValues(alpha: 0.5)
              : Colors.white;
          borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: _showFeedback
                ? null
                : () => setState(() => _selectedOption = option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(option,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isDark ? Colors.white : AppColors.lightText,
                        )),
                  ),
                  if (_showFeedback && isCorrect)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 22),
                  if (isWrong)
                    const Icon(Icons.cancel_rounded,
                        color: AppColors.error, size: 22),
                  if (!_showFeedback && isSelected)
                    Icon(Icons.radio_button_checked_rounded,
                        color: _accentColor, size: 22),
                  if (!_showFeedback && !isSelected)
                    Icon(Icons.radio_button_off_rounded,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Feedback card shown after checking an answer
  Widget _buildFeedbackCard(Exercise q, bool isDark) {
    final result = _results.last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (result.isCorrect ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (result.isCorrect ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: result.isCorrect ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                result.isCorrect ? 'Correct!' : 'Incorrect',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: result.isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
              if (result.isCorrect) ...[
                const Spacer(),
                Text('+${result.scoreEarned} XP',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.xpColor,
                    )),
              ],
            ],
          ),
          if (!result.isCorrect) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correct answer: ${q.correctAnswer}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(q.explanation,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                )),
          ],
        ],
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
            child: Icon(Icons.headphones_rounded, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Listening',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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
            totalSeconds: 30 * 60,
            size: 50,
            color: _accentColor,
            onTimeUp: _finishSection,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final String buttonLabel;
    if (!_showFeedback) {
      buttonLabel = 'Check Answer';
    } else if (_currentQuestionIndex < _session!.exercises.length - 1) {
      buttonLabel = 'Next Question';
    } else {
      buttonLabel = 'Submit Section';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _hasAnswer || _showFeedback ? _nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _showFeedback ? AppColors.success : _accentColor,
            disabledBackgroundColor: _accentColor.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            buttonLabel,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
