import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/user_progress_model.dart';
import '../providers/learning_provider.dart';
import '../providers/progress_provider.dart';
import 'beginner/beginner_dashboard.dart';
import 'intermediate/intermediate_dashboard.dart';
import 'advanced/advanced_dashboard.dart';
import 'suggestions/ai_suggestions_screen.dart';
import 'practice/daily_practice_screen.dart';
import 'practice/weekly_challenge_screen.dart';
import 'practice/practice_history_screen.dart';

/// Premium learning home screen with level selection, progress, and quick actions.
class LearningHomeScreen extends StatefulWidget {
  const LearningHomeScreen({super.key});

  @override
  State<LearningHomeScreen> createState() => _LearningHomeScreenState();
}

class _LearningHomeScreenState extends State<LearningHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().initialize();
      context.read<ProgressProvider>().loadProgress();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final learningProvider = context.watch<LearningProvider>();
    final progressProvider = context.watch<ProgressProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(isDark, learningProvider)),
            // Motivational Hero
            SliverToBoxAdapter(
                child: _buildMotivationCard(isDark, learningProvider)),
            // Progress Overview
            SliverToBoxAdapter(
                child: _buildProgressOverview(isDark, progressProvider)),
            // Level Selection
            SliverToBoxAdapter(child: _buildLevelSection(isDark)),
            // Level Cards
            SliverToBoxAdapter(
                child: _buildLevelCards(isDark, learningProvider)),
            // Quick Actions
            SliverToBoxAdapter(child: _buildQuickActions(isDark)),
            // Recent Activity
            SliverToBoxAdapter(
                child: _buildRecentActivity(isDark, progressProvider)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, LearningProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'English Learning',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                Text(
                  'AI-Powered Language Mastery',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.xpColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${provider.userProgress.streak.currentStreak}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(bool isDark, LearningProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: GlassCard(
        borderColor: AppColors.accentGreen.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: provider.isLoadingMotivation
                  ? _buildShimmerText()
                  : Text(
                      provider.dailyMotivation,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressOverview(bool isDark, ProgressProvider provider) {
    final progress = provider.userProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📊 Your Progress',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    provider.cefrLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  '${progress.totalXp}',
                  'Total XP',
                  AppColors.xpColor,
                  Icons.star_rounded,
                  isDark,
                ),
                _buildStatItem(
                  '${progress.totalLessonsCompleted}',
                  'Lessons',
                  AppColors.accentGreen,
                  Icons.school_rounded,
                  isDark,
                ),
                _buildStatItem(
                  '${progress.totalExercisesCompleted}',
                  'Exercises',
                  AppColors.primary,
                  Icons.fitness_center_rounded,
                  isDark,
                ),
                _buildStatItem(
                  '${progress.vocabularyMastered}',
                  'Words',
                  AppColors.info,
                  Icons.abc_rounded,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Daily goals progress
            _buildDailyGoalRow(
                'Grammar', progress.dailyGoal.grammarLessonsCompleted,
                progress.dailyGoal.grammarLessonsTarget,
                AppColors.accentGreen, isDark),
            const SizedBox(height: 6),
            _buildDailyGoalRow(
                'Pronunciation', progress.dailyGoal.pronunciationMinutesCompleted,
                progress.dailyGoal.pronunciationMinutesTarget,
                AppColors.info, isDark),
            const SizedBox(height: 6),
            _buildDailyGoalRow(
                'Spelling', progress.dailyGoal.spellingWordsCompleted,
                progress.dailyGoal.spellingWordsTarget,
                AppColors.primary, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalRow(
      String label, int current, int target, Color color, bool isDark) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: progress >= 1.0 ? AppColors.success : color,
          ),
        ),
        if (progress >= 1.0) ...[
          const SizedBox(width: 4),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 14),
        ],
      ],
    );
  }

  Widget _buildLevelSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'Learning Levels',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.lightText,
        ),
      ),
    );
  }

  Widget _buildLevelCards(bool isDark, LearningProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _LevelCard(
            level: LearningLevel.beginner,
            title: 'Beginner',
            subtitle: 'Grammar, Pronunciation, Spelling',
            description:
                'Master English fundamentals with AI-powered lessons',
            icon: Icons.school_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            cefrTag: 'A1–A2',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BeginnerDashboard()),
            ),
          ),
          _LevelCard(
            level: LearningLevel.intermediate,
            title: 'Intermediate',
            subtitle: 'Reading, Writing, Practice',
            description:
                'Duolingo-style exercises that adapt to your level',
            icon: Icons.trending_up_rounded,
            gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            cefrTag: 'B1–B2',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const IntermediateDashboard()),
            ),
          ),
          _LevelCard(
            level: LearningLevel.advanced,
            title: 'Advanced',
            subtitle: 'IELTS-Style Exam & Assessment',
            description: 'Full listening, reading, writing, speaking tests',
            icon: Icons.workspace_premium_rounded,
            gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            cefrTag: 'C1–C2',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdvancedDashboard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'AI Suggestions',
                  subtitle: 'Personal roadmap',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AiSuggestionsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  title: 'Daily Practice',
                  subtitle: 'Today\'s session',
                  icon: Icons.today_rounded,
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DailyPracticeScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Weekly Challenge',
                  subtitle: 'Test your skills',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WeeklyChallengeScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  title: 'Practice History',
                  subtitle: 'View progress metrics',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PracticeHistoryScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark, ProgressProvider provider) {
    final progress = provider.userProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills Overview',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          // Skill bars
          _buildSkillBar('Grammar', progress.skills.grammar.currentScore,
              AppColors.accentGreen, isDark),
          _buildSkillBar('Pronunciation',
              progress.skills.pronunciation.currentScore, AppColors.info, isDark),
          _buildSkillBar('Spelling', progress.skills.spelling.currentScore,
              AppColors.primary, isDark),
          _buildSkillBar('Reading', progress.skills.reading.currentScore,
              const Color(0xFF10B981), isDark),
          _buildSkillBar('Writing', progress.skills.writing.currentScore,
              AppColors.secondary, isDark),
          _buildSkillBar('Listening', progress.skills.listening.currentScore,
              const Color(0xFF8B5CF6), isDark),
          _buildSkillBar('Speaking', progress.skills.speaking.currentScore,
              const Color(0xFFF59E0B), isDark),
        ],
      ),
    );
  }

  Widget _buildSkillBar(
      String skill, double score, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              skill,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    valueColor: AlwaysStoppedAnimation(color),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${score.toInt()}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Level Card Widget ────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final LearningLevel level;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String cefrTag;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.cefrTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cefrTag,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withValues(alpha: 0.8)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
