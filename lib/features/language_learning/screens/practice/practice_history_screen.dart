import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../shared/models/activity_entry.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/user_progress_model.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/skill_radar_chart.dart';

/// Practice History and Metrics tracking view.
///
/// Displays:
///   1. Stats grid (XP, streak, level, lessons)
///   2. Skill radar chart
///   3. Recent activity list from [AppProvider.user.activityLog]
///
/// Handles loading, empty, and error states gracefully.
class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final progressProvider = context.read<ProgressProvider>();
      await progressProvider.loadProgress();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load practice history: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isDark)
            : _error != null
                ? _buildErrorState(isDark)
                : _buildContent(isDark),
      ),
    );
  }

  // ─── Loading State ──────────────────────────────────────────────

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: [
        _buildAppBar(isDark),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Loading practice history...',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Error State ────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return Column(
      children: [
        _buildAppBar(isDark),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Something went wrong',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'An unknown error occurred.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadData();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Main Content ───────────────────────────────────────────────

  Widget _buildContent(bool isDark) {
    final progressProvider = context.watch<ProgressProvider>();
    final appProvider = context.watch<AppProvider>();
    final progress = progressProvider.userProgress;
    final activityLog = appProvider.user.activityLog;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildAppBar(isDark)),
        SliverToBoxAdapter(
          child: _buildStatsGrid(progress, isDark),
        ),
        SliverToBoxAdapter(
          child: _buildSectionTitle('Skill Mastery Metrics', isDark),
        ),
        SliverToBoxAdapter(child: _buildSkillRadar(progress)),
        SliverToBoxAdapter(
          child: _buildSectionTitle('Recent Activity', isDark),
        ),
        _buildActivityList(activityLog, isDark),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
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
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_rounded,
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
                  'Practice History',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                Text(
                  'Track your learning journey',
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

  // ─── Stats Grid ─────────────────────────────────────────────────

  Widget _buildStatsGrid(UserProgress progress, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total XP',
                  value: progress.totalXp.toString(),
                  icon: Icons.flash_on_rounded,
                  color: AppColors.xpColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Day Streak',
                  value: progress.streak.currentStreak.toString(),
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFF97316),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Level',
                  value: progress.currentLevel.name.toUpperCase(),
                  icon: Icons.military_tech_rounded,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Lessons Done',
                  value: '${progress.contentHistory.length}',
                  icon: Icons.library_books_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      borderColor: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────────

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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

  // ─── Skill Radar ────────────────────────────────────────────────

  Widget _buildSkillRadar(UserProgress progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: SizedBox(
          height: 250,
          child: SkillRadarChart(
            grammar: progress.skills.grammar.currentScore,
            pronunciation: progress.skills.pronunciation.currentScore,
            spelling: progress.skills.spelling.currentScore,
            reading: progress.skills.reading.currentScore,
            writing: progress.skills.writing.currentScore,
            listening: progress.skills.listening.currentScore,
            speaking: progress.skills.speaking.currentScore,
          ),
        ),
      ),
    );
  }

  // ─── Activity List (from AppProvider) ───────────────────────────

  Widget _buildActivityList(List<ActivityEntry> activities, bool isDark) {
    if (activities.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No practice history found',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start a session to see your activity here!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = activities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 20, right: 20),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getActivityColor(entry.type).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getActivityIcon(entry.type),
                      color: _getActivityColor(entry.type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title.isNotEmpty ? entry.title : entry.type.label,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.lightText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.detail ?? entry.type.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (entry.xpEarned > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.xpColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${entry.xpEarned} XP',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.xpColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        entry.relativeTime,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: activities.length > 50 ? 50 : activities.length,
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.codeReview:
        return Icons.code_rounded;
      case ActivityType.lesson:
        return Icons.school_rounded;
      case ActivityType.ielts:
        return Icons.workspace_premium_rounded;
      case ActivityType.mentorChat:
        return Icons.chat_bubble_rounded;
      case ActivityType.practice:
        return Icons.fitness_center_rounded;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.codeReview:
        return AppColors.primary;
      case ActivityType.lesson:
        return AppColors.accentGreen;
      case ActivityType.ielts:
        return const Color(0xFF8B5CF6);
      case ActivityType.mentorChat:
        return AppColors.info;
      case ActivityType.practice:
        return const Color(0xFFF97316);
    }
  }
}
