import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/user_progress_model.dart';
import '../../providers/learning_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/lesson_card.dart';
import 'grammar_lesson_screen.dart';
import 'pronunciation_screen.dart';
import 'spelling_screen.dart';

/// Beginner dashboard with Grammar, Pronunciation, and Spelling sections.
class BeginnerDashboard extends StatelessWidget {
  const BeginnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressProvider = context.watch<ProgressProvider>();
    final progress = progressProvider.userProgress;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App bar
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            // Daily Goals
            SliverToBoxAdapter(child: _buildDailyGoals(isDark, progress)),
            // Grammar Section
            SliverToBoxAdapter(
              child: _buildSectionHeader('📖 Grammar Basics', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildGrammarSection(context, isDark, progress),
            ),
            // Pronunciation Section
            SliverToBoxAdapter(
              child: _buildSectionHeader('🎤 Pronunciation Practice', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildPronunciationSection(context, isDark),
            ),
            // Spelling Section
            SliverToBoxAdapter(
              child: _buildSectionHeader('✏️ Spelling Practice', isDark),
            ),
            SliverToBoxAdapter(child: _buildSpellingSection(context, isDark)),
            // Badges
            SliverToBoxAdapter(child: _buildBadgesSection(isDark, progress)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beginner Level',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                Text(
                  'A1–A2 • Grammar, Pronunciation, Spelling',
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
    );
  }

  Widget _buildDailyGoals(bool isDark, UserProgress progress) {
    final goal = progress.dailyGoal;
    final grammarDone =
        goal.grammarLessonsCompleted >= goal.grammarLessonsTarget;
    final pronDone =
        goal.pronunciationMinutesCompleted >= goal.pronunciationMinutesTarget;
    final spellDone = goal.spellingWordsCompleted >= goal.spellingWordsTarget;
    final allDone = grammarDone && pronDone && spellDone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: GlassCard(
        borderColor: allDone ? AppColors.success.withValues(alpha: 0.3) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  allDone ? '🎉 Daily Goals Complete!' : '🎯 Daily Goals',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: allDone ? AppColors.success : null,
                  ),
                ),
                const Spacer(),
                if (allDone)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _GoalRow(
              label: 'Grammar Lessons',
              current: goal.grammarLessonsCompleted,
              target: goal.grammarLessonsTarget,
              color: AppColors.accentGreen,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _GoalRow(
              label: 'Pronunciation (min)',
              current: goal.pronunciationMinutesCompleted,
              target: goal.pronunciationMinutesTarget,
              color: AppColors.info,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _GoalRow(
              label: 'Spelling Words',
              current: goal.spellingWordsCompleted,
              target: goal.spellingWordsTarget,
              color: AppColors.primary,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.lightText,
        ),
      ),
    );
  }

  Widget _buildGrammarSection(
    BuildContext context,
    bool isDark,
    UserProgress progress,
  ) {
    final topics = [
      _TopicInfo(
        'Parts of Speech',
        'Nouns, Verbs, Adjectives',
        Icons.category_rounded,
      ),
      _TopicInfo(
        'Sentence Structure',
        'Subject-Verb-Object',
        Icons.reorder_rounded,
      ),
      _TopicInfo(
        'Present Tense',
        'Simple present actions',
        Icons.today_rounded,
      ),
      _TopicInfo('Past Tense', 'Talking about the past', Icons.history_rounded),
      _TopicInfo(
        'Future Tense',
        'Plans and predictions',
        Icons.upcoming_rounded,
      ),
      _TopicInfo('Articles', 'A, An, The usage', Icons.article_rounded),
      _TopicInfo('Pronouns', 'I, You, He, She...', Icons.person_rounded),
      _TopicInfo('Prepositions', 'In, On, At, etc.', Icons.place_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: topics.map((topic) {
          return LessonCard(
            title: topic.title,
            subtitle: topic.subtitle,
            icon: topic.icon,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            badge: 'A1',
            xpReward: 20,
            timeEstimate: '15 min',
            onTap: () {
              context.read<LearningProvider>().selectLevel(
                LearningLevel.beginner,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GrammarLessonScreen(topic: topic.title),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPronunciationSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          LessonCard(
            title: 'Word Pronunciation',
            subtitle: 'Listen, record, and improve',
            icon: Icons.record_voice_over_rounded,
            gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            badge: 'Practice',
            xpReward: 15,
            timeEstimate: '10 min',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PronunciationScreen(mode: PronunciationMode.words),
              ),
            ),
          ),
          LessonCard(
            title: 'Sentence Pronunciation',
            subtitle: 'Intonation and rhythm',
            icon: Icons.short_text_rounded,
            gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            badge: 'Practice',
            xpReward: 15,
            timeEstimate: '10 min',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PronunciationScreen(
                  mode: PronunciationMode.sentences,
                ),
              ),
            ),
          ),
          LessonCard(
            title: 'Minimal Pairs',
            subtitle: 'ship/sheep, bit/beat...',
            icon: Icons.compare_arrows_rounded,
            gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            badge: 'Challenge',
            xpReward: 20,
            timeEstimate: '10 min',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PronunciationScreen(
                  mode: PronunciationMode.minimalPairs,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellingSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          LessonCard(
            title: 'Listen & Spell',
            subtitle: 'Hear the word, type the spelling',
            icon: Icons.hearing_rounded,
            gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
            badge: 'Game',
            xpReward: 15,
            timeEstimate: '10 min',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const SpellingScreen(mode: SpellingMode.listenAndSpell),
              ),
            ),
          ),
          LessonCard(
            title: 'Fill Missing Letters',
            subtitle: 'h_pp_n → happen',
            icon: Icons.text_fields_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            badge: 'Game',
            xpReward: 15,
            timeEstimate: '10 min',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const SpellingScreen(mode: SpellingMode.fillMissing),
              ),
            ),
          ),
          LessonCard(
            title: 'Spelling Bee',
            subtitle: 'Progressive difficulty challenge',
            icon: Icons.emoji_events_rounded,
            gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            badge: 'Challenge',
            xpReward: 25,
            timeEstimate: '15 min',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const SpellingScreen(mode: SpellingMode.spellingBee),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(bool isDark, UserProgress progress) {
    final badges = [
      _BadgeInfo(
        'First Lesson',
        Icons.school_rounded,
        AppColors.accentGreen,
        progress.totalLessonsCompleted >= 1,
      ),
      _BadgeInfo(
        '7-Day Streak',
        Icons.local_fire_department_rounded,
        AppColors.streakColor,
        progress.streak.currentStreak >= 7,
      ),
      _BadgeInfo(
        'Grammar Pro',
        Icons.menu_book_rounded,
        AppColors.primary,
        progress.skills.grammar.currentScore >= 70,
      ),
      _BadgeInfo(
        'Pronunciation',
        Icons.mic_rounded,
        AppColors.info,
        progress.skills.pronunciation.currentScore >= 70,
      ),
      _BadgeInfo(
        'Spelling Champ',
        Icons.spellcheck_rounded,
        AppColors.secondary,
        progress.skills.spelling.currentScore >= 70,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏅 Badges',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: badges.map((badge) {
              return Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: badge.unlocked
                      ? badge.color.withValues(alpha: 0.12)
                      : (isDark
                            ? AppColors.darkCard.withValues(alpha: 0.5)
                            : AppColors.lightBackground),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badge.unlocked
                        ? badge.color.withValues(alpha: 0.3)
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      badge.icon,
                      color: badge.unlocked
                          ? badge.color
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badge.unlocked
                            ? badge.color
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;
  final bool isDark;

  const _GoalRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$target',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: progress >= 1 ? AppColors.success : color,
          ),
        ),
      ],
    );
  }
}

class _TopicInfo {
  final String title, subtitle;
  final IconData icon;
  const _TopicInfo(this.title, this.subtitle, this.icon);
}

class _BadgeInfo {
  final String label;
  final IconData icon;
  final Color color;
  final bool unlocked;
  const _BadgeInfo(this.label, this.icon, this.color, this.unlocked);
}
