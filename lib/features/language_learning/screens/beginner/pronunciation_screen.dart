import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../services/speech_service.dart';
import '../../widgets/tts_controls.dart';
import '../../widgets/stt_recorder.dart';
import '../../widgets/score_reveal.dart';

enum PronunciationMode { words, sentences, minimalPairs }

/// Pronunciation practice screen with TTS playback, STT recording, and AI feedback.
class PronunciationScreen extends StatefulWidget {
  final PronunciationMode mode;

  const PronunciationScreen({super.key, required this.mode});

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  final SpeechService _speechService = SpeechService();
  int _currentIndex = 0;
  bool _showResults = false;
  final List<_PronResult> _results = [];

  // Sample data — in production, loaded from AI
  late List<_PronItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _generateItems();
  }

  List<_PronItem> _generateItems() {
    switch (widget.mode) {
      case PronunciationMode.words:
        return [
          _PronItem(
            'Comfortable',
            '/ˈkʌmf.tə.bəl/',
            'Not stressed — many syllables',
          ),
          _PronItem('Wednesday', '/ˈwenz.deɪ/', 'Silent "d" in the middle'),
          _PronItem('February', '/ˈfeb.ru.er.i/', 'Don\'t skip the first "r"'),
          _PronItem(
            'Pronunciation',
            '/prəˌnʌn.siˈeɪ.ʃən/',
            'Note: "nun" not "noun"',
          ),
          _PronItem('Colonel', '/ˈkɜː.nəl/', 'Sounds like "kernel"'),
          _PronItem('Receipt', '/rɪˈsiːt/', 'Silent "p"'),
          _PronItem('Entrepreneur', '/ˌɒn.trə.prəˈnɜːr/', 'French origin word'),
          _PronItem('Thoroughly', '/ˈθʌr.ə.li/', 'TH sound + silent "ough"'),
          _PronItem('Vegetable', '/ˈvedʒ.tə.bəl/', 'Three syllables, not four'),
          _PronItem(
            'Archipelago',
            '/ˌɑː.kɪˈpel.ə.ɡəʊ/',
            '"ch" sounds like "k"',
          ),
        ];
      case PronunciationMode.sentences:
        return [
          _PronItem(
            'The weather is nice today.',
            '',
            'Rising intonation for statements',
          ),
          _PronItem(
            'Can you help me, please?',
            '',
            'Rising intonation for questions',
          ),
          _PronItem(
            'I\'ve been studying English for two years.',
            '',
            'Stress on "studying" and "years"',
          ),
          _PronItem(
            'She said she would come tomorrow.',
            '',
            'Connected speech: "she_said"',
          ),
          _PronItem(
            'What are you going to do this weekend?',
            '',
            '"Going to" → "gonna" in casual speech',
          ),
        ];
      case PronunciationMode.minimalPairs:
        return [
          _PronItem(
            'ship / sheep',
            '/ʃɪp/ vs /ʃiːp/',
            'Short "i" vs long "ee"',
          ),
          _PronItem('bit / beat', '/bɪt/ vs /biːt/', 'Short "i" vs long "ee"'),
          _PronItem('pen / pan', '/pen/ vs /pæn/', '"e" vs "a" vowel sound'),
          _PronItem('bat / bet', '/bæt/ vs /bet/', '"a" vs "e" vowel sound'),
          _PronItem('think / sink', '/θɪŋk/ vs /sɪŋk/', 'TH vs S sound'),
          _PronItem('light / right', '/laɪt/ vs /raɪt/', 'L vs R sound'),
          _PronItem('very / berry', '/ˈver.i/ vs /ˈber.i/', 'V vs B sound'),
          _PronItem('fan / van', '/fæn/ vs /væn/', 'F vs V sound'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showResults) return _buildResultsScreen(isDark);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            _buildProgress(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildCurrentItem(isDark),
                    const SizedBox(height: 24),
                    _buildRecordSection(isDark),
                    const SizedBox(height: 20),
                    if (_results.length > _currentIndex)
                      _buildFeedback(isDark, _results[_currentIndex]),
                  ],
                ),
              ),
            ),
            _buildBottomActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    String title;
    switch (widget.mode) {
      case PronunciationMode.words:
        title = 'Word Pronunciation';
      case PronunciationMode.sentences:
        title = 'Sentence Practice';
      case PronunciationMode.minimalPairs:
        title = 'Minimal Pairs';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_currentIndex + 1}/${_items.length}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (_currentIndex + 1) / _items.length),
          duration: const Duration(milliseconds: 400),
          builder: (_, value, _) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.info),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentItem(bool isDark) {
    final item = _items[_currentIndex];

    return GlassCard(
      borderColor: AppColors.info.withValues(alpha: 0.2),
      child: Column(
        children: [
          // Word/Sentence
          Text(
            item.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: widget.mode == PronunciationMode.sentences ? 20 : 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          if (item.phonetic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.phonetic,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            item.hint,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // TTS controls
          TtsControls(
            text: widget.mode == PronunciationMode.minimalPairs
                ? item.text.split(' / ').first
                : item.text,
            speechService: _speechService,
            accentColor: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordSection(bool isDark) {
    return Column(
      children: [
        Text(
          'Now you try!',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 12),
        SttRecorder(
          speechService: _speechService,
          accentColor: AppColors.info,
          maxDurationSeconds: widget.mode == PronunciationMode.sentences
              ? 15
              : 5,
          onResult: (text) {
            _evaluatePronunciation(text);
          },
        ),
      ],
    );
  }

  void _evaluatePronunciation(String spokenText) {
    final expected = widget.mode == PronunciationMode.minimalPairs
        ? _items[_currentIndex].text.split(' / ').first.toLowerCase()
        : _items[_currentIndex].text.toLowerCase();

    final similarity = _calculateSimilarity(
      spokenText.toLowerCase().trim(),
      expected.trim(),
    );
    final score = (similarity * 100).round();

    setState(() {
      if (_results.length > _currentIndex) {
        _results[_currentIndex] = _PronResult(
          spokenText: spokenText,
          score: score,
          feedback: _getFeedback(score),
        );
      } else {
        _results.add(
          _PronResult(
            spokenText: spokenText,
            score: score,
            feedback: _getFeedback(score),
          ),
        );
      }
    });
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final wordsA = a.split(' ');
    final wordsB = b.split(' ');
    int matches = 0;
    for (final word in wordsA) {
      if (wordsB.contains(word)) matches++;
    }
    return matches / wordsB.length;
  }

  String _getFeedback(int score) {
    if (score >= 90) return 'Excellent! Your pronunciation is very clear.';
    if (score >= 70) return 'Good job! Minor improvements needed.';
    if (score >= 50) return 'Keep practicing! Focus on the sounds you missed.';
    return 'Try again! Listen carefully to the example first.';
  }

  Widget _buildFeedback(bool isDark, _PronResult result) {
    final color = result.score >= 70
        ? AppColors.success
        : result.score >= 50
        ? AppColors.warning
        : AppColors.error;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${result.score}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${result.score}/100',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      result.feedback,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.spokenText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'You said: "${result.spokenText}"',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentIndex--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentIndex < _items.length - 1) {
                  setState(() => _currentIndex++);
                } else {
                  setState(() => _showResults = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _currentIndex < _items.length - 1 ? 'Next' : 'See Results',
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

  Widget _buildResultsScreen(bool isDark) {
    final avgScore = _results.isEmpty
        ? 0.0
        : _results.fold<int>(0, (sum, r) => sum + r.score) / _results.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              ScoreReveal(
                score: avgScore,
                maxScore: 100,
                label: 'Pronunciation Practice',
                subtitle: '${_results.length}/${_items.length} words attempted',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back to Dashboard',
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

class _PronItem {
  final String text, phonetic, hint;
  const _PronItem(this.text, this.phonetic, this.hint);
}

class _PronResult {
  final String spokenText;
  final int score;
  final String feedback;
  const _PronResult({
    required this.spokenText,
    required this.score,
    required this.feedback,
  });
}
