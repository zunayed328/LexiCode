import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../widgets/tts_controls.dart';

/// Full-screen story reader with vocabulary tooltips, decision points, and comprehension.
class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({super.key});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  int _currentPage = 0;
  double _fontSize = 17;
  bool _showComprehension = false;
  final Map<int, int> _selectedAnswers = {};
  final Map<String, bool> _vocabularyRevealed = {};

  final _story = _StoryData(
    title: 'The Last Interview',
    author: 'AI Generated',
    readingTime: '8 min',
    level: 'B1-B2',
    pages: [
      _StoryPage(
        text: 'Sarah stared at her laptop screen, her heart racing. The email subject line read: "Interview Confirmation - Senior Developer Position." She had been [*applying*] for jobs for three months, and this was the first callback from a major tech company.\n\nHer qualification was [*adequate*] for the position, but she knew the competition would be fierce. The interview was scheduled for tomorrow at 10 AM, and she needed to prepare [*thoroughly*].',
        vocabularyWords: {
          'applying': 'Making a formal request for a job or position',
          'adequate': 'Sufficient; good enough for a particular purpose',
          'thoroughly': 'In a complete and careful way, covering every detail',
        },
      ),
      _StoryPage(
        text: 'That evening, Sarah opened her coding editor and began reviewing [*algorithms*]. She practiced explaining her thought process aloud, knowing that communication was just as important as technical skills.\n\n"The key to a good interview," she reminded herself, "is to remain [*composed*] and think out loud." She had read that interviewers valued [*transparency*] in a candidate\'s reasoning.',
        vocabularyWords: {
          'algorithms': 'Step-by-step procedures for solving problems or calculations',
          'composed': 'Calm and in control of one\'s feelings',
          'transparency': 'The quality of being open and honest; easy to understand',
        },
        decisionPoint: _DecisionPoint(
          question: 'How should Sarah prepare?',
          options: [
            'Practice coding challenges until midnight',
            'Review key concepts and get enough sleep',
          ],
          correctIndex: 1,
          explanation: 'Getting enough sleep improves cognitive function and interview performance.',
        ),
      ),
      _StoryPage(
        text: 'The next morning, Sarah arrived at the office fifteen minutes early. The receptionist guided her to a modern conference room with glass walls. Two interviewers entered: a technical lead named James and a project manager named Maria.\n\n"Welcome, Sarah," James said with a warm smile. "Let\'s start with a [*preliminary*] question. Can you describe your approach to [*debugging*] a complex system?"',
        vocabularyWords: {
          'preliminary': 'Coming before something more important; introductory',
          'debugging': 'The process of finding and fixing errors in software code',
        },
      ),
      _StoryPage(
        text: 'Sarah took a deep breath. "I follow a [*systematic*] approach," she began. "First, I try to [*reproduce*] the issue consistently. Then I isolate the components to narrow down the root cause. I use logging and breakpoints [*strategically*] to trace the execution flow."\n\nJames nodded approvingly. "That\'s exactly the kind of [*methodology*] we value here."',
        vocabularyWords: {
          'systematic': 'Done according to a fixed plan; methodical',
          'reproduce': 'To create or cause something to happen again',
          'strategically': 'In a way that is planned to achieve a specific purpose',
          'methodology': 'A system of methods used in a particular area of work',
        },
      ),
    ],
    comprehensionQuestions: [
      _ComprehensionQ(
        question: 'How long had Sarah been looking for a job?',
        options: ['One month', 'Two months', 'Three months', 'Six months'],
        correctIndex: 2,
      ),
      _ComprehensionQ(
        question: 'What did Sarah believe was important besides technical skills?',
        options: ['Appearance', 'Communication', 'Experience', 'Education'],
        correctIndex: 1,
      ),
      _ComprehensionQ(
        question: 'What is Sarah\'s approach to debugging?',
        options: [
          'Random testing',
          'Asking colleagues',
          'Systematic isolation and logging',
          'Rewriting the entire code',
        ],
        correctIndex: 2,
      ),
      _ComprehensionQ(
        question: 'What does "composed" mean in the context of the story?',
        options: ['Musical', 'Written', 'Calm and controlled', 'Happy'],
        correctIndex: 2,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            if (!_showComprehension) _buildPageIndicator(isDark),
            Expanded(
              child: _showComprehension
                  ? _buildComprehension(isDark)
                  : _buildStoryPage(isDark),
            ),
            if (!_showComprehension) _buildBottomNav(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_story.title,
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${_story.level} • ${_story.readingTime} read',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ),
          // Font size controls
          IconButton(
            onPressed: () => setState(
                () => _fontSize = (_fontSize - 1).clamp(14, 24)),
            icon: const Icon(Icons.text_decrease_rounded, size: 20),
          ),
          IconButton(
            onPressed: () => setState(
                () => _fontSize = (_fontSize + 1).clamp(14, 24)),
            icon: const Icon(Icons.text_increase_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(_story.pages.length, (i) {
          final isActive = i == _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accentGreen
                    : i < _currentPage
                        ? AppColors.accentGreen.withValues(alpha: 0.4)
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStoryPage(bool isDark) {
    final page = _story.pages[_currentPage];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page number
          Text(
            'Page ${_currentPage + 1} of ${_story.pages.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(height: 16),
          // Story text with vocabulary highlights
          _buildRichText(page, isDark),
          const SizedBox(height: 20),
          // TTS
          TtsControls(
            text: page.text.replaceAll(RegExp(r'\[\*|\*\]'), ''),
            accentColor: AppColors.accentGreen,
          ),
          // Vocabulary section
          if (page.vocabularyWords.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('📚 Vocabulary',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...page.vocabularyWords.entries.map((entry) {
              final revealed = _vocabularyRevealed[entry.key] ?? false;
              return GestureDetector(
                onTap: () => setState(() =>
                    _vocabularyRevealed[entry.key] = !revealed),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.key,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentGreen,
                              )),
                          const Spacer(),
                          Icon(
                            revealed
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: AppColors.accentGreen
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                      if (revealed) ...[
                        const SizedBox(height: 6),
                        Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          // Decision point
          if (page.decisionPoint != null) ...[
            const SizedBox(height: 24),
            _buildDecisionPoint(isDark, page.decisionPoint!),
          ],
        ],
      ),
    );
  }

  Widget _buildRichText(_StoryPage page, bool isDark) {
    final parts = page.text.split(RegExp(r'(\[\*.*?\*\])'));

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: _fontSize,
          height: 1.8,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.lightText,
        ),
        children: parts.map((part) {
          final match = RegExp(r'\[\*(.*?)\*\]').firstMatch(part);
          if (match != null) {
            return TextSpan(
              text: match.group(1),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.accentGreen,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.accentGreen.withValues(alpha: 0.3),
              ),
            );
          }
          return TextSpan(text: part);
        }).toList(),
      ),
    );
  }

  Widget _buildDecisionPoint(bool isDark, _DecisionPoint decision) {
    return GlassCard(
      borderColor: AppColors.secondary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.call_split_rounded,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text('Decision Point',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(decision.question,
              style: GoogleFonts.inter(fontSize: 15)),
          const SizedBox(height: 12),
          ...decision.options.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  // Simple feedback
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      entry.key == decision.correctIndex
                          ? '✅ ${decision.explanation}'
                          : '❌ ${decision.explanation}',
                    ),
                    backgroundColor: entry.key == decision.correctIndex
                        ? AppColors.success
                        : AppColors.error,
                  ));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(entry.value,
                      style: GoogleFonts.inter(fontSize: 14)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComprehension(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📝 Comprehension Check',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ..._story.comprehensionQuestions.asMap().entries.map((entry) {
            final q = entry.value;
            final idx = entry.key;
            final selected = _selectedAnswers[idx];

            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${idx + 1}. ${q.question}',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...q.options.asMap().entries.map((opt) {
                    final isSelected = selected == opt.key;
                    final isCorrect =
                        selected != null && opt.key == q.correctIndex;
                    final isWrong = isSelected && opt.key != q.correctIndex;

                    return GestureDetector(
                      onTap: selected != null
                          ? null
                          : () {
                              setState(() {
                                _selectedAnswers[idx] = opt.key;
                              });
                            },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.1)
                              : isWrong
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.success
                                : isWrong
                                    ? AppColors.error
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(opt.value,
                            style: GoogleFonts.inter(fontSize: 14)),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Done',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _currentPage--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _story.pages.length - 1) {
                  setState(() => _currentPage++);
                } else {
                  setState(() => _showComprehension = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _currentPage < _story.pages.length - 1
                    ? 'Next Page'
                    : 'Comprehension Quiz',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ────────────────────────────────────────────────

class _StoryData {
  final String title, author, readingTime, level;
  final List<_StoryPage> pages;
  final List<_ComprehensionQ> comprehensionQuestions;
  const _StoryData({
    required this.title, required this.author, required this.readingTime,
    required this.level, required this.pages, required this.comprehensionQuestions,
  });
}

class _StoryPage {
  final String text;
  final Map<String, String> vocabularyWords;
  final _DecisionPoint? decisionPoint;
  const _StoryPage({
    required this.text, this.vocabularyWords = const {}, this.decisionPoint,
  });
}

class _DecisionPoint {
  final String question, explanation;
  final List<String> options;
  final int correctIndex;
  const _DecisionPoint({
    required this.question, required this.options,
    required this.correctIndex, required this.explanation,
  });
}

class _ComprehensionQ {
  final String question;
  final List<String> options;
  final int correctIndex;
  const _ComprehensionQ({
    required this.question, required this.options, required this.correctIndex,
  });
}
