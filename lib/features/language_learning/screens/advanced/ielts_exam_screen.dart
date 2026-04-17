import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/tts_controls.dart';
import '../../widgets/stt_recorder.dart';
import 'exam_result_screen.dart';

/// IELTS exam screen with section navigation and timed completion.
class IeltsExamScreen extends StatefulWidget {
  final bool fullExam;
  final String? singleSection;

  const IeltsExamScreen({
    super.key,
    required this.fullExam,
    this.singleSection,
  });

  @override
  State<IeltsExamScreen> createState() => _IeltsExamScreenState();
}

class _IeltsExamScreenState extends State<IeltsExamScreen> {
  int _currentSection = 0;
  int _currentQuestion = 0;
  final Map<String, String> _answers = {};
  final TextEditingController _writingController = TextEditingController();
  late List<_IeltsSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = widget.fullExam
        ? _buildAllSections()
        : [_buildSection(widget.singleSection ?? 'listening')];
  }

  @override
  void dispose() {
    _writingController.dispose();
    super.dispose();
  }

  List<_IeltsSection> _buildAllSections() {
    return [
      _buildSection('listening'),
      _buildSection('reading'),
      _buildSection('writing'),
      _buildSection('speaking'),
    ];
  }

  _IeltsSection _buildSection(String type) {
    switch (type) {
      case 'listening':
        return _IeltsSection(
          title: 'Listening',
          icon: Icons.headphones_rounded,
          color: const Color(0xFF3B82F6),
          timerSeconds: 30 * 60,
          questions: [
            _IeltsQuestion(
              type: IeltsQuestionType.mcq,
              text:
                  'Listen to the conversation and answer: What is the main purpose of the speaker\'s visit?',
              audioText:
                  'Good morning. I\'m here to discuss the quarterly budget review. I\'ve prepared some figures that show our spending patterns over the last three months, and I\'d like to suggest some changes to our allocation strategy.',
              options: [
                'To request a budget increase',
                'To discuss quarterly budget review',
                'To introduce a new team member',
                'To announce a policy change',
              ],
              correctAnswer: 'To discuss quarterly budget review',
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.fillBlank,
              text:
                  'Complete the note: The speaker prepared _____ showing spending patterns.',
              audioText:
                  'Good morning. I\'m here to discuss the quarterly budget review. I\'ve prepared some figures that show our spending patterns over the last three months.',
              correctAnswer: 'figures',
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.mcq,
              text: 'How long does the spending data cover?',
              options: [
                'One month',
                'Two months',
                'Three months',
                'Six months',
              ],
              correctAnswer: 'Three months',
            ),
          ],
        );
      case 'reading':
        return _IeltsSection(
          title: 'Reading',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF10B981),
          timerSeconds: 60 * 60,
          passage: '''The Impact of Artificial Intelligence on Modern Education

Artificial intelligence has fundamentally transformed the landscape of modern education, offering both unprecedented opportunities and significant challenges. Machine learning algorithms now power adaptive learning platforms that can adjust difficulty levels in real-time, providing personalized educational experiences that were previously impossible at scale.

Research conducted at MIT in 2024 demonstrated that students using AI-enhanced platforms showed a 34% improvement in test scores compared to traditional methods. However, critics argue that over-reliance on technology may diminish critical thinking skills and reduce the role of human mentors in the educational process.

The integration of natural language processing has enabled sophisticated language learning applications that can assess pronunciation accuracy, provide instant grammar corrections, and generate contextually appropriate practice materials. These tools are particularly valuable for non-native English speakers preparing for standardized tests such as IELTS and TOEFL.

Despite these advances, educational researchers emphasize the importance of maintaining a balanced approach. Dr. Sarah Chen, a leading education technology researcher, notes that "AI should augment, not replace, the human elements of teaching that foster creativity, empathy, and social development."''',
          questions: [
            _IeltsQuestion(
              type: IeltsQuestionType.trueFalse,
              text:
                  'AI-enhanced platforms showed a 34% improvement in test scores.',
              options: ['True', 'False', 'Not Given'],
              correctAnswer: 'True',
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.trueFalse,
              text: 'All critics support the use of AI in education.',
              options: ['True', 'False', 'Not Given'],
              correctAnswer: 'False',
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.mcq,
              text: 'According to Dr. Chen, AI should:',
              options: [
                'Replace traditional teaching entirely',
                'Augment human elements of teaching',
                'Focus only on language learning',
                'Be avoided in education',
              ],
              correctAnswer: 'Augment human elements of teaching',
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.fillBlank,
              text:
                  'NLP has enabled applications that assess pronunciation _____.',
              correctAnswer: 'accuracy',
            ),
          ],
        );
      case 'writing':
        return _IeltsSection(
          title: 'Writing',
          icon: Icons.edit_rounded,
          color: const Color(0xFFF59E0B),
          timerSeconds: 60 * 60,
          questions: [
            _IeltsQuestion(
              type: IeltsQuestionType.writing,
              text:
                  'Task 1 (150+ words): The chart below shows the percentage of students using different learning tools from 2020 to 2025.\n\nOnline Platforms: 35% → 72%\nTextbooks: 60% → 28%\nAI Tutors: 5% → 45%\nVideo Courses: 25% → 55%\n\nSummarize the information by selecting and reporting the main features, and make comparisons where relevant.',
              correctAnswer: '',
              wordTarget: 150,
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.writing,
              text:
                  'Task 2 (250+ words): Some people believe that artificial intelligence will eventually replace human teachers. To what extent do you agree or disagree? Give reasons for your answer and include any relevant examples from your knowledge or experience.',
              correctAnswer: '',
              wordTarget: 250,
            ),
          ],
        );
      case 'speaking':
      default:
        return _IeltsSection(
          title: 'Speaking',
          icon: Icons.mic_rounded,
          color: const Color(0xFFEC4899),
          timerSeconds: 15 * 60,
          questions: [
            _IeltsQuestion(
              type: IeltsQuestionType.speaking,
              text:
                  'Part 1 - Introduction:\nTell me about your experience with learning English. How long have you been studying, and what methods do you find most effective?',
              correctAnswer: '',
              speakingTimeSeconds: 60,
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.speaking,
              text:
                  'Part 2 - Cue Card:\nDescribe a time when technology helped you learn something new.\nYou should say:\n• What you learned\n• What technology you used\n• How it helped you\n• Explain how you felt about the experience',
              correctAnswer: '',
              speakingTimeSeconds: 120,
            ),
            _IeltsQuestion(
              type: IeltsQuestionType.speaking,
              text:
                  'Part 3 - Discussion:\nDo you think AI will change the way people learn languages in the future? What are the advantages and disadvantages?',
              correctAnswer: '',
              speakingTimeSeconds: 120,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final section = _sections[_currentSection];
    final question = section.questions[_currentQuestion];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildExamHeader(isDark, section),
            if (widget.fullExam) _buildSectionTabs(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Passage for reading
                    if (section.passage != null &&
                        section.title == 'Reading') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard.withValues(alpha: 0.5)
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          section.passage!,
                          style: GoogleFonts.inter(fontSize: 14, height: 1.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Question
                    _buildQuestion(isDark, question, section),
                  ],
                ),
              ),
            ),
            _buildBottomBar(isDark, section),
          ],
        ),
      ),
    );
  }

  Widget _buildExamHeader(bool isDark, _IeltsSection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.close_rounded),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(section.icon, color: section.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              section.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Question counter
          Text(
            'Q${_currentQuestion + 1}/${section.questions.length}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: section.color,
            ),
          ),
          const SizedBox(width: 12),
          TimerWidget(
            totalSeconds: section.timerSeconds,
            size: 50,
            color: section.color,
            onTimeUp: () => _finishExam(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: _sections.asMap().entries.map((entry) {
          final idx = entry.key;
          final section = entry.value;
          final isActive = idx == _currentSection;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _currentSection = idx;
                _currentQuestion = 0;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? section.color.withValues(alpha: 0.15)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(color: section.color.withValues(alpha: 0.3))
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      section.icon,
                      size: 18,
                      color: isActive
                          ? section.color
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.title,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive ? section.color : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestion(
    bool isDark,
    _IeltsQuestion question,
    _IeltsSection section,
  ) {
    switch (question.type) {
      case IeltsQuestionType.mcq:
      case IeltsQuestionType.trueFalse:
        return _buildMCQ(isDark, question, section);
      case IeltsQuestionType.fillBlank:
        return _buildFillBlank(isDark, question, section);
      case IeltsQuestionType.writing:
        return _buildWritingTask(isDark, question);
      case IeltsQuestionType.speaking:
        return _buildSpeakingTask(isDark, question);
    }
  }

  Widget _buildMCQ(
    bool isDark,
    _IeltsQuestion question,
    _IeltsSection section,
  ) {
    // TTS for listening
    final hasAudio = question.audioText != null;
    final key = '${_currentSection}_$_currentQuestion';
    final selected = _answers[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAudio) ...[
          TtsControls(text: question.audioText!, accentColor: section.color),
          const SizedBox(height: 20),
        ],
        Text(
          question.text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...question.options!.map((option) {
          final isSelected = selected == option;
          return GestureDetector(
            onTap: () => setState(() => _answers[key] = option),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? section.color.withValues(alpha: 0.1)
                    : (isDark
                          ? AppColors.darkCard.withValues(alpha: 0.5)
                          : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? section.color
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                option,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFillBlank(
    bool isDark,
    _IeltsQuestion question,
    _IeltsSection section,
  ) {
    final key = '${_currentSection}_$_currentQuestion';
    final hasAudio = question.audioText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAudio) ...[
          TtsControls(text: question.audioText!, accentColor: section.color),
          const SizedBox(height: 20),
        ],
        Text(
          question.text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => _answers[key] = v,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Type your answer...',
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
              borderSide: BorderSide(color: section.color, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWritingTask(bool isDark, _IeltsQuestion question) {
    final wordCount = _writingController.text.trim().isEmpty
        ? 0
        : _writingController.text.trim().split(RegExp(r'\s+')).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          child: Text(
            question.text,
            style: GoogleFonts.inter(fontSize: 15, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
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
                controller: _writingController,
                maxLines: 15,
                onChanged: (_) {
                  final key = '${_currentSection}_$_currentQuestion';
                  _answers[key] = _writingController.text;
                  setState(() {});
                },
                style: GoogleFonts.inter(fontSize: 15, height: 1.7),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      '$wordCount words',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: wordCount >= (question.wordTarget ?? 150)
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Target: ${question.wordTarget ?? 150}+ words',
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
      ],
    );
  }

  Widget _buildSpeakingTask(bool isDark, _IeltsQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderColor: const Color(0xFFEC4899).withValues(alpha: 0.2),
          child: Text(
            question.text,
            style: GoogleFonts.inter(fontSize: 15, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),
        SttRecorder(
          accentColor: const Color(0xFFEC4899),
          maxDurationSeconds: question.speakingTimeSeconds ?? 120,
          onResult: (text) {
            final key = '${_currentSection}_$_currentQuestion';
            _answers[key] = text;
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark, _IeltsSection section) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (_currentQuestion > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentQuestion--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentQuestion > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: section.color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _getNextLabel(),
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

  String _getNextLabel() {
    final section = _sections[_currentSection];
    if (_currentQuestion < section.questions.length - 1) return 'Next';
    if (_currentSection < _sections.length - 1) return 'Next Section';
    return 'Submit Exam';
  }

  void _onNext() {
    final section = _sections[_currentSection];
    if (_currentQuestion < section.questions.length - 1) {
      setState(() => _currentQuestion++);
    } else if (_currentSection < _sections.length - 1) {
      setState(() {
        _currentSection++;
        _currentQuestion = 0;
        _writingController.clear();
      });
    } else {
      _finishExam();
    }
  }

  void _finishExam() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ExamResultScreen()),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text('Your progress will be saved.'),
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
}

// ─── Data Models ────────────────────────────────────────────────

enum IeltsQuestionType { mcq, trueFalse, fillBlank, writing, speaking }

class _IeltsSection {
  final String title;
  final IconData icon;
  final Color color;
  final int timerSeconds;
  final List<_IeltsQuestion> questions;
  final String? passage;

  const _IeltsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.timerSeconds,
    required this.questions,
    this.passage,
  });
}

class _IeltsQuestion {
  final IeltsQuestionType type;
  final String text;
  final String? audioText;
  final List<String>? options;
  final String correctAnswer;
  final int? wordTarget;
  final int? speakingTimeSeconds;

  const _IeltsQuestion({
    required this.type,
    required this.text,
    this.audioText,
    this.options,
    required this.correctAnswer,
    this.wordTarget,
    this.speakingTimeSeconds,
  });
}
