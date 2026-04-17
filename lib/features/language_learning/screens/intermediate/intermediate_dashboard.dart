import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

import '../../providers/progress_provider.dart';
import 'mcq_practice_screen.dart';
import 'fill_blanks_screen.dart';
import 'story_practice_screen.dart';
import 'reading_practice_screen.dart';
import 'writing_practice_screen.dart';
import '../beginner/pronunciation_screen.dart';

/// Intermediate practice selection screen with 6 practice categories.
class IntermediateDashboard extends StatelessWidget {
  const IntermediateDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressProvider = context.watch<ProgressProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            SliverToBoxAdapter(child: _buildDailySuggestion(isDark)),
            SliverToBoxAdapter(
                child: _buildSectionTitle('Practice Categories', isDark)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                childAspectRatio: 0.88,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _PracticeCard(
                    title: 'Grammar\nPractice',
                    subtitle: 'MCQ & rules',
                    icon: Icons.check_circle_outline_rounded,
                    gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue
                    timeEstimate: '10 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const McqPracticeScreen()),
                    ),
                  ),
                  _PracticeCard(
                    title: 'Fill in the\nBlanks',
                    subtitle: 'Contextual vocab',
                    icon: Icons.text_fields_rounded,
                    gradient: const [Color(0xFF14B8A6), Color(0xFF0D9488)], // Teal
                    timeEstimate: '10 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FillBlanksScreen()),
                    ),
                  ),
                  _PracticeCard(
                    title: 'Story\nReading',
                    subtitle: 'Interactive mysteries & adventure',
                    icon: Icons.auto_stories_rounded,
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)], // Green
                    timeEstimate: '15 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StoryPracticeScreen()),
                    ),
                  ),
                  _PracticeCard(
                    title: 'Article\nReading',
                    subtitle: 'Science, history & culture',
                    icon: Icons.article_rounded,
                    gradient: const [Color(0xFFF97316), Color(0xFFEA580C)], // Orange
                    timeEstimate: '15 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReadingPracticeScreen()),
                    ),
                  ),
                  _PracticeCard(
                    title: 'Writing\nLab',
                    subtitle: 'AI-guided writing practice',
                    icon: Icons.edit_note_rounded,
                    gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)], // Pink
                    timeEstimate: '20 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WritingPracticeScreen()),
                    ),
                  ),
                  _PracticeCard(
                    title: 'Pronunciation\nDrill',
                    subtitle: 'Intonation & tongue twisters',
                    icon: Icons.record_voice_over_rounded,
                    gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // Purple
                    timeEstimate: '10 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PronunciationScreen(
                            mode: PronunciationMode.sentences),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
                child: _buildAdaptiveDifficulty(isDark, progressProvider)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // Removed _startPractice as we route directly now

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
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
            child: const Icon(Icons.trending_up_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intermediate Level',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                Text('B1–B2 • Practice & Application',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySuggestion(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: GlassCard(
        borderColor: AppColors.xpColor.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.xpColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.xpColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Challenge",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.xpColor,
                      )),
                  Text(
                    'Complete a reading passage and answer 8 comprehension questions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildAdaptiveDifficulty(
      bool isDark, ProgressProvider provider) {
    final score = provider.overallProgress;
    final difficulty = score >= 0.8
        ? 'Advanced'
        : score >= 0.5
            ? 'Intermediate'
            : 'Building Foundation';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Adaptive Difficulty',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(difficulty,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI adjusts question difficulty based on your performance',
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
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String title, subtitle, timeEstimate;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.timeEstimate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⏱ $timeEstimate',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
