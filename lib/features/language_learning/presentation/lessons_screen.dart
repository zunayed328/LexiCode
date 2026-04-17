import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/lesson_model.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final units = provider.lessonUnits;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(provider, isDark)),
            SliverToBoxAdapter(child: _buildProficiencyBadge(provider, isDark)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildUnit(context, units[i], isDark),
                ),
                childCount: units.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accentGreen, Color(0xFF38A802)]),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Learn English', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
            Text('Tech-focused language lessons',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Text('${provider.user.lessonsCompleted} done', style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildProficiencyBadge(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GlassCard(
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(provider.user.proficiencyLevel,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current Level: ${provider.user.proficiencyLevel}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              LinearPercentIndicator(
                lineHeight: 6, percent: 0.45, padding: EdgeInsets.zero,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                linearGradient: AppColors.primaryGradient, barRadius: const Radius.circular(3),
              ),
              const SizedBox(height: 4),
              Text('45% to B2 level', style: TextStyle(fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildUnit(BuildContext context, LessonUnitModel unit, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: unit.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(unit.icon, color: unit.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Unit ${unit.unitNumber}: ${unit.title}',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(unit.description,
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: unit.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${(unit.progress * 100).toInt()}%',
                  style: TextStyle(color: unit.color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Lessons in unit
        ...unit.lessons.map((lesson) => _buildLessonTile(context, lesson, isDark)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLessonTile(BuildContext context, LessonModel lesson, bool isDark) {
    return Opacity(
      opacity: lesson.isLocked ? 0.5 : 1.0,
      child: GlassCard(
        onTap: lesson.isLocked
            ? null
            : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LessonDetailScreen(lesson: lesson))),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: lesson.isCompleted
                  ? LinearGradient(colors: [lesson.color, lesson.color.withValues(alpha: 0.7)])
                  : null,
              color: lesson.isCompleted ? null : lesson.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              lesson.isLocked ? Icons.lock_rounded : (lesson.isCompleted ? Icons.check_rounded : lesson.icon),
              color: lesson.isCompleted ? Colors.white : lesson.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(lesson.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lesson.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(lesson.difficultyLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lesson.color)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(lesson.description,
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              if (lesson.progress > 0 && !lesson.isCompleted) ...[
                const SizedBox(height: 6),
                LinearPercentIndicator(
                  lineHeight: 4, percent: lesson.progress, padding: EdgeInsets.zero,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  progressColor: lesson.color, barRadius: const Radius.circular(2),
                ),
              ],
            ]),
          ),
          Column(children: [
            Text('+${lesson.xpReward}', style: const TextStyle(color: AppColors.xpColor, fontSize: 12, fontWeight: FontWeight.w700)),
            const Text('XP', style: TextStyle(fontSize: 10, color: AppColors.xpColor)),
          ]),
        ]),
      ),
    );
  }
}
