import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/skill_radar_chart.dart';

/// Practice History and Metrics tracking view.
class PracticeHistoryScreen extends StatelessWidget {
  const PracticeHistoryScreen({super.key});

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
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            SliverToBoxAdapter(child: _buildStatsGrid(context, progress, isDark)),
            SliverToBoxAdapter(child: _buildSectionTitle('Skill Mastery Metrics', isDark)),
            SliverToBoxAdapter(child: _buildSkillRadar(progress)),
            SliverToBoxAdapter(child: _buildSectionTitle('Recent Activity', isDark)),
            _buildRecentSessions(progress.recentTopics, isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
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
            child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Practice History',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Track your learning journey',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, var progress, bool isDark) {
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
                  value: progress.streak.toString(),
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
              Text(title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSkillRadar(var progress) {
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

  Widget _buildRecentSessions(List<String> recentSessions, bool isDark) {
    if (recentSessions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'No recent activity recorded yet.',
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final topic = recentSessions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 20, right: 20),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Practiced Topic',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(topic,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: recentSessions.length > 5 ? 5 : recentSessions.length, // Limit to 5
      ),
    );
  }
}
