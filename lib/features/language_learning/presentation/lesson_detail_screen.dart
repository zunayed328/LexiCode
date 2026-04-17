import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_provider.dart';
import '../../../shared/models/lesson_model.dart';
import '../../../shared/widgets/gradient_button.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  int _xpEarned = 0;
  bool _isCompleted = false;
  late AnimationController _shakeController;

  List<QuestionModel> get questions => widget.lesson.questions;
  QuestionModel get current => questions[_currentQuestion];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _checkAnswer(String answer) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _isCorrect = answer == current.correctAnswer;
      if (_isCorrect) {
        _correctCount++;
        _xpEarned += current.xpReward;
      } else {
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < questions.length - 1) {
      setState(() { _currentQuestion++; _selectedAnswer = null; _isAnswered = false; _isCorrect = false; });
    } else {
      setState(() => _isCompleted = true);
      context.read<AppProvider>().completeLesson(widget.lesson.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isCompleted) return _buildCompletionScreen(isDark);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildQuestionCard(isDark),
                const SizedBox(height: 20),
                if (current.codeSnippet != null) _buildCodeSnippet(current.codeSnippet!),
                if (current.codeSnippet != null) const SizedBox(height: 16),
                ..._buildOptions(isDark),
                if (_isAnswered) ...[const SizedBox(height: 16), _buildFeedback(isDark)],
              ]),
            ),
          ),
          if (_isAnswered) _buildBottomButton(isDark),
        ]),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        Expanded(
          child: LinearPercentIndicator(
            lineHeight: 10, percent: (_currentQuestion + 1) / questions.length,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            linearGradient: LinearGradient(colors: [widget.lesson.color, widget.lesson.color.withValues(alpha: 0.7)]),
            barRadius: const Radius.circular(5), padding: EdgeInsets.zero, animation: true,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.xpColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, color: AppColors.xpColor, size: 16),
            const SizedBox(width: 4),
            Text('$_xpEarned', style: const TextStyle(color: AppColors.xpColor, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          widget.lesson.color.withValues(alpha: 0.1),
          widget.lesson.color.withValues(alpha: 0.03),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.lesson.color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: widget.lesson.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Text('${_currentQuestion + 1}/${questions.length}',
                style: TextStyle(color: widget.lesson.color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(current.type == QuestionType.fillBlank ? 'Fill in the Blank' : 'Multiple Choice',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
        ]),
        const SizedBox(height: 16),
        Text(current.question, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5)),
      ]),
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.codeBackground, borderRadius: BorderRadius.circular(12)),
      child: Text(code, style: GoogleFonts.firaCode(fontSize: 13, color: AppColors.darkText, height: 1.5)),
    );
  }

  List<Widget> _buildOptions(bool isDark) {
    return current.options.map((option) {
      final isSelected = _selectedAnswer == option;
      final isCorrectOption = option == current.correctAnswer;
      Color bgColor;
      Color borderColor;

      if (!_isAnswered) {
        bgColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
        borderColor = isSelected ? widget.lesson.color : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
      } else if (isCorrectOption) {
        bgColor = AppColors.accentGreen.withValues(alpha: 0.1);
        borderColor = AppColors.accentGreen;
      } else if (isSelected && !_isCorrect) {
        bgColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error;
      } else {
        bgColor = isDark ? AppColors.darkCard.withValues(alpha: 0.5) : AppColors.lightSurface.withValues(alpha: 0.5);
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => _checkAnswer(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: isSelected || (_isAnswered && isCorrectOption) ? 2 : 1),
            ),
            child: Row(children: [
              Expanded(child: Text(option, style: GoogleFonts.inter(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
              if (_isAnswered && isCorrectOption)
                const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 22),
              if (_isAnswered && isSelected && !_isCorrect)
                const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
            ]),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFeedback(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_isCorrect ? AppColors.accentGreen : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (_isCorrect ? AppColors.accentGreen : AppColors.error).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_isCorrect ? Icons.celebration_rounded : Icons.info_rounded,
              color: _isCorrect ? AppColors.accentGreen : AppColors.error, size: 22),
          const SizedBox(width: 8),
          Text(_isCorrect ? 'Correct! 🎉' : 'Not quite right',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                  color: _isCorrect ? AppColors.accentGreen : AppColors.error)),
          if (_isCorrect) ...[
            const Spacer(),
            Text('+${current.xpReward} XP', style: const TextStyle(color: AppColors.xpColor, fontWeight: FontWeight.w700)),
          ],
        ]),
        const SizedBox(height: 8),
        Text(current.explanation,
            style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ]),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: GradientButton(
        text: _currentQuestion < questions.length - 1 ? 'Continue' : 'Finish Lesson',
        onPressed: _nextQuestion, width: double.infinity,
        gradient: _isCorrect
            ? const LinearGradient(colors: [AppColors.accentGreen, Color(0xFF38A802)])
            : AppColors.primaryGradient,
      ),
    );
  }

  Widget _buildCompletionScreen(bool isDark) {
    final accuracy = questions.isNotEmpty ? (_correctCount / questions.length * 100).round() : 0;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accentGreen, Color(0xFF38A802)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.celebration_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text('Lesson Complete! 🎉', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text(widget.lesson.title, style: TextStyle(fontSize: 16, color: AppColors.darkTextSecondary)),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _buildCompletionStat('$_correctCount/${questions.length}', 'Correct', AppColors.accentGreen),
                const SizedBox(width: 24),
                _buildCompletionStat('$accuracy%', 'Accuracy', AppColors.info),
                const SizedBox(width: 24),
                _buildCompletionStat('+$_xpEarned', 'XP Earned', AppColors.xpColor),
              ]),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GradientButton(
                  text: 'Continue Learning', onPressed: () => Navigator.pop(context),
                  width: double.infinity,
                  gradient: const LinearGradient(colors: [AppColors.accentGreen, Color(0xFF38A802)]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStat(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
    ]);
  }
}
