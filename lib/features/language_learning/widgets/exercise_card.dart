import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/exercise_model.dart';

/// Renders a single exercise question with interactive answer input.
///
/// Supports: Multiple choice, Fill-in-blank, True/False, Error correction.
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final int questionNumber;
  final int totalQuestions;
  final ValueChanged<String> onAnswer;
  final bool showFeedback;
  final ExerciseResult? result;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onAnswer,
    this.showFeedback = false,
    this.result,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with TickerProviderStateMixin {
  String? _selectedOption;
  final TextEditingController _textController = TextEditingController();
  bool _showHint = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Rebuild when text changes so the Check Answer button enables/disables
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _selectedOption = null;
      _textController.clear();
      _showHint = false;
      _isRecording = false;
      _hasRecorded = false;
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _shakeController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ex = widget.exercise;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * (widget.result?.isCorrect == false ? 1 : 0),
            0,
          ),
          child: child,
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number badge
            _buildQuestionBadge(isDark),
            const SizedBox(height: 16),

            // Question text
            Text(
              ex.question,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),

            // Points indicator
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: AppColors.xpColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${ex.points} XP',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.xpColor,
                  ),
                ),
                if (ex.difficulty == ExerciseDifficulty.hard ||
                    ex.difficulty == ExerciseDifficulty.challenging) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ex.difficulty.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Context/passage if available
            if (ex.context != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withValues(alpha: 0.5)
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  ex.context!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Answer area
            _buildAnswerArea(isDark, ex),
            const SizedBox(height: 20),

            // Hint button
            if (ex.hint != null && !widget.showFeedback)
              _buildHintArea(isDark, ex),

            // Submit button
            if (!widget.showFeedback) _buildSubmitButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Question ${widget.questionNumber} of ${widget.totalQuestions}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnswerArea(bool isDark, Exercise ex) {
    switch (ex.type) {
      case ExerciseType.mcq:
      case ExerciseType.trueFalse:
        return _buildOptions(isDark, ex);
      case ExerciseType.fillBlank:
      case ExerciseType.spelling:
        return _buildTextInput(isDark, ex);
      case ExerciseType.errorCorrection:
        return _buildErrorCorrection(isDark, ex);
      case ExerciseType.sentenceConstruction:
        return _buildTextInput(isDark, ex);
      case ExerciseType.speakingPrompt:
        return _buildSpeakingInput(isDark, ex);
      default:
        return _buildOptions(isDark, ex);
    }
  }

  Widget _buildOptions(bool isDark, Exercise ex) {
    final options = ex.options;
    return Column(
      children: options.map((option) {
        final isSelected = _selectedOption == option;
        final isCorrect = widget.showFeedback && option == ex.correctAnswer;
        final isWrong = widget.showFeedback && isSelected && !isCorrect;

        Color bgColor;
        Color borderColor;
        if (widget.showFeedback && isCorrect) {
          bgColor = AppColors.success.withValues(alpha: 0.15);
          borderColor = AppColors.success;
        } else if (isWrong) {
          bgColor = AppColors.error.withValues(alpha: 0.15);
          borderColor = AppColors.error;
        } else if (isSelected) {
          bgColor = AppColors.primary.withValues(alpha: 0.1);
          borderColor = AppColors.primary;
        } else {
          bgColor = isDark
              ? AppColors.darkCard.withValues(alpha: 0.5)
              : Colors.white;
          borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: widget.showFeedback
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
                    child: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isDark ? Colors.white : AppColors.lightText,
                      ),
                    ),
                  ),
                  if (widget.showFeedback && isCorrect)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                  if (isWrong)
                    const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.error,
                      size: 22,
                    ),
                  if (!widget.showFeedback && isSelected)
                    Icon(
                      Icons.radio_button_checked_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  if (!widget.showFeedback && !isSelected)
                    Icon(
                      Icons.radio_button_off_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(bool isDark, Exercise ex) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          enabled: !widget.showFeedback,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: ex.type == ExerciseType.spelling
                ? 'Type the correct spelling...'
                : 'Type your answer...',
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: widget.showFeedback
                ? Icon(
                    widget.result?.isCorrect == true
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: widget.result?.isCorrect == true
                        ? AppColors.success
                        : AppColors.error,
                  )
                : null,
          ),
          onSubmitted: widget.showFeedback
              ? null
              : (value) => widget.onAnswer(value),
        ),
        if (widget.showFeedback && widget.result?.isCorrect == false) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Correct answer: ${ex.correctAnswer}',
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
      ],
    );
  }

  Widget _buildErrorCorrection(bool isDark, Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Find and correct the error:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ex.context ?? ex.question,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          enabled: !widget.showFeedback,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Write the corrected sentence...',
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingInput(bool isDark, Exercise ex) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Instruction label
        Text(
          _hasRecorded
              ? '✅ Recording complete!'
              : _isRecording
              ? '🔴 Recording... Tap to stop'
              : 'Tap the microphone to start speaking',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _hasRecorded
                ? AppColors.success
                : _isRecording
                ? const Color(0xFFEF4444)
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // Animated mic button
        Center(
          child: GestureDetector(
            onTap: widget.showFeedback
                ? null
                : () {
                    setState(() {
                      if (_isRecording) {
                        // Stop recording
                        _isRecording = false;
                        _hasRecorded = true;
                        _pulseController.stop();
                        _pulseController.reset();
                      } else if (!_hasRecorded) {
                        // Start recording
                        _isRecording = true;
                        _pulseController.repeat(reverse: true);
                      }
                    });
                  },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = _isRecording ? _pulseAnimation.value : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _hasRecorded
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : _isRecording
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isRecording
                                  ? const Color(0xFFEF4444)
                                  : _hasRecorded
                                  ? const Color(0xFF10B981)
                                  : AppColors.primary)
                              .withValues(alpha: 0.35),
                      blurRadius: _isRecording ? 24 : 16,
                      spreadRadius: _isRecording ? 4 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _hasRecorded
                      ? Icons.check_rounded
                      : _isRecording
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Waveform / status area
        if (_isRecording)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Listening...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),

        // Completed label
        if (_hasRecorded && !_isRecording)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Your answer has been recorded',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

        // Re-record option
        if (_hasRecorded && !widget.showFeedback) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _hasRecorded = false;
                _isRecording = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Record again',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHintArea(bool isDark, Exercise ex) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showHint = !_showHint),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _showHint ? 'Hide Hint' : 'Show Hint',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        if (_showHint) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              ex.hint!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    final hasAnswer =
        _selectedOption != null ||
        _textController.text.trim().isNotEmpty ||
        _hasRecorded;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: hasAnswer
            ? () {
                final answer = _hasRecorded
                    ? widget.exercise.correctAnswer
                    : (_selectedOption ?? _textController.text.trim());
                widget.onAnswer(answer);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Check Answer',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: hasAnswer
                ? Colors.white
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
