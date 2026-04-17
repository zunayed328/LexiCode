import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

/// AI-guided writing lab with task prompt, text editor, and AI evaluation panel.
class WritingLabScreen extends StatefulWidget {
  const WritingLabScreen({super.key});

  @override
  State<WritingLabScreen> createState() => _WritingLabScreenState();
}

class _WritingLabScreenState extends State<WritingLabScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isEvaluating = false;
  bool _showFeedback = false;
  _WritingFeedback? _feedback;
  int _selectedTaskIndex = 0;

  final _tasks = [
    _WritingTask(
      title: 'Email to a Colleague',
      prompt:
          'Write a professional email to your team lead requesting a code review for your latest pull request. Include: what changes you made, why, and any areas you want them to focus on.',
      type: 'Email',
      wordTarget: 150,
      level: 'B1',
    ),
    _WritingTask(
      title: 'Bug Report',
      prompt:
          'Write a clear bug report for the following issue: The login page freezes when users enter special characters in the password field on iOS devices. Include: steps to reproduce, expected vs actual behavior, and your environment.',
      type: 'Technical Writing',
      wordTarget: 200,
      level: 'B2',
    ),
    _WritingTask(
      title: 'Feature Proposal',
      prompt:
          'Write a short proposal for adding dark mode to your application. Explain: the user benefit, technical approach, estimated effort, and potential challenges.',
      type: 'Business Writing',
      wordTarget: 250,
      level: 'B2',
    ),
  ];

  int get _wordCount {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = _tasks[_selectedTaskIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: _showFeedback
                  ? _buildFeedbackPanel(isDark)
                  : _buildEditor(isDark, task),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text('Writing Lab',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          if (_showFeedback)
            TextButton(
              onPressed: () => setState(() {
                _showFeedback = false;
                _feedback = null;
              }),
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildEditor(bool isDark, _WritingTask task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final isActive = index == _selectedTaskIndex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTaskIndex = index;
                    _textController.clear();
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.secondary
                          : (isDark
                              ? AppColors.darkCard
                              : AppColors.lightBackground),
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                    ),
                    child: Text(
                      _tasks[index].title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Task prompt
          GlassCard(
            borderColor: AppColors.secondary.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(task.type,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${task.wordTarget} words',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(task.level,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(task.prompt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Editor
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 12,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 15, height: 1.7),
                  decoration: InputDecoration(
                    hintText: 'Start writing here...',
                    hintStyle: GoogleFonts.inter(
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                // Word counter
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        '$_wordCount words',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _wordCount >= task.wordTarget
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (_wordCount / task.wordTarget)
                                .clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            valueColor: AlwaysStoppedAnimation(
                              _wordCount >= task.wordTarget
                                  ? AppColors.success
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target: ${task.wordTarget}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _wordCount >= 20 && !_isEvaluating
                  ? _submitWriting
                  : null,
              icon: _isEvaluating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isEvaluating ? 'AI Evaluating...' : 'Submit for AI Review',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitWriting() {
    setState(() => _isEvaluating = true);

    // Simulate AI evaluation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isEvaluating = false;
        _showFeedback = true;
        _feedback = _WritingFeedback(
          overallScore: 72,
          grammarScore: 78,
          vocabularyScore: 65,
          structureScore: 74,
          grammarErrors: [
            _WritingError(
              original: 'I have went to the meeting.',
              corrected: 'I have gone to the meeting.',
              explanation: 'Use past participle "gone" with "have".',
            ),
            _WritingError(
              original: 'The data shows that...',
              corrected: 'The data show that...',
              explanation: '"Data" is technically plural (singular: datum).',
            ),
          ],
          vocabularySuggestions: [
            'Consider using "implement" instead of "do"',
            'Replace "big" with "significant" or "substantial"',
            'Use "subsequently" instead of "then" for formal writing',
          ],
          correctedVersion:
              _textController.text.replaceAll('went', 'gone'),
          overallFeedback:
              'Good effort! Your writing communicates the key points effectively. Focus on using more varied vocabulary and maintaining consistent tense throughout.',
        );
      });
    });
  }

  Widget _buildFeedbackPanel(bool isDark) {
    if (_feedback == null) return const SizedBox();
    final fb = _feedback!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scores
          Text('AI Evaluation',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              _ScoreCircle('Overall', fb.overallScore, AppColors.secondary),
              const SizedBox(width: 12),
              _ScoreCircle('Grammar', fb.grammarScore, AppColors.accentGreen),
              const SizedBox(width: 12),
              _ScoreCircle('Vocabulary', fb.vocabularyScore, AppColors.info),
              const SizedBox(width: 12),
              _ScoreCircle('Structure', fb.structureScore, AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          // Overall feedback
          GlassCard(
            child: Text(
              fb.overallFeedback,
              style: GoogleFonts.inter(
                  fontSize: 14, height: 1.6, fontStyle: FontStyle.italic),
            ),
          ),
          // Grammar errors
          if (fb.grammarErrors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('❌ Grammar Corrections',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...fb.grammarErrors.map((error) => GlassCard(
                  borderColor: AppColors.error.withValues(alpha: 0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(error.original,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.error,
                          )),
                      const SizedBox(height: 4),
                      Text(error.corrected,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          )),
                      const SizedBox(height: 6),
                      Text(error.explanation,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          )),
                    ],
                  ),
                )),
          ],
          // Vocabulary suggestions
          if (fb.vocabularySuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('💡 Vocabulary Tips',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...fb.vocabularySuggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('→ ', style: TextStyle(color: AppColors.info)),
                      Expanded(
                        child: Text(s,
                            style: GoogleFonts.inter(
                                fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _showFeedback = false;
                    _feedback = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Revise'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Done',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreCircle(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text('$score',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _WritingTask {
  final String title, prompt, type, level;
  final int wordTarget;
  const _WritingTask({
    required this.title, required this.prompt, required this.type,
    required this.wordTarget, required this.level,
  });
}

class _WritingFeedback {
  final int overallScore, grammarScore, vocabularyScore, structureScore;
  final List<_WritingError> grammarErrors;
  final List<String> vocabularySuggestions;
  final String correctedVersion, overallFeedback;
  const _WritingFeedback({
    required this.overallScore, required this.grammarScore,
    required this.vocabularyScore, required this.structureScore,
    required this.grammarErrors, required this.vocabularySuggestions,
    required this.correctedVersion, required this.overallFeedback,
  });
}

class _WritingError {
  final String original, corrected, explanation;
  const _WritingError({
    required this.original, required this.corrected, required this.explanation,
  });
}
