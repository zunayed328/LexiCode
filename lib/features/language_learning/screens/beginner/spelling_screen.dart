import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../services/speech_service.dart';
import '../../widgets/tts_controls.dart';
import '../../widgets/score_reveal.dart';

enum SpellingMode { listenAndSpell, fillMissing, spellingBee }

/// Interactive spelling practice with listen & spell, fill missing, and spelling bee modes.
class SpellingScreen extends StatefulWidget {
  final SpellingMode mode;
  const SpellingScreen({super.key, required this.mode});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  final SpeechService _speechService = SpeechService();
  final TextEditingController _inputController = TextEditingController();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _showResults = false;
  final List<_SpellResult> _results = [];
  late List<_SpellWord> _words;

  @override
  void initState() {
    super.initState();
    _words = _generateWords();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  List<_SpellWord> _generateWords() {
    return [
      _SpellWord(
        'necessary',
        '/ˈnes.ə.ser.i/',
        'Needed or required',
        'It is necessary to study every day.',
        'neccessary',
      ),
      _SpellWord(
        'accommodate',
        '/əˈkɒm.ə.deɪt/',
        'Provide lodging or room',
        'The hotel can accommodate 200 guests.',
        'accomodate',
      ),
      _SpellWord(
        'separate',
        '/ˈsep.ər.ət/',
        'Set apart from each other',
        'Please separate the colors from whites.',
        'seperate',
      ),
      _SpellWord(
        'definitely',
        '/ˈdef.ɪ.nət.li/',
        'Without any doubt',
        'I will definitely be there.',
        'definately',
      ),
      _SpellWord(
        'occurred',
        '/əˈkɜːd/',
        'Happened or took place',
        'The accident occurred yesterday.',
        'occured',
      ),
      _SpellWord(
        'receive',
        '/rɪˈsiːv/',
        'Get or be given something',
        'Did you receive my email?',
        'recieve',
      ),
      _SpellWord(
        'beginning',
        '/bɪˈɡɪn.ɪŋ/',
        'The start of something',
        'This is only the beginning.',
        'begining',
      ),
      _SpellWord(
        'believe',
        '/bɪˈliːv/',
        'Accept as true',
        'I believe in your ability.',
        'beleive',
      ),
      _SpellWord(
        'disappear',
        '/ˌdɪs.əˈpɪər/',
        'Cease to be visible',
        'The sun disappeared behind clouds.',
        'dissapear',
      ),
      _SpellWord(
        'knowledge',
        '/ˈnɒl.ɪdʒ/',
        'Information and understanding',
        'Knowledge is power.',
        'knowlege',
      ),
      _SpellWord(
        'apparently',
        '/əˈpær.ənt.li/',
        'As far as one knows',
        'Apparently, the meeting is canceled.',
        'apparantly',
      ),
      _SpellWord(
        'temperature',
        '/ˈtem.prə.tʃər/',
        'Degree of heat',
        'The temperature is dropping.',
        'temprature',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showResults) return _buildResults(isDark);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            _buildProgress(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildExercise(isDark),
              ),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    String title;
    switch (widget.mode) {
      case SpellingMode.listenAndSpell:
        title = 'Listen & Spell';
      case SpellingMode.fillMissing:
        title = 'Fill Missing Letters';
      case SpellingMode.spellingBee:
        title = 'Spelling Bee';
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
            '${_currentIndex + 1}/${_words.length}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
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
        child: LinearProgressIndicator(
          value: (_currentIndex + 1) / _words.length,
          minHeight: 8,
          backgroundColor: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
        ),
      ),
    );
  }

  Widget _buildExercise(bool isDark) {
    final word = _words[_currentIndex];

    switch (widget.mode) {
      case SpellingMode.listenAndSpell:
        return _buildListenAndSpell(isDark, word);
      case SpellingMode.fillMissing:
        return _buildFillMissing(isDark, word);
      case SpellingMode.spellingBee:
        return _buildSpellingBee(isDark, word);
    }
  }

  Widget _buildListenAndSpell(bool isDark, _SpellWord word) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Listen card
        GlassCard(
          borderColor: AppColors.info.withValues(alpha: 0.2),
          child: Column(
            children: [
              Icon(
                Icons.hearing_rounded,
                size: 48,
                color: AppColors.info.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Listen to the word and spell it',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 16),
              TtsControls(
                text: word.word,
                speechService: _speechService,
                accentColor: AppColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Definition hint
        Text(
          'Definition: ${word.definition}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Input
        TextField(
          controller: _inputController,
          enabled: !_showAnswer,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
          decoration: InputDecoration(
            hintText: 'Type the word...',
            hintStyle: GoogleFonts.inter(fontSize: 18, letterSpacing: 1),
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _showAnswer
                    ? (_results.isNotEmpty && _results.last.isCorrect
                          ? AppColors.success
                          : AppColors.error)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 2,
              ),
            ),
          ),
          onSubmitted: (_) => _checkSpelling(),
        ),
        // Feedback
        if (_showAnswer) ...[
          const SizedBox(height: 16),
          _buildSpellingFeedback(isDark, word),
        ],
      ],
    );
  }

  Widget _buildFillMissing(bool isDark, _SpellWord word) {
    final masked = _maskWord(word.word);

    return Column(
      children: [
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              Text(
                'Fill in the missing letters',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                masked,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                word.definition,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '📝 ${word.example}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _inputController,
          enabled: !_showAnswer,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
          decoration: InputDecoration(
            hintText: 'Complete the word...',
            hintStyle: GoogleFonts.inter(fontSize: 18),
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (_) => _checkSpelling(),
        ),
        if (_showAnswer) ...[
          const SizedBox(height: 16),
          _buildSpellingFeedback(isDark, word),
        ],
      ],
    );
  }

  Widget _buildSpellingBee(bool isDark, _SpellWord word) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentIndex < 4
                  ? [AppColors.success, const Color(0xFF059669)]
                  : _currentIndex < 8
                  ? [AppColors.warning, const Color(0xFFD97706)]
                  : [AppColors.error, const Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _currentIndex < 4
                ? 'Easy'
                : _currentIndex < 8
                ? 'Medium'
                : 'Hard',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: AppColors.xpColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Spelling Bee Challenge',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // Definition
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Definition:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.definition,
                      style: GoogleFonts.inter(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.example,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TtsControls(
                text: word.word,
                speechService: _speechService,
                compact: true,
                accentColor: AppColors.xpColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _inputController,
          enabled: !_showAnswer,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
          decoration: InputDecoration(
            hintText: 'Spell the word...',
            hintStyle: GoogleFonts.inter(fontSize: 18),
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (_) => _checkSpelling(),
        ),
        if (_showAnswer) ...[
          const SizedBox(height: 16),
          _buildSpellingFeedback(isDark, word),
        ],
      ],
    );
  }

  String _maskWord(String word) {
    final chars = word.split('');
    // Remove ~40% of vowels and some consonants
    final vowels = {'a', 'e', 'i', 'o', 'u'};
    int removed = 0;
    final target = (chars.length * 0.4).ceil();
    for (int i = 1; i < chars.length - 1 && removed < target; i++) {
      if (vowels.contains(chars[i].toLowerCase()) || i % 3 == 0) {
        chars[i] = '_';
        removed++;
      }
    }
    return chars.join('');
  }

  void _checkSpelling() {
    final userInput = _inputController.text.trim().toLowerCase();
    final correct = _words[_currentIndex].word.toLowerCase();
    final isCorrect = userInput == correct;

    setState(() {
      _results.add(
        _SpellResult(
          word: _words[_currentIndex].word,
          userInput: _inputController.text.trim(),
          isCorrect: isCorrect,
        ),
      );
      _showAnswer = true;
    });
  }

  Widget _buildSpellingFeedback(bool isDark, _SpellWord word) {
    final result = _results.last;
    final color = result.isCorrect ? AppColors.success : AppColors.error;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                result.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isCorrect ? 'Correct! 🎉' : 'Not quite!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (result.isCorrect)
                Text(
                  '+10 XP',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.xpColor,
                  ),
                ),
            ],
          ),
          if (!result.isCorrect) ...[
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                children: [
                  const TextSpan(text: 'Correct spelling: '),
                  TextSpan(
                    text: word.word,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Common misspelling: ${word.commonMisspelling}',
              style: GoogleFonts.inter(
                fontSize: 12,
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

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (!_showAnswer)
            Expanded(
              child: ElevatedButton(
                onPressed: _inputController.text.isNotEmpty
                    ? _checkSpelling
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Check',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_showAnswer)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_currentIndex < _words.length - 1) {
                    setState(() {
                      _currentIndex++;
                      _showAnswer = false;
                      _inputController.clear();
                    });
                  } else {
                    setState(() => _showResults = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _currentIndex < _words.length - 1
                      ? 'Next Word'
                      : 'See Results',
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

  Widget _buildResults(bool isDark) {
    final correct = _results.where((r) => r.isCorrect).length;
    final score = _results.isNotEmpty ? (correct / _results.length * 100) : 0.0;

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
                label: 'Spelling Practice',
                subtitle: '$correct/${_results.length} words correct',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
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

class _SpellWord {
  final String word, phonetic, definition, example, commonMisspelling;
  const _SpellWord(
    this.word,
    this.phonetic,
    this.definition,
    this.example,
    this.commonMisspelling,
  );
}

class _SpellResult {
  final String word, userInput;
  final bool isCorrect;
  const _SpellResult({
    required this.word,
    required this.userInput,
    required this.isCorrect,
  });
}
