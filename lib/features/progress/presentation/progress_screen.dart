import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/services/gamification_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/xp_progress_ring.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isDark)),
            SliverToBoxAdapter(child: _buildLevelCard(user, isDark)),
            SliverToBoxAdapter(child: _buildWeeklyChart(isDark)),
            SliverToBoxAdapter(child: _buildStatsRow(user, isDark)),
            SliverToBoxAdapter(child: _buildAchievements(provider, isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: AppColors.xpColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Text('Progress', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildLevelCard(user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: GlassCard(
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        child: Row(children: [
          XpProgressRing(currentXp: user.xp, maxXp: user.xpForNextLevel, level: user.level, size: 90, lineWidth: 8),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.levelTitle, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Level ${user.level}',
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                _buildSmallStat(Icons.star_rounded, '${user.xp} XP', AppColors.xpColor),
                const SizedBox(width: 16),
                _buildSmallStat(Icons.local_fire_department_rounded, '${user.streak} days', AppColors.streakColor),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildWeeklyChart(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Weekly Activity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('This Week', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 80,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[value.toInt()],
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [45, 60, 35, 70, 50, 25, 40].asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(), width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: e.key == 3 ? AppColors.primaryGradient
                          : LinearGradient(colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.primary.withValues(alpha: 0.15),
                            ]),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(children: [
        Expanded(child: _buildStatBox('📚', '${user.lessonsCompleted}', 'Lessons\nCompleted', AppColors.accentGreen, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatBox('🔍', '${user.codeReviewsCompleted}', 'Code\nReviews', AppColors.primary, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatBox('🏆', '${user.badges.length}', 'Badges\nEarned', AppColors.xpColor, isDark)),
      ]),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label, Color color, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.3, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ]),
    );
  }

  Widget _buildAchievements(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Achievements', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...GamificationService.allAchievements.map((a) {
          final unlocked = a.isUnlocked || provider.user.xp >= a.requiredXp;
          return Opacity(
            opacity: unlocked ? 1.0 : 0.5,
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              borderColor: unlocked ? a.color.withValues(alpha: 0.3) : null,
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: unlocked ? LinearGradient(colors: [a.color, a.color.withValues(alpha: 0.7)]) : null,
                    color: unlocked ? null : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(unlocked ? a.icon : Icons.lock_rounded, color: unlocked ? Colors.white : AppColors.darkTextSecondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(a.description,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ]),
                ),
                if (unlocked)
                  const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 22)
                else
                  Text('${a.requiredXp} XP', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}
