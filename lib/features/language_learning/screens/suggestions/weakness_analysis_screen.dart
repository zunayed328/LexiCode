import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/progress_provider.dart';
import '../../models/suggestion_model.dart';
import '../../models/exercise_model.dart';
import '../intermediate/practice_session_screen.dart';

/// Deep dive into specific learning weaknesses with evidence and quick actions.
class WeaknessAnalysisScreen extends StatelessWidget {
  const WeaknessAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressProvider = context.watch<ProgressProvider>();
    final analysis = progressProvider.weaknessAnalysis;

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weakness Analysis')),
        body: const Center(child: Text('No analysis available.')),
      );
    }

    final allWeaknesses = [
      ...analysis.criticalWeaknesses,
      ...analysis.moderateWeaknesses,
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            if (analysis.hiddenPatterns.isNotEmpty)
              SliverToBoxAdapter(child: _buildPatternsAlert(isDark, analysis)),
            SliverToBoxAdapter(child: _buildSectionTitle('Detailed Breakdown', isDark)),
            ...allWeaknesses.map(
              (w) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildDeepDiveCard(context, w, isDark),
                ),
              ),
            ),
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
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.troubleshoot_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deep Dive',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Detailed weakness breakdown',
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

  Widget _buildPatternsAlert(bool isDark, WeaknessAnalysis analysis) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Text('AI Identified Patterns',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            ...analysis.hiddenPatterns.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: AppColors.info.withOpacity(0.8))),
                      Expanded(
                        child: Text(p,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            )),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildDeepDiveCard(BuildContext context, Weakness w, bool isDark) {
    final color = w.urgencyColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderColor: color.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bug_report_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.area,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${w.skill} Issue',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    w.urgency.name.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(w.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                )),
            if (w.evidence.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EVIDENCE',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 6),
                    Text('"$w.evidence"',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: color.withOpacity(0.9))),
                  ],
                ),
              )
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _launchTargetedPractice(context, w.skill, w.area),
                icon: Icon(Icons.rocket_launch_rounded, color: color, size: 18),
                label: Text('Practice This Now',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchTargetedPractice(BuildContext context, String skill, String area) {
    SessionType targetType;
    switch (skill.toLowerCase()) {
      case 'grammar':
        targetType = SessionType.grammarPractice;
        break;
      case 'reading':
        targetType = SessionType.readingPractice;
        break;
      case 'listening':
        targetType = SessionType.listeningPractice;
        break;
      case 'spelling':
        targetType = SessionType.spellingPractice;
        break;
      default:
        targetType = SessionType.mixedSkills;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          sessionType: targetType,
          title: 'Target: $area',
        ),
      ),
    );
  }
}
