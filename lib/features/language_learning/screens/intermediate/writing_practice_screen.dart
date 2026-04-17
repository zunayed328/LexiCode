import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/exercise_types_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/content_generation_service.dart';
import '../../services/gemini_learning_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/score_reveal.dart';

class WritingPracticeScreen extends StatefulWidget {
  const WritingPracticeScreen({super.key});

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  final GeminiLearningService _gemini = GeminiLearningService();
  final TextEditingController _textController = TextEditingController();

  bool _isLoadingTask = true;
  bool _isEvaluating = false;
  String? _error;
  WritingTask? _task;
  WritingEvaluation? _evaluation;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final task = await _contentService.getWritingTask(
        progress.currentLevel,
        progress,
      );
      if (mounted) {
        setState(() {
          _task = task;
          _isLoadingTask = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingTask = false;
        });
      }
    }
  }

  Future<void> _evaluateWriting() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _task == null) return;

    setState(() => _isEvaluating = true);

    try {
      final evaluation = await _gemini.evaluateWriting(text, _task!.prompt);
      if (mounted) {
        setState(() {
          _evaluation = evaluation;
          _isEvaluating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evaluation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isEvaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTask) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFEC4899)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Writing Lab')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_task == null) return const Scaffold();

    if (_evaluation != null) {
      return _buildEvaluationScreen();
    }

    return _buildWritingScreen();
  }

  Widget _buildWritingScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _textController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Writing Lab',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$wordCount / ${_task!.wordCountTarget} words',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: wordCount >= _task!.wordCountTarget
                      ? AppColors.success
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prompt',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEC4899).withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _task!.prompt,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_task!.suggestedVocabulary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Suggested Vocabulary:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _task!.suggestedVocabulary
                              .map(
                                (v) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEC4899,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFEC4899,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    v,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFEC4899),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Start writing here...',
                    hintStyle: GoogleFonts.inter(
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFFEC4899),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: GoogleFonts.inter(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isEvaluating || _textController.text.trim().isEmpty
                      ? null
                      : _evaluateWriting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    disabledBackgroundColor: const Color(
                      0xFFEC4899,
                    ).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isEvaluating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit for Evaluation',
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

  Widget _buildEvaluationScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Normalize band 0-9 to percentage
    final scorePercent = (_evaluation!.overallBand / 9.0 * 100).clamp(
      0.0,
      100.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results',
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
              ScoreReveal(
                score: scorePercent,
                maxScore: 100,
                label: 'Overall Band Score',
                subtitle: _evaluation!.overallBand.toStringAsFixed(1),
              ),
              const SizedBox(height: 24),
              Text(
                'Detailed Feedback',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _evaluation!.detailedFeedback ??
                        'No detailed feedback available.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (_evaluation!.strengths.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Strengths',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                ..._evaluation!.strengths.map(
                  (s) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s, style: GoogleFonts.inter(height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ],
              if (_evaluation!.weaknesses.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Areas for Improvement',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                ..._evaluation!.weaknesses.map(
                  (w) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(w, style: GoogleFonts.inter(height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ],
              if (_evaluation!.grammarErrors.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Corrections',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._evaluation!.grammarErrors.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.original,
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.correction,
                          style: GoogleFonts.inter(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.explanation,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Done',
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
}
